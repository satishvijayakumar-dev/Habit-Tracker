import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/habit_provider.dart';
import '../theme/app_theme.dart';

class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final profile = provider.profile;
    final textTheme = Theme.of(context).textTheme;
    final message =
        'Join me on ActivHealth. My plan: ${provider.selectedPath ?? "coached fitness"} in ${profile?.areaName ?? "my City/Town"}.';

    return Scaffold(
      appBar: AppBar(title: const Text('Invite friends')),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(Ah.gutter, Ah.s8, Ah.gutter, Ah.s32),
        children: [
          Container(
            padding: const EdgeInsets.all(Ah.gutter),
            decoration: BoxDecoration(
              gradient: Ah.brandGradient,
              borderRadius: BorderRadius.circular(Ah.rXl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.favorite, color: Ah.onAccent, size: 36),
                const SizedBox(height: Ah.s16),
                Text(
                  'Train with people\nyou trust',
                  style:
                      textTheme.headlineLarge?.copyWith(color: Ah.onAccent),
                ),
                const SizedBox(height: Ah.s8),
                Text(
                  'Share your plan, invite friends, or bring your local group along.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Ah.onAccent.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Ah.s16),
          _ShareOption(
            label: 'WhatsApp',
            detail: 'Copy invite text for a WhatsApp message',
            icon: Icons.chat_bubble_outline,
            color: Ah.mint,
            message: message,
          ),
          _ShareOption(
            label: 'Instagram',
            detail: 'Copy a short caption for Stories or DMs',
            icon: Icons.camera_alt_outlined,
            color: Ah.accent,
            message: message,
          ),
          _ShareOption(
            label: 'TikTok',
            detail: 'Copy a workout update caption',
            icon: Icons.music_note_outlined,
            color: Ah.info,
            message: message,
          ),
          _ShareOption(
            label: 'Email',
            detail: 'Copy a longer invite for email',
            icon: Icons.mail_outline,
            color: Ah.warning,
            message: message,
          ),
          const SizedBox(height: Ah.s8),
          Text(
            'Direct platform posting arrives with the sharing SDK. For this beta, these buttons prepare invite text without pretending to post on your behalf.',
            style: textTheme.labelSmall?.copyWith(height: 1.4),
            textAlign: TextAlign.center,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: Ah.s8),
      child: Card(
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Ah.tint(color),
              borderRadius: BorderRadius.circular(Ah.rSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(label),
          subtitle: Text(detail),
          trailing: const Icon(Icons.copy, size: 18),
          onTap: () async {
            HapticFeedback.selectionClick();
            await Clipboard.setData(ClipboardData(text: message));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label invite copied')),
              );
            }
          },
        ),
      ),
    );
  }
}
