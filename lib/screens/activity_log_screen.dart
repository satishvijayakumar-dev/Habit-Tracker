import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../services/habit_provider.dart';
import '../theme/app_theme.dart';

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
  double _minutes = 30;
  bool _overrodeMinutes = false;
  bool _initialised = false;

  static const _types = [
    (name: 'Walking', icon: Icons.directions_walk),
    (name: 'Running', icon: Icons.directions_run),
    (name: 'Gym', icon: Icons.fitness_center),
    (name: 'Pickleball', icon: Icons.sports_tennis),
    (name: 'Badminton', icon: Icons.sports_tennis),
    (name: 'Tennis', icon: Icons.sports_tennis),
    (name: 'Padel', icon: Icons.sports_tennis),
    (name: 'Football', icon: Icons.sports_soccer),
    (name: 'Cycling', icon: Icons.directions_bike),
    (name: 'Stretching', icon: Icons.self_improvement),
    (name: 'Custom', icon: Icons.add),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _minutes =
          context.read<HabitProvider>().recommendedMinutesFor(_type).toDouble();
      _initialised = true;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  void _selectType(String type) {
    HapticFeedback.selectionClick();
    setState(() {
      _type = type;
      if (!_overrodeMinutes && type != 'Custom') {
        _minutes = context
            .read<HabitProvider>()
            .recommendedMinutesFor(type)
            .toDouble();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final activities = provider.activities;
    final textTheme = Theme.of(context).textTheme;
    final recommended = provider.recommendedMinutesFor(_type);

    return Scaffold(
      appBar: AppBar(title: const Text('Log activity')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Ah.gutter, Ah.s8, Ah.gutter, Ah.s32),
        children: [
          Text('What did you do?', style: textTheme.titleLarge),
          const SizedBox(height: Ah.s12),
          // Colourful activity chips
          Wrap(
            spacing: Ah.s8,
            runSpacing: Ah.s8,
            children: _types.map((t) {
              final selected = _type == t.name;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(Ah.rMd),
                  onTap: () => _selectType(t.name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: Ah.s12, vertical: Ah.s8),
                    decoration: BoxDecoration(
                      color: selected
                          ? Color.alphaBlend(Ah.tint(Ah.accent), Ah.surface1)
                          : Ah.surface2,
                      borderRadius: BorderRadius.circular(Ah.rMd),
                      border: Border.all(
                        color: selected ? Ah.accent : Ah.hairline,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.icon,
                            size: 16,
                            color: selected ? Ah.accent : Ah.textSecondary),
                        const SizedBox(width: 6),
                        Text(t.name,
                            style: textTheme.labelLarge?.copyWith(
                                color: selected ? Ah.accent : Ah.textPrimary)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_type == 'Custom') ...[
            const SizedBox(height: Ah.s12),
            TextField(
              controller: _customTypeController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Activity name'),
            ),
          ],
          const SizedBox(height: Ah.s24),

          // Duration + AI coach recommendation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Ah.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${_minutes.round()} minutes',
                          style: textTheme.titleMedium),
                      const Spacer(),
                      if (_type != 'Custom')
                        _CoachChip(
                          recommended: recommended,
                          isDefault: !_overrodeMinutes,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _minutes = recommended.toDouble();
                              _overrodeMinutes = false;
                            });
                          },
                        ),
                    ],
                  ),
                  Slider(
                    value: _minutes.clamp(5, 120),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    label: '${_minutes.round()} min',
                    onChanged: (v) => setState(() {
                      _minutes = v;
                      _overrodeMinutes = true;
                    }),
                  ),
                  const SizedBox(height: Ah.s8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'Easy',
                          label: Text('Easy'),
                          icon: Icon(Icons.spa_outlined)),
                      ButtonSegment(
                          value: 'Moderate',
                          label: Text('Moderate'),
                          icon: Icon(Icons.directions_walk)),
                      ButtonSegment(
                          value: 'Hard',
                          label: Text('Hard'),
                          icon: Icon(Icons.local_fire_department_outlined)),
                    ],
                    selected: {_intensity},
                    onSelectionChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _intensity = v.first);
                    },
                  ),
                  const SizedBox(height: Ah.s12),
                  TextField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Quick note',
                      hintText: 'Energy, mood, pain, or what made it easy',
                    ),
                  ),
                  const SizedBox(height: Ah.s16),
                  FilledButton.icon(
                    onPressed: () => _save(context),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Save activity'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Ah.s24),
          Text('Recent activity', style: textTheme.titleLarge),
          const SizedBox(height: Ah.s8),
          if (activities.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Ah.s16),
                child: Text('Log your first session to unlock weekly insights.',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: Ah.textSecondary)),
              ),
            )
          else
            ...activities.take(10).map((activity) => Padding(
                  padding: const EdgeInsets.only(bottom: Ah.s8),
                  child: Card(
                    child: ListTile(
                      leading: Icon(_iconFor(activity.type)),
                      title: Text(
                          '${activity.type} · ${activity.durationMinutes} min'),
                      subtitle: Text(
                        '${activity.intensity} · ${DateFormat.MMMEd().format(activity.completedAt)}',
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
                  ),
                )),
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
    HapticFeedback.mediumImpact();
    if (mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Ah.mint, size: 20),
              SizedBox(width: Ah.s8),
              Expanded(child: Text('Activity saved — ring updated')),
            ],
          ),
        ),
      );
    }
  }

  IconData _iconFor(String type) {
    final n = type.toLowerCase();
    if (n.contains('run')) return Icons.directions_run;
    if (n.contains('gym')) return Icons.fitness_center;
    if (n.contains('cycl')) return Icons.directions_bike;
    if (n.contains('football')) return Icons.sports_soccer;
    if (n.contains('pickle') ||
        n.contains('badmin') ||
        n.contains('tennis') ||
        n.contains('padel') ||
        n.contains('squash')) {
      return Icons.sports_tennis;
    }
    if (n.contains('stretch')) return Icons.self_improvement;
    return Icons.directions_walk;
  }
}

/// Shows the coach's recommended minutes; tap to snap back to it.
class _CoachChip extends StatelessWidget {
  final int recommended;
  final bool isDefault;
  final VoidCallback onTap;

  const _CoachChip({
    required this.recommended,
    required this.isDefault,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Ah.rSm),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: Ah.s8, vertical: Ah.s4),
          decoration: BoxDecoration(
            color: isDefault ? Ah.tint(Ah.accent) : Ah.surface2,
            borderRadius: BorderRadius.circular(Ah.rSm),
            border: Border.all(color: isDefault ? Ah.accent : Ah.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.psychology_alt, size: 13, color: Ah.accent),
              const SizedBox(width: 4),
              Text(
                isDefault ? 'Coach: $recommended min' : 'Reset to $recommended',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Ah.accent, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
