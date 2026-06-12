import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ActivHealth's signature element: one coral->ember gradient ring.
///
/// Outer ring: each active loop fills an equal segment when protected today.
/// Inner thin mint arc: active minutes this week vs the weekly target.
/// Center: count-up number + one-word state.
class MomentumRing extends StatelessWidget {
  final int loopsDone;
  final int loopsTotal;
  final int activeMinutes;
  final int minutesTarget;
  final double size;

  const MomentumRing({
    super.key,
    required this.loopsDone,
    required this.loopsTotal,
    required this.activeMinutes,
    required this.minutesTarget,
    this.size = 210,
  });

  bool get _dayClosed => loopsTotal > 0 && loopsDone >= loopsTotal;

  String get _stateWord {
    if (loopsTotal == 0) return 'Ready';
    if (_dayClosed) return 'Closed';
    if (loopsDone > 0) return 'Building';
    return 'Open';
  }

  @override
  Widget build(BuildContext context) {
    final loopProgress =
        loopsTotal == 0 ? 0.0 : (loopsDone / loopsTotal).clamp(0.0, 1.0);
    final minuteProgress = minutesTarget == 0
        ? 0.0
        : (activeMinutes / minutesTarget).clamp(0.0, 1.0);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: loopProgress),
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 800),
      curve: Curves.easeOutQuart,
      builder: (context, animatedLoop, _) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: minuteProgress),
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 900),
          curve: Curves.easeOutQuart,
          builder: (context, animatedMinutes, _) {
            return Container(
              width: size,
              height: size,
              decoration: _dayClosed
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: Ah.accentGlow(opacity: 0.30),
                    )
                  : null,
              child: CustomPaint(
                painter: _RingPainter(
                  loopProgress: animatedLoop,
                  segments: loopsTotal,
                  minuteProgress: animatedMinutes,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loopsTotal == 0 ? '—' : '$loopsDone/$loopsTotal',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _stateWord,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: _dayClosed ? Ah.mint : Ah.textSecondary,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: Ah.s4),
                      Text(
                        '$activeMinutes min this week',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double loopProgress;
  final int segments;
  final double minuteProgress;

  _RingPainter({
    required this.loopProgress,
    required this.segments,
    required this.minuteProgress,
  });

  static const double _stroke = 14;
  static const double _innerStroke = 5;
  static const double _gapRadians = 0.06;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - _stroke / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = Ah.surface3;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [Ah.accent, Ah.ember, Ah.accent],
        transform: GradientRotation(startAngle),
      ).createShader(rect);

    if (segments <= 1) {
      canvas.drawArc(rect, startAngle, math.pi * 2, false, track);
      if (loopProgress > 0) {
        canvas.drawArc(
            rect, startAngle, math.pi * 2 * loopProgress, false, progressPaint);
      }
    } else {
      // Segmented track + fill so each loop owns an equal slice of the day.
      final sweepPer = (math.pi * 2 / segments) - _gapRadians;
      final filledSweepTotal = math.pi * 2 * loopProgress;
      var consumed = 0.0;
      for (var i = 0; i < segments; i++) {
        final segStart =
            startAngle + i * (sweepPer + _gapRadians) + _gapRadians / 2;
        canvas.drawArc(rect, segStart, sweepPer, false, track);

        final remaining = filledSweepTotal - consumed;
        if (remaining > 0) {
          final fill = remaining.clamp(0.0, sweepPer);
          canvas.drawArc(rect, segStart, fill, false, progressPaint);
        }
        consumed += sweepPer + _gapRadians;
      }
    }

    // Inner mint arc: weekly active minutes.
    final innerRadius = radius - _stroke / 2 - 10;
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
    final innerTrack = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _innerStroke
      ..strokeCap = StrokeCap.round
      ..color = Ah.surface2;
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _innerStroke
      ..strokeCap = StrokeCap.round
      ..color = Ah.mint;

    canvas.drawArc(innerRect, startAngle, math.pi * 2, false, innerTrack);
    if (minuteProgress > 0) {
      canvas.drawArc(innerRect, startAngle, math.pi * 2 * minuteProgress,
          false, innerPaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.loopProgress != loopProgress ||
      old.segments != segments ||
      old.minuteProgress != minuteProgress;
}
