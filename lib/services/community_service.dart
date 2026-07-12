import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/community.dart';
import 'geo_service.dart';
import 'supabase_config.dart';

/// Thin client over the ActivHealth Supabase community backend.
///
/// All reads/writes go through RLS-protected tables and the SECURITY INVOKER
/// RPCs (upsert_my_profile, create_group, join_group, groups_near). Location
/// is always coarsened on-device before it leaves the phone.
class CommunityService {
  SupabaseClient get _db => Supabase.instance.client;

  // -- Auth --
  /// Safe even when Supabase isn't initialised (e.g. offline build or tests):
  /// returns null rather than throwing, so UI that checks sign-in state in
  /// build() never crashes.
  String? get currentUserId {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  bool get isSignedIn => currentUserId != null;
  Stream<AuthState> get authChanges => _db.auth.onAuthStateChange;

  /// Email of the signed-in user (null when signed out / unavailable).
  String? get currentUserEmail {
    try {
      return Supabase.instance.client.auth.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  /// Display name from the OAuth provider (Google/Apple), if any.
  String? get currentUserName {
    try {
      final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
      final name = meta?['full_name'] ?? meta?['name'];
      return name is String && name.trim().isNotEmpty ? name : null;
    } catch (_) {
      return null;
    }
  }

  /// How the user signed in — 'google', 'apple', 'email', … (null if unknown).
  String? get currentUserProvider {
    try {
      final meta = Supabase.instance.client.auth.currentUser?.appMetadata;
      final p = meta?['provider'];
      return p is String ? p : null;
    } catch (_) {
      return null;
    }
  }

  /// Email OTP sign-in (no password). A 6-digit code is emailed; complete it
  /// via [verifyEmailOtp]. Works with no third-party provider config.
  Future<void> signInWithEmail(String email) => _db.auth.signInWithOtp(
        email: email.trim(),
        emailRedirectTo: SupabaseConfig.authRedirect,
      );

  Future<void> verifyEmailOtp(String email, String token) async {
    await _db.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.email,
    );
  }

  /// Google OAuth via the Supabase hosted flow, returning through the
  /// app's deep link. Requires the Google provider configured in Supabase.
  Future<bool> signInWithGoogle() => _db.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: SupabaseConfig.authRedirect,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

  /// Sign in with Apple (required on iOS when other providers are offered).
  Future<bool> signInWithApple() => _db.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: SupabaseConfig.authRedirect,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

  Future<void> signOut() => _db.auth.signOut();

  /// Permanently delete the signed-in user's cloud account and ALL their
  /// community data (profile, groups, messages — cascaded from auth.users via
  /// the `delete-account` edge function, which runs with the service role).
  /// Signs out afterwards. Returns true on success.
  ///
  /// Throws if not signed in or the server call fails, so the UI can keep the
  /// user informed rather than silently leaving a live cloud account behind.
  Future<bool> deleteAccount() async {
    if (!isSignedIn) return false;
    final res = await _db.functions.invoke('delete-account');
    final data = res.data;
    final ok = data is Map && data['deleted'] == true;
    if (!ok) {
      throw Exception('Account deletion did not complete on the server.');
    }
    try {
      await _db.auth.signOut();
    } catch (_) {
      // Already deleted server-side; a failed local sign-out is harmless.
    }
    return true;
  }

  // -- AI coach (server-side Claude Haiku proxy) --
  /// Returns a clever, adaptive coach reply, or null to fall back to the
  /// on-device rule-based coach. Requires sign-in (the function is JWT-gated)
  /// and Supabase to be initialised; any failure degrades to null.
  Future<String?> coachReply(
    String message,
    Map<String, dynamic> context,
  ) async {
    try {
      if (!isSignedIn) return null;
      final res = await _db.functions.invoke(
        'coach-chat',
        body: {'message': message, 'context': context},
      );
      final data = res.data;
      if (data is Map && data['reply'] is String) {
        final reply = (data['reply'] as String).trim();
        return reply.isEmpty ? null : reply;
      }
      return null; // {fallback: true} or unexpected shape
    } catch (_) {
      return null;
    }
  }

  // -- Profile --
  Future<void> upsertProfile({
    required String displayName,
    String? outwardPostcode,
    CoarseLocation? location,
    String visibility = 'hidden',
  }) async {
    await _db.rpc('upsert_my_profile', params: {
      'in_display_name': displayName,
      'in_outward_postcode': outwardPostcode,
      'in_lat': location?.lat,
      'in_lng': location?.lng,
      'in_visibility': visibility,
    });
  }

  // -- Discovery --
  /// Public groups near a coarse point, nearest first, optionally by sport.
  Future<List<CommunityGroup>> groupsNear(
    CoarseLocation at, {
    double radiusMetres = 16000,
    String? sport,
  }) async {
    final rows = await _db.rpc('groups_near', params: {
      'in_lat': at.lat,
      'in_lng': at.lng,
      'in_radius_m': radiusMetres,
      'in_sport': sport,
    }) as List<dynamic>;
    return rows
        .map((r) => CommunityGroup.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Groups the signed-in user belongs to (any membership status).
  Future<List<CommunityGroup>> myGroups() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final rows = await _db
        .from('groups')
        .select('*, group_members!inner(profile_id, status)')
        .eq('group_members.profile_id', uid) as List<dynamic>;
    return rows
        .map((r) => CommunityGroup.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  // -- Mutations --
  Future<CommunityGroup> createGroup({
    required String name,
    required String sport,
    String description = '',
    String? outwardPostcode,
    CoarseLocation? location,
    String privacy = 'invite_only',
    String skillBand = 'all',
    bool womenOnly = false,
  }) async {
    final row = await _db.rpc('create_group', params: {
      'in_name': name,
      'in_sport': sport,
      'in_description': description,
      'in_outward_postcode': outwardPostcode,
      'in_lat': location?.lat,
      'in_lng': location?.lng,
      'in_privacy': privacy,
      'in_skill_band': skillBand,
      'in_women_only': womenOnly,
    });
    return CommunityGroup.fromMap(row as Map<String, dynamic>);
  }

  Future<GroupMembership> joinGroup(String groupId) async {
    final row = await _db.rpc('join_group', params: {'in_group_id': groupId});
    return GroupMembership.fromMap(row as Map<String, dynamic>);
  }

  // -- Group chat --
  /// Recent messages for a group, oldest first.
  Future<List<Map<String, dynamic>>> messageHistory(String groupId) async {
    final rows = await _db
        .from('messages')
        .select()
        .eq('group_id', groupId)
        .order('created_at', ascending: true)
        .limit(100) as List<dynamic>;
    return rows.cast<Map<String, dynamic>>();
  }

  // -- Realtime group chat (subscribe to a group's messages) --
  RealtimeChannel groupMessages(
    String groupId,
    void Function(Map<String, dynamic> message) onInsert,
  ) {
    return _db
        .channel('messages:$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
  }

  Future<void> sendMessage(String groupId, String body) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _db.from('messages').insert({
      'group_id': groupId,
      'sender_id': uid,
      'body': body,
    });
  }
}
