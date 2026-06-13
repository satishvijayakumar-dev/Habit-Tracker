import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/community.dart';
import 'geo_service.dart';

/// Thin client over the ActivHealth Supabase community backend.
///
/// All reads/writes go through RLS-protected tables and the SECURITY INVOKER
/// RPCs (upsert_my_profile, create_group, join_group, groups_near). Location
/// is always coarsened on-device before it leaves the phone.
class CommunityService {
  SupabaseClient get _db => Supabase.instance.client;

  // -- Auth --
  String? get currentUserId => _db.auth.currentUser?.id;
  bool get isSignedIn => currentUserId != null;
  Stream<AuthState> get authChanges => _db.auth.onAuthStateChange;

  /// Email magic-link / OTP sign-in (no password). The deep-link or 6-digit
  /// code completes it via [verifyEmailOtp].
  Future<void> signInWithEmail(String email) =>
      _db.auth.signInWithOtp(email: email.trim());

  Future<void> verifyEmailOtp(String email, String token) async {
    await _db.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.email,
    );
  }

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
