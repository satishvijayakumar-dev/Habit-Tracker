import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../services/habit_provider.dart';
import '../theme/app_theme.dart';
import 'share_screen.dart';

/// Community: social sport groups — pickleball, badminton, tennis, padel
/// and more. Local-first today (groups live on this device); the shared
/// backend turns these into real clubs with sessions, RSVP, and chat.
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  static const kSports = [
    'Pickleball',
    'Badminton',
    'Tennis',
    'Padel',
    'Squash',
    '5-a-side Football',
    'Walking',
    'Running',
    'Gym',
    'Stretching',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final groups = provider.localGroups;
    final profile = provider.profile;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            tooltip: 'Invite friends',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ShareScreen()),
            ),
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            Ah.gutter, Ah.s8, Ah.gutter, Ah.s48 + Ah.s32),
        children: [
          // -- Opt-in: one simple switch --
          _OptInCard(
            optedIn: provider.communityOptIn,
            area: profile?.areaName,
            onChanged: (v) {
              provider.setCommunityOptIn(v);
              if (v) _showOptInDialog(context);
            },
          ),
          const SizedBox(height: Ah.s24),

          if (provider.communityOptIn) ...[
            Text('Your groups', style: textTheme.titleLarge),
            const SizedBox(height: Ah.s8),
            ...groups.map((group) => _GroupCard(group: group)),
          ] else
            _OptedOutHint(textTheme: textTheme),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'community_fab',
        onPressed: () => _showCreateGroup(context),
        backgroundColor: Ah.accent,
        foregroundColor: Ah.onAccent,
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('New group'),
      ),
    );
  }

  void _showCreateGroup(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateGroupSheet(),
    );
  }

  void _showOptInDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("You're in the community"),
        content: const Text(
          'People nearby with similar interests can now find your group and ask to join or chat. '
          'Only your approximate area is shared — never your exact location. '
          'You can opt out or silence notifications any time from Settings.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _OptInCard extends StatelessWidget {
  final bool optedIn;
  final String? area;
  final ValueChanged<bool> onChanged;

  const _OptInCard({
    required this.optedIn,
    required this.area,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Ah.s16),
      decoration: BoxDecoration(
        gradient: optedIn ? Ah.brandGradient : null,
        color: optedIn ? null : Ah.surface2,
        borderRadius: BorderRadius.circular(Ah.rLg),
        border: optedIn ? null : Border.all(color: Ah.hairline),
      ),
      child: Row(
        children: [
          Icon(optedIn ? Icons.groups : Icons.groups_outlined,
              color: optedIn ? Ah.onAccent : Ah.textSecondary, size: 28),
          const SizedBox(width: Ah.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  optedIn ? 'Community is on' : 'Join the community',
                  style: textTheme.titleMedium?.copyWith(
                    color: optedIn ? Ah.onAccent : Ah.textPrimary,
                  ),
                ),
                Text(
                  optedIn
                      ? 'Visible in ${area ?? "your area"} · approximate only'
                      : 'Find like-minded people nearby to train with',
                  style: textTheme.labelMedium?.copyWith(
                    color: optedIn
                        ? Ah.onAccent.withValues(alpha: 0.8)
                        : Ah.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: optedIn,
            onChanged: onChanged,
            activeTrackColor: Ah.onAccent.withValues(alpha: 0.5),
            thumbColor: WidgetStatePropertyAll(
                optedIn ? Ah.onAccent : Ah.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _OptedOutHint extends StatelessWidget {
  final TextTheme textTheme;
  const _OptedOutHint({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Ah.s24),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Ah.tint(Ah.info),
                borderRadius: BorderRadius.circular(Ah.rLg),
              ),
              child:
                  const Icon(Icons.groups_outlined, color: Ah.info, size: 28),
            ),
            const SizedBox(height: Ah.s12),
            Text('Community is off', style: textTheme.titleMedium),
            const SizedBox(height: Ah.s4),
            Text(
              'Turn it on to discover local groups for your sports and connect with people nearby. You stay in control — opt out any time.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final LocalGroup group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Ah.s8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Ah.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Ah.tint(_sportColor(group.activityType)),
                      borderRadius: BorderRadius.circular(Ah.rMd),
                    ),
                    child: Icon(
                      _iconFor(group.activityType),
                      color: _sportColor(group.activityType),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: Ah.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name, style: textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          '${group.activityType} · ${group.area}',
                          style: textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Ah.s12),
              Row(
                children: [
                  _Tag(
                      icon: Icons.signal_cellular_alt, label: group.skillLevel),
                  const SizedBox(width: Ah.s8),
                  _Tag(
                      icon: Icons.lock_outline,
                      label: _privacyLabel(group.privacy)),
                  const Spacer(),
                  _JoinButton(group: group),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _privacyLabel(String value) {
    switch (value) {
      case 'private':
        return 'Private';
      case 'invite_only':
        return 'Invite only';
      default:
        return 'Public';
    }
  }

  Color _sportColor(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('pickle')) return Ah.accent;
    if (normalized.contains('badminton')) return Ah.info;
    if (normalized.contains('tennis')) return Ah.mint;
    if (normalized.contains('padel')) return Ah.warning;
    if (normalized.contains('football')) return Ah.mint;
    if (normalized.contains('gym')) return Ah.accent;
    if (normalized.contains('run')) return Ah.info;
    return Ah.textSecondary;
  }

  IconData _iconFor(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('pickle') ||
        normalized.contains('badminton') ||
        normalized.contains('tennis') ||
        normalized.contains('padel') ||
        normalized.contains('squash')) {
      return Icons.sports_tennis;
    }
    if (normalized.contains('football')) return Icons.sports_soccer;
    if (normalized.contains('gym')) return Icons.fitness_center;
    if (normalized.contains('run')) return Icons.directions_run;
    if (normalized.contains('stretch')) return Icons.self_improvement;
    return Icons.directions_walk;
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Tag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Ah.s8, vertical: Ah.s4),
      decoration: BoxDecoration(
        color: Ah.surface2,
        borderRadius: BorderRadius.circular(Ah.rSm),
        border: Border.all(color: Ah.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Ah.textSecondary),
          const SizedBox(width: Ah.s4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  final LocalGroup group;

  const _JoinButton({required this.group});

  @override
  Widget build(BuildContext context) {
    final joined = group.joined;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: joined ? Ah.tint(Ah.mint) : Ah.accent,
        borderRadius: BorderRadius.circular(Ah.rXl),
        border:
            joined ? Border.all(color: Ah.mint.withValues(alpha: 0.5)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Ah.rXl),
          onTap: () {
            HapticFeedback.selectionClick();
            context.read<HabitProvider>().toggleJoinGroup(group);
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: Ah.s16, vertical: Ah.s8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  joined ? Icons.check : Icons.add,
                  size: 16,
                  color: joined ? Ah.mint : Ah.onAccent,
                ),
                const SizedBox(width: Ah.s4),
                Text(
                  joined ? 'Joined' : 'Join',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: joined ? Ah.mint : Ah.onAccent,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateGroupSheet extends StatefulWidget {
  const _CreateGroupSheet();

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  String _activityType = 'Pickleball';
  String _privacy = 'invite_only';
  String _skillLevel = 'All';

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Ah.gutter,
        Ah.s8,
        Ah.gutter,
        MediaQuery.of(context).viewInsets.bottom + Ah.s24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create group', style: textTheme.headlineSmall),
            const SizedBox(height: Ah.s16),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Group name'),
            ),
            const SizedBox(height: Ah.s12),
            TextField(
              controller: _areaController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Area',
                hintText: 'e.g. WD17 or Watford',
              ),
            ),
            const SizedBox(height: Ah.s16),
            Text('Sport', style: textTheme.labelMedium),
            const SizedBox(height: Ah.s8),
            Wrap(
              spacing: Ah.s8,
              runSpacing: Ah.s8,
              children: GroupsScreen.kSports
                  .map(
                    (sport) => ChoiceChip(
                      label: Text(sport),
                      selected: _activityType == sport,
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _activityType = sport);
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: Ah.s16),
            Text('Skill level', style: textTheme.labelMedium),
            const SizedBox(height: Ah.s8),
            Wrap(
              spacing: Ah.s8,
              children: const ['All', 'Beginner', 'Intermediate', 'Advanced']
                  .map(
                    (level) => ChoiceChip(
                      label: Text(level),
                      selected: _skillLevel == level,
                      onSelected: (_) => setState(() => _skillLevel = level),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: Ah.s16),
            Text('Privacy', style: textTheme.labelMedium),
            const SizedBox(height: Ah.s8),
            Wrap(
              spacing: Ah.s8,
              children: const [
                ('invite_only', 'Invite only'),
                ('private', 'Private'),
                ('public', 'Public'),
              ]
                  .map(
                    (option) => ChoiceChip(
                      label: Text(option.$2),
                      selected: _privacy == option.$1,
                      onSelected: (_) => setState(() => _privacy = option.$1),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: Ah.s24),
            FilledButton(
              onPressed: () => _save(context),
              child: const Text('Create group'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final name = _nameController.text.trim();
    final area = _areaController.text.trim();
    if (name.isEmpty || area.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a group name and area')),
      );
      return;
    }

    await context.read<HabitProvider>().addLocalGroup(
          LocalGroup(
            name: name,
            activityType: _activityType,
            area: area,
            privacy: _privacy,
            skillLevel: _skillLevel,
            joined: true,
            createdAt: DateTime.now(),
          ),
        );

    if (context.mounted) Navigator.of(context).pop();
  }
}
