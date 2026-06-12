import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../services/habit_provider.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final groups = provider.localGroups;
    final profile = provider.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            tooltip: 'Create group',
            onPressed: () => _showCreateGroup(context),
            icon: const Icon(Icons.group_add_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      profile == null
                          ? 'Complete your profile to unlock local community matching by approximate area.'
                          : profile.shareApproxLocation
                              ? 'Visible in ${profile.areaName}. Nearby user search, pings, and invitations are ready for the secure backend phase.'
                              : 'Your area is saved, but local visibility is off. Turn it on from Profile when you want members nearby to discover you.',
                      style: const TextStyle(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (profile?.shareApproxLocation ?? false) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.radar_outlined),
                title: const Text('Nearby community'),
                subtitle: Text(
                  'Approximate area: ${profile!.areaName}. Live member counts and pings require the shared backend.',
                ),
                trailing: const Icon(Icons.lock_outline),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Suggested nearby groups',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...groups.map(
            (group) => Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          child: Icon(_iconFor(group.activityType)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${group.activityType} - ${group.area}',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(group.skillLevel),
                          avatar:
                              const Icon(Icons.signal_cellular_alt, size: 16),
                        ),
                        Chip(
                          label: Text(_privacyLabel(group.privacy)),
                          avatar: const Icon(Icons.lock_outline, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          context.read<HabitProvider>().toggleJoinGroup(group),
                      icon: Icon(
                        group.joined
                            ? Icons.check_circle
                            : Icons.add_circle_outline,
                      ),
                      label: Text(group.joined ? 'Joined' : 'Join group'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create group',
        onPressed: () => _showCreateGroup(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateGroup(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _CreateGroupDialog(),
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

  IconData _iconFor(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('gym')) return Icons.fitness_center;
    if (normalized.contains('badminton')) return Icons.sports_tennis;
    if (normalized.contains('run')) return Icons.directions_run;
    return Icons.directions_walk;
  }
}

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog();

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _nameController = TextEditingController();
  final _areaController = TextEditingController(text: 'Approx. local area');
  String _activityType = 'Walking';
  String _privacy = 'public';
  String _skillLevel = 'All';

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create group'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Group name'),
            ),
            TextField(
              controller: _areaController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Approximate area'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _activityType,
              decoration: const InputDecoration(labelText: 'Activity'),
              items: const [
                DropdownMenuItem(value: 'Walking', child: Text('Walking')),
                DropdownMenuItem(value: 'Running', child: Text('Running')),
                DropdownMenuItem(value: 'Gym', child: Text('Gym')),
                DropdownMenuItem(value: 'Badminton', child: Text('Badminton')),
                DropdownMenuItem(
                    value: 'Stretching', child: Text('Stretching')),
              ],
              onChanged: (value) => setState(() => _activityType = value!),
            ),
            DropdownButtonFormField<String>(
              initialValue: _skillLevel,
              decoration: const InputDecoration(labelText: 'Skill level'),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
                DropdownMenuItem(
                    value: 'Intermediate', child: Text('Intermediate')),
              ],
              onChanged: (value) => setState(() => _skillLevel = value!),
            ),
            DropdownButtonFormField<String>(
              initialValue: _privacy,
              decoration: const InputDecoration(labelText: 'Privacy'),
              items: const [
                DropdownMenuItem(value: 'public', child: Text('Public')),
                DropdownMenuItem(value: 'private', child: Text('Private')),
                DropdownMenuItem(
                    value: 'invite_only', child: Text('Invite only')),
              ],
              onChanged: (value) => setState(() => _privacy = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _save(context),
          child: const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final name = _nameController.text.trim();
    final area = _areaController.text.trim();
    if (name.isEmpty || area.isEmpty) return;

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
