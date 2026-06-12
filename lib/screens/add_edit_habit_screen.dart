import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/habit_style.dart';

class AddEditHabitScreen extends StatefulWidget {
  final Habit? habit;
  const AddEditHabitScreen({super.key, this.habit});

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _targetController = TextEditingController(text: '1');
  final _unitController = TextEditingController();
  final _anchorController = TextEditingController();
  final _fallbackController = TextEditingController();
  final _celebrationController = TextEditingController();

  String _color = 'blue';
  String _icon = 'check_circle';
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  String _habitType = 'build';
  String _trackingType = 'checkoff';
  String _difficulty = 'tiny';

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    if (h != null) {
      _nameController.text = h.name;
      _descController.text = h.description;
      _color = h.colorName;
      _icon = h.iconName;
      _reminderEnabled = h.hasReminder;
      _habitType = h.habitType;
      _trackingType = h.trackingType;
      _targetController.text = '${h.targetAmount}';
      _unitController.text = h.unit;
      _anchorController.text = h.anchor;
      _fallbackController.text = h.fallbackBehavior;
      _celebrationController.text = h.celebration;
      _difficulty = h.difficulty;
      if (h.hasReminder) {
        _reminderTime =
            TimeOfDay(hour: h.reminderHour!, minute: h.reminderMinute!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    _anchorController.dispose();
    _fallbackController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<HabitProvider>();
    var saveWithReminder = _reminderEnabled;
    if (_reminderEnabled) {
      final granted = await NotificationService.instance.requestPermissions();
      if (!granted) {
        saveWithReminder = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Notification permission denied — habit saved without reminder.'),
            ),
          );
        }
      }
    }

    final target = int.tryParse(_targetController.text) ?? 1;

    if (_isEditing) {
      final updated = widget.habit!.copyWith(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        colorName: _color,
        iconName: _icon,
        clearReminder: !saveWithReminder,
        reminderHour: saveWithReminder ? _reminderTime.hour : null,
        reminderMinute: saveWithReminder ? _reminderTime.minute : null,
        habitType: _habitType,
        trackingType: _trackingType,
        targetAmount: target,
        unit: _unitController.text.trim(),
        anchor: _anchorController.text.trim(),
        fallbackBehavior: _fallbackController.text.trim(),
        celebration: _celebrationController.text.trim(),
        pathName: provider.selectedPath ?? widget.habit!.pathName,
        difficulty: _difficulty,
      );
      await provider.updateHabit(updated);
    } else {
      final newHabit = Habit(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        colorName: _color,
        iconName: _icon,
        createdAt: DateTime.now(),
        reminderHour: saveWithReminder ? _reminderTime.hour : null,
        reminderMinute: saveWithReminder ? _reminderTime.minute : null,
        habitType: _habitType,
        trackingType: _trackingType,
        targetAmount: target,
        unit: _unitController.text.trim(),
        anchor: _anchorController.text.trim(),
        fallbackBehavior: _fallbackController.text.trim(),
        celebration: _celebrationController.text.trim(),
        pathName: provider.selectedPath ?? '',
        difficulty: _difficulty,
      );
      await provider.addHabit(newHabit);
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked != null) setState(() => _reminderTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit loop' : 'New ActivHealth loop'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_isEditing &&
                context.watch<HabitProvider>().hasSelectedPath) ...[
              _PathBanner(
                  pathName: context.watch<HabitProvider>().selectedPath!),
              const SizedBox(height: 20),
            ],

            // Habit Type: Build or Quit
            const _SectionLabel('Type'),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'build',
                    label: Text('Build'),
                    icon: Icon(Icons.trending_up)),
                ButtonSegment(
                    value: 'quit',
                    label: Text('Quit'),
                    icon: Icon(Icons.block)),
              ],
              selected: {_habitType},
              onSelectionChanged: (val) =>
                  setState(() => _habitType = val.first),
            ),
            const SizedBox(height: 4),
            Text(
              _habitType == 'build'
                  ? 'Build a positive loop'
                  : 'Break a pattern - track days free',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 20),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: _habitType == 'build'
                    ? 'e.g. Exercise, Read, Meditate'
                    : 'e.g. Smoking, Junk Food, Social Media',
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter a name';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            const _SectionLabel('Behavior loop'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _anchorController,
              decoration: const InputDecoration(
                labelText: 'Anchor',
                hintText: 'After I brush my teeth...',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fallbackController,
              decoration: const InputDecoration(
                labelText: 'Smallest fallback',
                hintText: 'If I am busy, I will do the 30-second version',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _celebrationController,
              decoration: const InputDecoration(
                labelText: 'Celebration',
                hintText: 'I will say: that counts',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'tiny', label: Text('Tiny')),
                ButtonSegment(value: 'manageable', label: Text('Manageable')),
                ButtonSegment(value: 'challenging', label: Text('Stretch')),
              ],
              selected: {_difficulty},
              onSelectionChanged: (val) =>
                  setState(() => _difficulty = val.first),
            ),
            const SizedBox(height: 24),

            // Tracking Type (only for Build habits)
            if (_habitType == 'build') ...[
              const _SectionLabel('Tracking'),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'checkoff', label: Text('Check off')),
                  ButtonSegment(value: 'amount', label: Text('Track amount')),
                ],
                selected: {_trackingType},
                onSelectionChanged: (val) =>
                    setState(() => _trackingType = val.first),
              ),
              const SizedBox(height: 4),
              Text(
                _trackingType == 'checkoff'
                    ? 'Simple done / not done each day'
                    : 'Track a quantity (glasses, minutes, pages...)',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 12),

              // Amount fields
              if (_trackingType == 'amount') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _targetController,
                        decoration: const InputDecoration(
                          labelText: 'Daily target',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (_trackingType == 'amount') {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 1) return 'Enter a number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          hintText: 'e.g. glasses, minutes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
            ],

            // Colour
            const _SectionLabel('Colour'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: kHabitColors.entries.map((e) {
                final selected = _color == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _color = e.key),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: e.value,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            selected ? Ah.textPrimary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Icon
            const _SectionLabel('Icon'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kHabitIcons.entries.map((e) {
                final selected = _icon == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _icon = e.key),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected
                          ? colorFor(_color).withValues(alpha: 0.15)
                          : Ah.surface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? colorFor(_color) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(e.value, color: colorFor(_color)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Reminder
            const _SectionLabel('Reminder'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Daily reminder'),
                    value: _reminderEnabled,
                    onChanged: (v) => setState(() => _reminderEnabled = v),
                  ),
                  if (_reminderEnabled)
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Time'),
                      trailing: Text(
                        _reminderTime.format(context),
                        style: const TextStyle(fontSize: 16),
                      ),
                      onTap: _pickTime,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Ah.textSecondary,
          ),
    );
  }
}

class _PathBanner extends StatelessWidget {
  final String pathName;

  const _PathBanner({required this.pathName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Ah.tint(Ah.accent),
        borderRadius: BorderRadius.circular(Ah.rMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_outlined, color: Ah.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$pathName path: design the smallest loop that still counts.',
              style: const TextStyle(
                color: Ah.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
