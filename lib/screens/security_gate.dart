import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../services/habit_provider.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';

/// Optional biometric lock for returning users with a health profile.
///
/// Safety rules (learned the hard way):
///  - NEVER hard-lock the app: if biometrics are unavailable, unenrolled,
///    or fail, the user can always continue.
///  - Allow device passcode fallback (biometricOnly: false).
///  - Nothing sensitive is reachable from the locked state.
class SecurityGate extends StatefulWidget {
  const SecurityGate({super.key});

  @override
  State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _checking = true;
  bool _unlocked = false;
  bool _authUnavailable = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAccess());
  }

  Future<void> _checkAccess() async {
    final provider = context.read<HabitProvider>();
    if (!provider.hasProfile) {
      setState(() {
        _checking = false;
        _unlocked = true;
      });
      return;
    }

    await _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() {
      _checking = true;
      _message = null;
    });

    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) {
        // No biometrics and no passcode on this device — never lock out.
        setState(() {
          _checking = false;
          _unlocked = true;
        });
        return;
      }

      final ok = await _auth.authenticate(
        localizedReason: 'Unlock ActivHealth to view your health profile.',
        options: const AuthenticationOptions(
          // Device passcode is an acceptable fallback when Face ID is
          // unavailable or not recognised.
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      setState(() {
        _checking = false;
        _unlocked = ok;
        _message = ok ? null : 'Unlock was not confirmed. Try again.';
      });
    } catch (e) {
      // Auth plugin failed entirely (no biometrics, no passcode, or a
      // platform error). Locking the user out of their own data is worse
      // than skipping the lock — offer a way in.
      setState(() {
        _checking = false;
        _authUnavailable = true;
        _message = 'Secure unlock could not start on this device.';
      });
    }
  }

  void _continueWithoutLock() {
    setState(() => _unlocked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return const HomeShell();

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Ah.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: Ah.surface2,
                  borderRadius: BorderRadius.circular(Ah.rLg),
                  border: Border.all(color: Ah.hairline),
                  boxShadow: Ah.accentGlow(opacity: 0.15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Ah.rLg),
                  child: Image.asset(
                    'assets/images/activhealth_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.favorite,
                      color: Ah.accent,
                      size: 42,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Ah.s24),
              Text('Welcome back', style: textTheme.displayMedium),
              const SizedBox(height: Ah.s8),
              Text(
                'Your profile, body metrics, and plan are protected with your device lock.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: Ah.textSecondary, height: 1.4),
              ),
              if (_message != null) ...[
                const SizedBox(height: Ah.s16),
                Text(
                  _message!,
                  style:
                      textTheme.bodyMedium?.copyWith(color: Ah.warning),
                ),
              ],
              const Spacer(),
              FilledButton.icon(
                onPressed: _checking ? null : _authenticate,
                icon: _checking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_open),
                label: Text(_checking ? 'Checking…' : 'Unlock'),
              ),
              if (_authUnavailable) ...[
                const SizedBox(height: Ah.s8),
                TextButton(
                  onPressed: _checking ? null : _continueWithoutLock,
                  child: const Text('Continue without unlocking'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
