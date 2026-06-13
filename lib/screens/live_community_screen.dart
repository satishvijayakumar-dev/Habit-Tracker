import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/community.dart';
import '../services/community_service.dart';
import '../services/geo_service.dart';
import '../theme/app_theme.dart';
import 'group_chat_screen.dart';

const kSports = [
  'Pickleball',
  'Badminton',
  'Tennis',
  'Padel',
  'Squash',
  'Football',
  'Walking',
  'Running',
  'Gym',
];

/// Live community: discover nearby public groups, see your groups, create
/// and join — all backed by Supabase. Rendered when the user is signed in
/// and opted in. Self-contained scrollable (host wraps it in Expanded).
class LiveCommunity extends StatefulWidget {
  final String displayName;
  final String? areaName;

  const LiveCommunity({super.key, required this.displayName, this.areaName});

  @override
  State<LiveCommunity> createState() => _LiveCommunityState();
}

class _LiveCommunityState extends State<LiveCommunity> {
  final _community = CommunityService();
  bool _loading = true;
  String? _error;
  CoarseLocation? _location;
  List<CommunityGroup> _mine = [];
  List<CommunityGroup> _nearby = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _location = await GeoService.currentCoarseLocation();
      // Make the user discoverable with a coarse point + display name.
      await _community.upsertProfile(
        displayName: widget.displayName.isEmpty ? 'Member' : widget.displayName,
        outwardPostcode: widget.areaName,
        location: _location,
        visibility: 'discoverable',
      );
      await _refresh();
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load community.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    final mine = await _community.myGroups();
    final nearby = _location == null
        ? <CommunityGroup>[]
        : await _community.groupsNear(_location!);
    if (!mounted) return;
    setState(() {
      _mine = mine;
      // Don't list groups the user already belongs to under "near you".
      final mineIds = mine.map((g) => g.id).toSet();
      _nearby = nearby.where((g) => !mineIds.contains(g.id)).toList();
    });
  }

  Future<void> _join(CommunityGroup g) async {
    HapticFeedback.selectionClick();
    try {
      final m = await _community.joinGroup(g.id);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              m.isActive ? 'Joined ${g.name}' : 'Request sent to ${g.name}'),
        ));
      }
    } catch (_) {
      _toast('Could not join — please try again.');
    }
  }

  void _toast(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  void _openChat(CommunityGroup g) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GroupChatScreen(groupId: g.id, groupName: g.name),
    ));
  }

  Future<void> _createGroup() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreateLiveGroupSheet(
        location: _location,
        areaName: widget.areaName,
        community: _community,
      ),
    );
    if (created == true) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _bootstrap);
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            Ah.gutter, Ah.s8, Ah.gutter, Ah.s48 + Ah.s32),
        children: [
          Row(
            children: [
              Expanded(child: Text('Your groups', style: textTheme.titleLarge)),
              TextButton.icon(
                onPressed: _createGroup,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New group'),
              ),
            ],
          ),
          const SizedBox(height: Ah.s8),
          if (_mine.isEmpty)
            _hint(
                context,
                'You haven\'t joined a group yet. Join one nearby '
                'or create your own.')
          else
            ..._mine.map((g) => _LiveGroupCard(
                  group: g,
                  trailingLabel: 'Open',
                  onTrailing: () => _openChat(g),
                )),
          const SizedBox(height: Ah.s24),
          Text('Near you', style: textTheme.titleLarge),
          const SizedBox(height: Ah.s8),
          if (_location == null)
            _hint(context, 'Turn on location to discover groups near you.')
          else if (_nearby.isEmpty)
            _hint(context, 'No public groups nearby yet. Create the first one!')
          else
            ..._nearby.map((g) => _LiveGroupCard(
                  group: g,
                  trailingLabel: 'Join',
                  onTrailing: () => _join(g),
                )),
        ],
      ),
    );
  }

  Widget _hint(BuildContext context, String text) => Card(
        child: Padding(
          padding: const EdgeInsets.all(Ah.s16),
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Ah.textSecondary, height: 1.4)),
        ),
      );
}

class _LiveGroupCard extends StatelessWidget {
  final CommunityGroup group;
  final String trailingLabel;
  final VoidCallback onTrailing;

  const _LiveGroupCard({
    required this.group,
    required this.trailingLabel,
    required this.onTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Ah.s8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Ah.s12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Ah.tint(Ah.accent),
                  borderRadius: BorderRadius.circular(Ah.rMd),
                ),
                child:
                    const Icon(Icons.sports_tennis, color: Ah.accent, size: 22),
              ),
              const SizedBox(width: Ah.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium),
                    Text('${group.sport} · ${group.skillBand}',
                        style: textTheme.labelMedium),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onTrailing,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: Ah.s16),
                ),
                child: Text(trailingLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Ah.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Ah.textSecondary, size: 40),
            const SizedBox(height: Ah.s12),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: Ah.s16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _CreateLiveGroupSheet extends StatefulWidget {
  final CoarseLocation? location;
  final String? areaName;
  final CommunityService community;

  const _CreateLiveGroupSheet({
    required this.location,
    required this.areaName,
    required this.community,
  });

  @override
  State<_CreateLiveGroupSheet> createState() => _CreateLiveGroupSheetState();
}

class _CreateLiveGroupSheetState extends State<_CreateLiveGroupSheet> {
  final _name = TextEditingController();
  String _sport = 'Pickleball';
  String _privacy = 'public';
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.community.createGroup(
        name: _name.text.trim(),
        sport: _sport,
        outwardPostcode: widget.areaName,
        location: widget.location,
        privacy: _privacy,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create group.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(Ah.gutter, Ah.s8, Ah.gutter,
          MediaQuery.of(context).viewInsets.bottom + Ah.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create a group', style: textTheme.headlineSmall),
          const SizedBox(height: Ah.s16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Group name'),
          ),
          const SizedBox(height: Ah.s16),
          Text('Sport', style: textTheme.labelMedium),
          const SizedBox(height: Ah.s8),
          Wrap(
            spacing: Ah.s8,
            runSpacing: Ah.s8,
            children: kSports
                .map((s) => ChoiceChip(
                      label: Text(s),
                      selected: _sport == s,
                      onSelected: (_) => setState(() => _sport = s),
                    ))
                .toList(),
          ),
          const SizedBox(height: Ah.s16),
          Text('Privacy', style: textTheme.labelMedium),
          const SizedBox(height: Ah.s8),
          Wrap(
            spacing: Ah.s8,
            children: const [
              ('public', 'Public'),
              ('invite_only', 'Invite only'),
            ]
                .map((o) => ChoiceChip(
                      label: Text(o.$2),
                      selected: _privacy == o.$1,
                      onSelected: (_) => setState(() => _privacy = o.$1),
                    ))
                .toList(),
          ),
          const SizedBox(height: Ah.s24),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Creating…' : 'Create group'),
          ),
        ],
      ),
    );
  }
}
