import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/habit_provider.dart';

class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final profile = provider.profile;
    final message =
        'Join me on ActivHealth. My plan: ${provider.selectedPath ?? "AI fitness trainer"} in ${profile?.areaName ?? "my City/Town"}.';

    return Scaffold(
      appBar: AppBar(title: const Text('Share ActivHealth')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.favorite, color: Colors.white, size: 42),
                SizedBox(height: 18),
                Text(
                  'Train with people you trust',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Share your plan, invite friends, or collaborate with your local group.',
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ShareOption(
            label: 'WhatsApp',
            detail: 'Copy invite text for a WhatsApp message',
            icon: Icons.chat_bubble_outline,
            color: const Color(0xFF22C55E),
            message: message,
          ),
          _ShareOption(
            label: 'Instagram',
            detail: 'Copy a short caption for Stories or DMs',
            icon: Icons.camera_alt_outlined,
            color: const Color(0xFFE11D48),
            message: message,
          ),
          _ShareOption(
            label: 'TikTok',
            detail: 'Copy a workout update caption',
            icon: Icons.music_note_outlined,
            color: const Color(0xFF111827),
            message: message,
          ),
          _ShareOption(
            label: 'Email',
            detail: 'Copy a longer invite for email',
            icon: Icons.mail_outline,
            color: const Color(0xFF2563EB),
            message: message,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Direct platform posting will be connected when we add the sharing SDK/backend. For this TestFlight build, these buttons prepare safe invite text without pretending to post on your behalf.',
                style: TextStyle(color: Colors.grey.shade700, height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final String label;
  final String detail;
  final IconData icon;
  final Color color;
  final String message;

  const _ShareOption({
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        subtitle: Text(detail),
        trailing: const Icon(Icons.copy),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: message));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label invite copied')),
            );
          }
        },
      ),
    );
  }
}
