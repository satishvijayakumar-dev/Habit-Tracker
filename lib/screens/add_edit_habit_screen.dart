import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_provider.dart';
import '../services/notification_service.dart';
import '../widgets/habit_style.dart';

class AddEditHabitScreen extends StatefulWidget {
  /// Pass an existing habit to edit; omit for a new habit.
  final Habit? habit;

  const AddEditHabitScreen({super.key, this.habit});

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  String _color = 'blue';
  String _icon = 'check_circle';
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

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
      if (h.hasReminder) {
        _reminderTime = TimeOfDay(
          hour: h.reminderHour!,
          minute: h.reminderMinute!,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // If turning on a reminder, request permission first. If it's denied,
    // save the habit anyway but without the reminder, and let the user know.
    var saveWithReminder = _reminderEnabled;
    if (_reminderEnabled) {
      final granted = await NotificationService.instance.requestPermissions();
      if (!granted) {
        saveWithReminder = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Notification permission denied — habit saved without reminder.',
              ),
            ),
          );
        }
      }
    }

    final provider = context.read<HabitProvider>();

    if (_isEditing) {
      final updated = widget.habit!.copyWith(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        colorName: _color,
        iconName: _icon,
        clearReminder: !saveWithReminder,
        reminderHour: saveWithReminder ? _reminderTime.hour : null,
        reminderMinute: saveWithReminder ? _reminderTime.minute : null,
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
      );
      await provider.addHabit(newHabit);
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit habit' : 'New habit'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Exercise, Read, Meditate',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter a name';
                return null;
              },
            ),
            const SizedBox(height: 16),
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
                        color: selected ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
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
                          ? colorFor(_color).withOpacity(0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? colorFor(_color)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(e.value, color: colorFor(_color)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
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
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }
}
