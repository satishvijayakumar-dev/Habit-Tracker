import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/services/coach_brain.dart';

void main() {
  group('intent classification', () {
    test('time constraints', () {
      expect(CoachBrain.classify('I only have 20 minutes'),
          CoachIntent.shortOnTime);
      expect(
          CoachBrain.classify('feeling busy today'), CoachIntent.shortOnTime);
    });

    test('pain / injury', () {
      expect(CoachBrain.classify('my knees hurt'), CoachIntent.pain);
      expect(CoachBrain.classify('lower back is sore'), CoachIntent.pain);
    });

    test('no equipment / home', () {
      expect(CoachBrain.classify('I am at home with no equipment'),
          CoachIntent.noEquipment);
    });

    test('easier / harder', () {
      expect(CoachBrain.classify('make it easier'), CoachIntent.easier);
      expect(
          CoachBrain.classify('this is too easy, push me'), CoachIntent.harder);
    });

    test('nutrition / community / motivation', () {
      expect(CoachBrain.classify('what should I eat?'), CoachIntent.nutrition);
      expect(CoachBrain.classify('find me a group'), CoachIntent.community);
      expect(
          CoachBrain.classify('feeling unmotivated'), CoachIntent.motivation);
    });

    test('plan and unknown', () {
      expect(CoachBrain.classify('what should I do today'), CoachIntent.plan);
      expect(CoachBrain.classify('asdfqwer'), CoachIntent.unknown);
    });
  });

  group('replies', () {
    const ctx = CoachContext(name: 'Sam', loopsRemaining: 2, dailyStreak: 5);

    test('addresses the user by name', () {
      expect(CoachBrain.reply('make it easier', ctx), contains('Sam'));
    });

    test('pain reply prioritises safety', () {
      final r = CoachBrain.reply('my knee hurts', ctx).toLowerCase();
      expect(r, anyOf(contains('pain-free'), contains('stop')));
    });

    test('plan reply references remaining loops', () {
      expect(CoachBrain.reply('plan my day', ctx), contains('2'));
    });

    test('streak reply references the streak length', () {
      expect(CoachBrain.reply('keep my streak', ctx), contains('5-day'));
    });

    test('every intent returns a non-empty reply', () {
      for (final msg in [
        'short on time',
        'knee pain',
        'no equipment',
        'easier',
        'harder',
        'swap squats',
        'food',
        'group',
        'tired',
        'plan',
        'streak',
        'hello',
        'xyz',
      ]) {
        expect(CoachBrain.reply(msg, ctx).trim(), isNotEmpty);
      }
    });
  });
}
