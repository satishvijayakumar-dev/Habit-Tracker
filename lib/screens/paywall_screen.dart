import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/habit_provider.dart';
import '../theme/app_theme.dart';

/// ActivHealth Pro.
///
/// Beta behaviour: real App Store purchases (StoreKit / RevenueCat) are a
/// founder go-live task. Until then this screen sells the tier honestly
/// and unlocks it free for beta testers — so the upgrade journey, gating,
/// and copy are all real and testable today.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  static const _benefits = [
    ('Unlimited loops', 'Free covers ${HabitProvider.freeLoopLimit} active loops — Pro removes the cap'),
    ('Full insights', 'Trends, streaks history, and weekly recaps'),
    ('Personalised plans', 'Sessions tuned to your check-ins and goal'),
    ('Early access', 'Community features and new tools land here first'),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('ActivHealth Pro')),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(Ah.gutter, Ah.s8, Ah.gutter, Ah.s32),
        children: [
          Container(
            padding: const EdgeInsets.all(Ah.s24),
            decoration: BoxDecoration(
              gradient: Ah.brandGradient,
              borderRadius: BorderRadius.circular(Ah.rXl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.workspace_premium,
                    color: Ah.onAccent, size: 36),
                const SizedBox(height: Ah.s12),
                Text(
                  'Train with the\nfull coach',
                  style: textTheme.headlineLarge
                      ?.copyWith(color: Ah.onAccent),
                ),
                const SizedBox(height: Ah.s8),
                Text(
                  'One small subscription keeps ActivHealth independent — no ads, no selling your health data. Ever.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Ah.onAccent.withValues(alpha: 0.8),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Ah.s24),

          ..._benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: Ah.s12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: Ah.mint, size: 22),
                  const SizedBox(width: Ah.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.$1, style: textTheme.titleMedium),
                        Text(b.$2, style: textTheme.labelMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Ah.s16),

          // Pricing
          const Row(
            children: [
              Expanded(
                child: _PriceCard(
                  title: 'Monthly',
                  price: '£3.99',
                  per: '/month',
                  highlighted: false,
                ),
              ),
              SizedBox(width: Ah.s12),
              Expanded(
                child: _PriceCard(
                  title: 'Yearly',
                  price: '£24.99',
                  per: '/year',
                  badge: 'Save 48%',
                  highlighted: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: Ah.s24),

          if (provider.isPro) ...[
            const Card(
              child: ListTile(
                leading: Icon(Icons.verified, color: Ah.mint),
                title: Text('Pro is active'),
                subtitle: Text('Thanks for backing ActivHealth.'),
              ),
            ),
          ] else ...[
            FilledButton(
              onPressed: () async {
                await provider.setPro(true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Pro unlocked — free during the beta. Enjoy!'),
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Unlock Pro — free during beta'),
            ),
            const SizedBox(height: Ah.s8),
            Center(
              child: Text(
                'App Store billing arrives at launch. Beta testers keep founder pricing.',
                textAlign: TextAlign.center,
                style: textTheme.labelSmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final String title;
  final String price;
  final String per;
  final String? badge;
  final bool highlighted;

  const _PriceCard({
    required this.title,
    required this.price,
    required this.per,
    this.badge,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Ah.s16),
      decoration: BoxDecoration(
        color: Ah.surface1,
        borderRadius: BorderRadius.circular(Ah.rLg),
        border: Border.all(
          color: highlighted ? Ah.accent : Ah.hairline,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: textTheme.labelMedium)),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Ah.s8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Ah.tint(Ah.accent),
                    borderRadius: BorderRadius.circular(Ah.rSm),
                  ),
                  child: Text(
                    badge!,
                    style: textTheme.labelSmall?.copyWith(color: Ah.accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Ah.s8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: textTheme.headlineMedium),
              Text(per, style: textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}
