import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/community_service.dart';
import '../services/habit_provider.dart';
import '../theme/app_theme.dart';
import 'change_persona_screen.dart';
import 'paywall_screen.dart';
import 'profile_screen.dart';
import 'reminders_screen.dart';

/// Standard-app settings: profile, persona, reminders, community, privacy,
/// account, about — the home for everything that isn't a daily action.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final community = CommunityService();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Ah.gutter, Ah.s8, Ah.gutter, Ah.s32),
        children: [
          const _SectionHeader('You'),
          _SettingsGroup(children: [
            _SettingsTile(
              icon: Icons.person_outline,
              color: Ah.info,
              title: 'Profile & body metrics',
              subtitle: provider.userName.isEmpty
                  ? 'Name, age, height, weight, goal'
                  : provider.userName,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
            _SettingsTile(
              icon: Icons.swap_horiz,
              color: const Color(0xFF9B8AFB),
              title: 'Change persona',
              subtitle: provider.selectedPath ?? 'Not set',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangePersonaScreen()),
              ),
            ),
          ]),
          const SizedBox(height: Ah.s16),
          const _SectionHeader('Coaching'),
          _SettingsGroup(children: [
            _SettingsTile(
              icon: Icons.notifications_active_outlined,
              color: Ah.accent,
              title: 'Reminders',
              subtitle: provider.reminderMinutes.isEmpty
                  ? 'None set'
                  : '${provider.reminderMinutes.length} daily',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RemindersScreen()),
              ),
            ),
            _SettingsTile(
              icon: Icons.workspace_premium,
              color: Ah.warning,
              title: provider.isPro ? 'ActivHealth Pro — active' : 'Go Pro',
              subtitle: provider.isPro
                  ? 'Unlimited loops + full insights'
                  : 'Unlock unlimited loops and more',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              ),
            ),
          ]),
          const SizedBox(height: Ah.s16),
          const _SectionHeader('Community & privacy'),
          _SettingsGroup(children: [
            SwitchListTile(
              secondary: const Icon(Icons.groups_outlined, color: Ah.mint),
              title: const Text('Join the community'),
              subtitle: const Text(
                  'Be discoverable to like-minded people nearby. You can opt out any time.'),
              value: provider.communityOptIn,
              onChanged: (v) {
                provider.setCommunityOptIn(v);
                if (v) {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("You're in"),
                      content: const Text(
                          'When you opt in, others nearby with similar interests can find your group and ask to join or chat. Only your approximate area is shared — never your exact location. Opt out or silence anytime here.'),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Got it'),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ]),
          const SizedBox(height: Ah.s16),
          const _SectionHeader('Account'),
          _SettingsGroup(children: [
            _SettingsTile(
              icon: Icons.lock_outline,
              color: Ah.info,
              title: 'Security',
              subtitle: 'Device lock protects your health data',
              onTap: () => showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Security'),
                  content: const Text(
                      'ActivHealth uses your device biometrics / passcode to protect your profile, body metrics, and plan. Manage Face ID in iOS Settings.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close')),
                  ],
                ),
              ),
            ),
            _SettingsTile(
              icon: Icons.logout,
              color: Ah.danger,
              title: 'Sign out',
              subtitle: community.isSignedIn
                  ? 'Signed in to community'
                  : 'Not signed in to community',
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                if (community.isSignedIn) {
                  await community.signOut();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Signed out of community')),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Community sign-in arrives with the next update.')),
                  );
                }
              },
            ),
          ]),
          const SizedBox(height: Ah.s16),
          Center(
            child: Text('ActivHealth · v2.0',
                style: Theme.of(context).textTheme.labelSmall),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: Ah.s4, bottom: Ah.s8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.4,
              color: Ah.textTertiary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const Divider(height: 1),
          ]
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(Ah.rSm),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}
