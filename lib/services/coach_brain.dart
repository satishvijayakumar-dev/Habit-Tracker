/// The Coach's rule-based reasoning, extracted as a pure function so the
/// chat input works offline today and is unit-testable. The same interface
/// can later delegate to an LLM edge function without changing callers.
///
/// No Flutter imports — keep this pure.
library;

class CoachContext {
  final String name;
  final String persona;
  final String goal;
  final String energy; // Low | Steady | High
  final int missedSessions;
  final int loopsRemaining;
  final int dailyStreak;

  const CoachContext({
    this.name = '',
    this.persona = '',
    this.goal = '',
    this.energy = 'Steady',
    this.missedSessions = 0,
    this.loopsRemaining = 0,
    this.dailyStreak = 0,
  });
}

enum CoachIntent {
  shortOnTime,
  pain,
  noEquipment,
  easier,
  harder,
  swap,
  nutrition,
  community,
  motivation,
  plan,
  streak,
  greeting,
  unknown,
}

abstract final class CoachBrain {
  /// Classify a free-text message into an intent.
  static CoachIntent classify(String message) {
    final m = message.toLowerCase();
    bool has(List<String> ws) => ws.any(m.contains);

    if (has([
      '20 min',
      '15 min',
      '10 min',
      'short on time',
      'quick',
      'no time',
      'only have',
      'busy'
    ])) {
      return CoachIntent.shortOnTime;
    }
    if (has([
      'pain',
      'hurt',
      'knee',
      'back',
      'injur',
      'sore',
      'ankle',
      'shoulder'
    ])) {
      return CoachIntent.pain;
    }
    if (has([
      'no equipment',
      'no gym',
      'at home',
      'home workout',
      'no weights',
      'bodyweight'
    ])) {
      return CoachIntent.noEquipment;
    }
    if (has(['easier', 'too hard', 'lighter', 'reduce', 'scale down'])) {
      return CoachIntent.easier;
    }
    if (has(['harder', 'too easy', 'tougher', 'more challenge', 'push me'])) {
      return CoachIntent.harder;
    }
    if (has(
        ['swap', 'replace', 'different exercise', 'instead of', 'change ex'])) {
      return CoachIntent.swap;
    }
    if (has([
      'eat',
      'food',
      'nutrition',
      'protein',
      'meal',
      'hungry',
      'calorie',
      'diet',
      'fuel'
    ])) {
      return CoachIntent.nutrition;
    }
    if (has([
      'group',
      'community',
      'people',
      'buddy',
      'partner',
      'club',
      'social'
    ])) {
      return CoachIntent.community;
    }
    if (has([
      'tired',
      'unmotivated',
      'cant be',
      "can't be",
      'lazy',
      'give up',
      'demotivated',
      'low energy'
    ])) {
      return CoachIntent.motivation;
    }
    if (has(['plan', 'today', 'what should', 'next', 'do now'])) {
      return CoachIntent.plan;
    }
    if (has(['streak', 'missed', 'broke my', 'keep my'])) {
      return CoachIntent.streak;
    }
    if (has(['hi', 'hello', 'hey', 'morning', 'thanks', 'thank you'])) {
      return CoachIntent.greeting;
    }
    return CoachIntent.unknown;
  }

  /// Generate a coach reply for a free-text message.
  static String reply(String message, CoachContext ctx) {
    final who = ctx.name.isEmpty ? '' : '${ctx.name}, ';
    switch (classify(message)) {
      case CoachIntent.shortOnTime:
        return '${who}no problem. I\'ll trim today to a focused 20 minutes: '
            'a quick warm-up, two main moves, and a short finisher. Short and '
            'done beats skipped.';
      case CoachIntent.pain:
        return 'Thanks for telling me. Stop anything sharp. We\'ll switch to '
            'pain-free movement only — gentle mobility, a short walk, and skip '
            'loaded work on that area today. If pain persists, see a '
            'professional.';
      case CoachIntent.noEquipment:
        return '${who}home and equipment-free works. Today becomes a bodyweight '
            'session: squats, push-ups (or incline), glute bridges, and a plank '
            'finisher. Same effect, zero kit.';
      case CoachIntent.easier:
        return '${who}scaling it down. Fewer sets, easier variations, and '
            'longer rests — we keep the habit alive and protect recovery.';
      case CoachIntent.harder:
        return '${who}let\'s push. I\'ll add a set to the main lifts, shorten '
            'rests, and finish with a burnout. Keep form first.';
      case CoachIntent.swap:
        return 'Sure — tell me which exercise and I\'ll swap it for one that '
            'hits the same muscles with what you\'ve got.';
      case CoachIntent.nutrition:
        return '${who}open Fuel and I\'ll show today\'s calorie and protein '
            'target plus natural foods to close the gap — light snack, full '
            'meal, or post-workout.';
      case CoachIntent.community:
        return ctx.persona.toLowerCase().contains('social')
            ? '${who}you thrive with people. Check Community for a group near '
                'you — showing up with others is your consistency superpower.'
            : '${who}a little accountability helps. There may be a beginner-'
                'friendly group near you in Community worth a look.';
      case CoachIntent.motivation:
        return '${who}low days are normal — the goal today is just to not break '
            'the chain. Do the smallest version: a 10-minute walk counts. '
            'Momentum, not perfection.';
      case CoachIntent.plan:
        if (ctx.loopsRemaining > 0) {
          return '${who}your best next action: close one loop now — pick the '
              'easiest. ${ctx.loopsRemaining} left today.';
        }
        if (ctx.missedSessions > 0) {
          return '${who}loops are done. One ${ctx.energy == 'Low' ? 'easy ' : ''}'
              'session would put the week back on track.';
        }
        return '${who}you\'re on track. Keep it gentle and fuel well today.';
      case CoachIntent.streak:
        return ctx.dailyStreak > 0
            ? '${who}you\'re on a ${ctx.dailyStreak}-day streak. One small '
                'action today protects it — even a short walk or stretch counts.'
            : '${who}let\'s start a streak today. One health-positive action is '
                'all it takes to begin.';
      case CoachIntent.greeting:
        return '${who}good to see you. Tell me how you\'re feeling or what '
            'you\'ve got time for, and I\'ll shape today around it.';
      case CoachIntent.unknown:
        return '${who}I can adjust your session (time, difficulty, swaps, '
            'injuries), suggest food, find a group, or plan today. What do you '
            'need?';
    }
  }
}
