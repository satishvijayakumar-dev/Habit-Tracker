import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/community_service.dart';
import '../theme/app_theme.dart';
import '../widgets/coach_popup.dart';

/// Sign-in to unlock the live community. Apple (iOS) + Google via the
/// Supabase OAuth flow, and email OTP which needs no provider config.
/// Pops `true` once authenticated.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

enum _Step { methods, email, code }

class _SignInScreenState extends State<SignInScreen> {
  final _community = CommunityService();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  _Step _step = _Step.methods;
  bool _busy = false;
  StreamSubscription<AuthState>? _sub;

  @override
  void initState() {
    super.initState();
    // Single source of truth: when auth completes (incl. OAuth deep-link
    // return), close the screen.
    _sub = _community.authChanges.listen((state) {
      if (state.event == AuthChangeEvent.signedIn && mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on AuthException catch (e) {
      _toast(_friendly(e.message));
    } catch (_) {
      _toast('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendly(String raw) {
    final m = raw.toLowerCase();
    if (m.contains('provider') && m.contains('not enabled')) {
      return 'That sign-in option isn\'t switched on yet — try email for now.';
    }
    return raw;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      _toast('Enter a valid email');
      return;
    }
    await _run(() async {
      await _community.signInWithEmail(email);
      if (mounted) setState(() => _step = _Step.code);
      _toast('We emailed you a 6-digit code.');
    });
  }

  Future<void> _verifyCode() async {
    await _run(() =>
        _community.verifyEmailOtp(_emailController.text, _codeController.text));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _busy,
          child: ListView(
            padding:
                const EdgeInsets.fromLTRB(Ah.gutter, Ah.s8, Ah.gutter, Ah.s32),
            children: [
              const SizedBox(height: Ah.s16),
              const Center(child: CoachAvatar(size: 72)),
              const SizedBox(height: Ah.s24),
              Text('Join the community',
                  textAlign: TextAlign.center, style: textTheme.headlineMedium),
              const SizedBox(height: Ah.s8),
              Text(
                'Sign in to discover local groups, RSVP to sessions, and chat. '
                'Only your approximate area is ever shared.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium
                    ?.copyWith(color: Ah.textSecondary, height: 1.4),
              ),
              const SizedBox(height: Ah.s32),
              if (_step == _Step.methods) ..._methods(context),
              if (_step == _Step.email) ..._emailStep(context),
              if (_step == _Step.code) ..._codeStep(context),
              if (_busy) ...[
                const SizedBox(height: Ah.s24),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _methods(BuildContext context) => [
        if (Platform.isIOS) ...[
          _ProviderButton(
            label: 'Continue with Apple',
            icon: Icons.apple,
            background: Ah.textPrimary,
            foreground: Ah.bg,
            onTap: () {
              HapticFeedback.selectionClick();
              _run(_community.signInWithApple);
            },
          ),
          const SizedBox(height: Ah.s12),
        ],
        _ProviderButton(
          label: 'Continue with Google',
          icon: Icons.g_mobiledata,
          background: Ah.surface2,
          foreground: Ah.textPrimary,
          border: true,
          onTap: () {
            HapticFeedback.selectionClick();
            _run(_community.signInWithGoogle);
          },
        ),
        const SizedBox(height: Ah.s12),
        _ProviderButton(
          label: 'Continue with email',
          icon: Icons.mail_outline,
          background: Ah.accent,
          foreground: Ah.onAccent,
          onTap: () => setState(() => _step = _Step.email),
        ),
      ];

  List<Widget> _emailStep(BuildContext context) => [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'you@example.com',
          ),
        ),
        const SizedBox(height: Ah.s16),
        FilledButton(
          onPressed: _busy ? null : _sendCode,
          child: const Text('Email me a code'),
        ),
        const SizedBox(height: Ah.s8),
        TextButton(
          onPressed: () => setState(() => _step = _Step.methods),
          child: const Text('Back'),
        ),
      ];

  List<Widget> _codeStep(BuildContext context) => [
        Text('Enter the 6-digit code sent to ${_emailController.text.trim()}',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: Ah.s16),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          autofocus: true,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'Code'),
        ),
        const SizedBox(height: Ah.s8),
        FilledButton(
          onPressed: _busy ? null : _verifyCode,
          child: const Text('Verify & continue'),
        ),
        const SizedBox(height: Ah.s8),
        TextButton(
          onPressed: _busy ? null : _sendCode,
          child: const Text('Resend code'),
        ),
      ];
}

class _ProviderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final bool border;
  final VoidCallback onTap;

  const _ProviderButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    this.border = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(Ah.rMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Ah.rMd),
        child: Container(
          height: 52,
          decoration: border
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(Ah.rMd),
                  border: Border.all(color: Ah.hairline),
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 22),
              const SizedBox(width: Ah.s8),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}
