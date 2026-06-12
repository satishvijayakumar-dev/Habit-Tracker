import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../services/habit_provider.dart';
import 'home_shell.dart';
import 'profile_screen.dart';

class SecurityGate extends StatefulWidget {
  const SecurityGate({super.key});

  @override
  State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _checking = true;
  bool _unlocked = false;
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
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      if (!canCheck || !supported) {
        setState(() {
          _checking = false;
          _message =
              'Biometric unlock is not available on this device. You can continue for this beta build.';
        });
        return;
      }

      final ok = await _auth.authenticate(
        localizedReason: 'Unlock ActivHealth to view your health profile.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      setState(() {
        _checking = false;
        _unlocked = ok;
        _message = ok ? null : 'Face ID was not confirmed.';
      });
    } catch (e) {
      setState(() {
        _checking = false;
        _message = 'Secure unlock could not start. You can retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return const HomeShell();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/activhealth_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.favorite,
                      color: Color(0xFFE53935),
                      size: 42,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Unlock your trainer',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                'ActivHealth protects your profile, body metrics, plan, and local community visibility with device biometrics.',
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(_message!, style: const TextStyle(height: 1.35)),
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
                    : const Icon(Icons.face),
                label: Text(_checking ? 'Checking...' : 'Use Face ID'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _checking
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        ),
                icon: const Icon(Icons.person_outline),
                label: const Text('Review profile'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
