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
