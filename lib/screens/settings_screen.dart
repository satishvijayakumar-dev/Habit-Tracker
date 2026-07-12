import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/community_service.dart';
import '../services/habit_provider.dart';
import '../theme/app_theme.dart';
import 'change_persona_screen.dart';
import 'paywall_screen.dart';
import 'profile_screen.dart';
import 'reminders_screen.dart';
import 'sign_in_screen.dart';

/// Human-readable label for the auth provider id.
String _providerLabel(String? provider) {
  switch (provider) {
    case 'google':
      return 'Google';
    case 'apple':
      return 'Apple';
    case 'email':
      return 'email';
    case null:
      return 'community sign-in';
    default:
      return provider;
  }
}

/// Permanently deletes the user's cloud account (via the delete-account edge
/// function) and wipes all on-device data, then returns to a fresh app state.
/// Two-step confirmation so it can never fire by accident. Required by Apple
/// App Store Guideline 5.1.1(v) for any app offering account creation.
Future<void> _confirmDeleteAccount(
  BuildContext context,
  CommunityService community,
  HabitProvider provider,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.delete_forever_outlined, color: Ah.danger),
      title: const Text('Delete your account?'),
      content: Text(
        'This permanently deletes your account'
        '${community.currentUserEmail != null ? ' (${community.currentUserEmail})' : ''} '
        'and everything tied to it — your community profile, groups, and '
        'messages — plus all activity, plans, and progress on this device.\n\n'
        'This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Ah.danger),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Delete account'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  if (!context.mounted) return;

  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    await community.deleteAccount(); // cloud account + community data, then sign-out
    await provider.deleteAllLocalData(); // on-device wipe
    navigator.pop(); // dismiss progress
    navigator.popUntil((route) => route.isFirst); // back to a fresh start
    messenger.showSnackBar(
      const SnackBar(content: Text('Your account has been deleted.')),
    );
  } catch (_) {
    navigator.pop(); // dismiss progress — keep the account intact on failure
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
            "Couldn't delete your account. Check your connection and try again."),
      ),
    );
  }
}

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
            if (community.isSignedIn)
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Ah.mint.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(Ah.rSm),
                  ),
                  child: const Icon(Icons.account_circle_outlined,
                      color: Ah.mint, size: 20),
                ),
                title: Text(
                    community.currentUserName ??
                        community.currentUserEmail ??
                        'Signed in',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  community.currentUserName != null &&
                          community.currentUserEmail != null
                      ? '${community.currentUserEmail} · via ${_providerLabel(community.currentUserProvider)}'
                      : 'Signed in via ${_providerLabel(community.currentUserProvider)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
            community.isSignedIn
                ? _SettingsTile(
                    icon: Icons.logout,
                    color: Ah.danger,
                    title: 'Sign out',
                    subtitle: 'Leave the community on this device',
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sign out?'),
                          content: Text(
                            'You\'ll be signed out of the community as '
                            '${community.currentUserEmail ?? "this account"}. '
                            'Your activity, plan, and progress stay on this device.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Sign out'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      await community.signOut();
                      messenger.showSnackBar(
                        const SnackBar(
                            content: Text('Signed out of community')),
                      );
                    },
                  )
                : _SettingsTile(
                    icon: Icons.login,
                    color: Ah.mint,
                    title: 'Sign in',
                    subtitle: 'Join the community & unlock your smart coach',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    ),
                  ),
            if (community.isSignedIn)
              _SettingsTile(
                icon: Icons.delete_forever_outlined,
                color: Ah.danger,
                title: 'Delete account',
                subtitle: 'Permanently remove your account and data',
                onTap: () => _confirmDeleteAccount(context, community, provider),
              ),
          ]),
          const SizedBox(height: Ah.s16),
          Center(
            child: Text('ActivHealth · v2.1.0',
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
