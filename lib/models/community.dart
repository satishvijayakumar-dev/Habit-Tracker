// Cloud community models (ActivHealth Supabase backend).
//
// Distinct from the local-only LocalGroup in activity.dart: these map to the
// networked `groups` / `group_members` / `sessions` tables and carry server
// ids (uuid strings).

class CommunityGroup {
  final String id;
  final String name;
  final String sport;
  final String description;
  final String? outwardPostcode;
  final String privacy; // public | invite_only | private
  final String skillBand;
  final bool womenOnly;
  final String ownerId;
  final String? inviteCode;

  const CommunityGroup({
    required this.id,
    required this.name,
    required this.sport,
    this.description = '',
    this.outwardPostcode,
    this.privacy = 'invite_only',
    this.skillBand = 'all',
    this.womenOnly = false,
    required this.ownerId,
    this.inviteCode,
  });

  factory CommunityGroup.fromMap(Map<String, dynamic> m) => CommunityGroup(
        id: m['id'] as String,
        name: m['name'] as String,
        sport: m['sport'] as String,
        description: (m['description'] as String?) ?? '',
        outwardPostcode: m['outward_postcode'] as String?,
        privacy: (m['privacy'] as String?) ?? 'invite_only',
        skillBand: (m['skill_band'] as String?) ?? 'all',
        womenOnly: (m['women_only'] as bool?) ?? false,
        ownerId: m['owner_id'] as String,
        inviteCode: m['invite_code'] as String?,
      );
}

class GroupMembership {
  final String groupId;
  final String profileId;
  final String role; // owner | organiser | member
  final String status; // pending | active | removed | banned

  const GroupMembership({
    required this.groupId,
    required this.profileId,
    required this.role,
    required this.status,
  });

  bool get isActive => status == 'active';

  factory GroupMembership.fromMap(Map<String, dynamic> m) => GroupMembership(
        groupId: m['group_id'] as String,
        profileId: m['profile_id'] as String,
        role: (m['role'] as String?) ?? 'member',
        status: (m['status'] as String?) ?? 'pending',
      );
}
