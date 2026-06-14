import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../services/habit_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _areaController = TextEditingController();
  String _sex = 'Prefer not to say';
  String _goal = 'Build consistency';
  String _level = 'Getting started';
  bool _shareApproxLocation = false;
  bool _loaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    final providerRead = context.read<HabitProvider>();
    _nameController.text = providerRead.userName;
    final profile = providerRead.profile;
    if (profile != null) {
      _ageController.text = '${profile.age}';
      _heightController.text = profile.heightCm.toStringAsFixed(0);
      _weightController.text = profile.weightKg.toStringAsFixed(1);
      _areaController.text = profile.areaName;
      _sex = profile.sex;
      _goal = profile.fitnessGoal;
      _level = profile.activityLevel;
      _shareApproxLocation = profile.shareApproxLocation;
    }
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final profile = provider.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          if (profile != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.monitor_weight_outlined),
                title: Text('BMI ${profile.bmi.toStringAsFixed(1)}'),
                subtitle: Text(profile.bmiLabel),
                trailing: Text('${provider.starPoints} pts'),
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'What your coach calls you',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Age',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _sex,
            decoration: const InputDecoration(
              labelText: 'Sex',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Female', child: Text('Female')),
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
              DropdownMenuItem(
                value: 'Prefer not to say',
                child: Text('Prefer not to say'),
              ),
            ],
            onChanged: (value) => setState(() => _sex = value!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Height cm',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Weight kg',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _goal,
            decoration: const InputDecoration(
              labelText: 'Primary goal',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Build consistency',
                child: Text('Build consistency'),
              ),
              DropdownMenuItem(
                  value: 'Lose weight', child: Text('Lose weight')),
              DropdownMenuItem(
                value: 'Build strength',
                child: Text('Build strength'),
              ),
              DropdownMenuItem(value: 'Run better', child: Text('Run better')),
              DropdownMenuItem(
                  value: 'Feel healthier', child: Text('Feel healthier')),
            ],
            onChanged: (value) => setState(() => _goal = value!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _level,
            decoration: const InputDecoration(
              labelText: 'Activity level',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Getting started',
                child: Text('Getting started'),
              ),
              DropdownMenuItem(
                value: 'Some activity',
                child: Text('Some activity'),
              ),
              DropdownMenuItem(value: 'Active', child: Text('Active')),
            ],
            onChanged: (value) => setState(() => _level = value!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _areaController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'City/Town',
              hintText: 'Example: Croydon or Watford',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Visible to nearby members'),
            subtitle: const Text(
              'Shares only your approximate area (~1 km) — never your exact location.',
            ),
            value: _shareApproxLocation,
            onChanged: (value) => setState(() => _shareApproxLocation = value),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _save(context),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save profile'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final height = double.tryParse(_heightController.text.trim()) ?? 0;
    final weight = double.tryParse(_weightController.text.trim()) ?? 0;
    final area = _areaController.text.trim();
    if (age <= 0 || height <= 0 || weight <= 0 || area.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete age, height, weight, and City/Town'),
        ),
      );
      return;
    }

    final provider = context.read<HabitProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await provider.setUserName(_nameController.text);
    await provider.saveProfile(
      UserProfile(
        age: age,
        sex: _sex,
        heightCm: height,
        weightKg: weight,
        fitnessGoal: _goal,
        activityLevel: _level,
        areaName: area,
        shareApproxLocation: _shareApproxLocation,
        updatedAt: DateTime.now(),
      ),
    );

    if (mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('Profile saved')));
    }
  }
}
