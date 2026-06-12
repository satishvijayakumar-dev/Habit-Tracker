import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../services/habit_provider.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final _notesController = TextEditingController();
  final _customTypeController = TextEditingController();
  String _type = 'Walking';
  String _intensity = 'Moderate';
  double _minutes = 20;

  @override
  void dispose() {
    _notesController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final activities = provider.activities;

    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Log movement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final type in const [
                        'Walking',
                        'Running',
                        'Gym',
                        'Badminton',
                        'Stretching',
                        'Custom',
                      ])
                        ChoiceChip(
                          label: Text(type),
                          selected: _type == type,
                          onSelected: (_) => setState(() => _type = type),
                        ),
                    ],
                  ),
                  if (_type == 'Custom') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customTypeController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Activity name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    '${_minutes.round()} minutes',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Slider(
                    value: _minutes,
                    min: 5,
                    max: 120,
                    divisions: 23,
                    label: '${_minutes.round()} min',
                    onChanged: (value) => setState(() => _minutes = value),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'Easy',
                        label: Text('Easy'),
                        icon: Icon(Icons.spa_outlined),
                      ),
                      ButtonSegment(
                        value: 'Moderate',
                        label: Text('Moderate'),
                        icon: Icon(Icons.directions_walk),
                      ),
                      ButtonSegment(
                        value: 'Hard',
                        label: Text('Hard'),
                        icon: Icon(Icons.local_fire_department_outlined),
                      ),
                    ],
                    selected: {_intensity},
                    onSelectionChanged: (value) {
                      setState(() => _intensity = value.first);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Quick note',
                      hintText: 'Energy, mood, pain, or what made it easy',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => _save(context),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Save activity'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Recent activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (activities.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Log your first session to unlock weekly reports.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            )
          else
            ...activities.take(10).map((activity) {
              return Card(
                child: ListTile(
                  leading: Icon(_iconFor(activity.type)),
                  title: Text(
                      '${activity.type} - ${activity.durationMinutes} min'),
                  subtitle: Text(
                    '${activity.intensity} - ${DateFormat.MMMEd().format(activity.completedAt)}',
                  ),
                  trailing: activity.id == null
                      ? null
                      : IconButton(
                          tooltip: 'Delete activity',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => context
                              .read<HabitProvider>()
                              .deleteActivity(activity.id!),
                        ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final type = _type == 'Custom' ? _customTypeController.text.trim() : _type;
    if (type.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an activity name')),
      );
      return;
    }

    final provider = context.read<HabitProvider>();
    final messenger = ScaffoldMessenger.of(context);

    await provider.addActivity(
      ActivityLog(
        type: type,
        durationMinutes: _minutes.round(),
        intensity: _intensity,
        notes: _notesController.text.trim(),
        completedAt: DateTime.now(),
      ),
    );

    _notesController.clear();
    _customTypeController.clear();
    if (mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Activity saved')),
      );
    }
  }

  IconData _iconFor(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('run')) return Icons.directions_run;
    if (normalized.contains('gym')) return Icons.fitness_center;
    if (normalized.contains('badminton')) return Icons.sports_tennis;
    if (normalized.contains('stretch')) return Icons.self_improvement;
    return Icons.directions_walk;
  }
}
