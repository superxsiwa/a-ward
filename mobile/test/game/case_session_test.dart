import 'dart:math';

import 'package:clock/clock.dart';
import 'package:criticalcare/game/case_session.dart';
import 'package:criticalcare/game/step_checker.dart';
import 'package:criticalcare/game/step_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/cases.dart';

void main() {
  final b = bed(1);
  var now = DateTime(2026, 10, 28, 9);

  /// Runs [body] with a clock the test moves by setting [now].
  T at<T>(T Function() body) => withClock(Clock(() => now), body);

  setUp(() => now = DateTime(2026, 10, 28, 9));

  CaseSession start() => CaseSession.start(b, random: Random(5));

  /// Answers the current step correctly and checks it.
  (CaseSession, Feedback?) pass(CaseSession s) => s.update((st) => answered(s.stage, st)).check();

  /// A check that fails: one option the case marks wrong on step 1, an unsafe card on step 4.
  (CaseSession, Feedback?) fail(CaseSession s) {
    final stage = s.stage;
    var st = answered(stage, s.state);
    if (stage.choices != null) st = st.toggleOption('fc4');
    if (stage.unorderedDrop != null) st = st.move('fa1', const PoolZone()).move('faw1', const DropBoxZone());
    if (stage.trays != null) st = st.move('fe1', const TrayZone('ftr2'));
    return s.update((_) => st).check();
  }

  test('a perfect play of bed 01: 6 passes, 3 stars, every step flawless', () => at(() {
    var s = start();
    final feedback = <Feedback?>[];
    for (var i = 0; i < 6; i++) {
      expect(s.stepIndex, i);
      Feedback? f;
      (s, f) = pass(s);
      feedback.add(f);
      if (i < 5) (s, _) = s.next();
    }
    expect(feedback.take(5), everyElement(isA<StepPassed>()));
    final result = (feedback.last! as CaseFinished).result;
    expect(result.stars, 3);
    expect(result.mistakes, 0);
    expect(result.flawlessSteps, 6);
    expect(result.traysSorted, 13, reason: '7 cards on step 2, 6 on step 3');
    expect(result.isEmergency, isTrue, reason: 'bed 01 is on alert');
    expect(s.finished, isTrue);
    expect(s.check().$2, isNull, reason: 'a finished session ignores actions');
  }));

  test('the last step passes straight to the result, without a step-passed sheet', () => at(() {
    var s = start();
    for (var i = 0; i < 5; i++) {
      (s, _) = pass(s);
      (s, _) = s.next();
    }
    final (_, f) = pass(s);
    expect(f, isA<CaseFinished>());
  }));

  test('a check that is not ready counts nothing and keeps the cards', () => at(() {
    final s = start().update((st) => st.toggleOption('fc1'));
    final (next, f) = s.check();
    expect(f, isA<NotReady>().having((n) => n.reason, 'reason', isA<EmptySlots>()));
    expect(next.mistakes, 0);
    expect(next.state.selected, {'fc1'});
  }));

  test('a wrong check marks red, counts a mistake and costs stars', () => at(() {
    var s = start();
    Feedback? f;
    (s, f) = fail(s);
    expect(f, isA<StepFailed>().having((x) => x.strike, 'strike', 1).having((x) => x.canShowAnswer, 'mercy', false));
    expect(s.mistakes, 1);
    expect(s.state.wrongOptions, {'fc4'});
    expect(s.liveStars, 2);
    expect(s.isPassed, isFalse);
    (s, f) = pass(s);
    expect(f, isA<StepPassed>());
    (s, _) = s.next();
    for (var i = 1; i < 6; i++) {
      (s, f) = pass(s);
      if (i < 5) (s, _) = s.next();
    }
    final result = (f! as CaseFinished).result;
    expect(result.stars, 2);
    expect(result.flawlessSteps, 5, reason: 'step 1 had a mistake');
  }));

  test('mercy rule: the 3rd mistake on a step offers the answer, which locks and passes it', () => at(() {
    var s = start();
    Feedback? f;
    (s, f) = fail(s);
    (s, f) = fail(s);
    expect(s.canShowAnswer, isFalse);
    expect(s.showAnswer().$2, isNull, reason: 'not before the 3rd strike');
    (s, f) = fail(s);
    expect(f, isA<StepFailed>().having((x) => x.canShowAnswer, 'mercy', true));
    expect(s.canShowAnswer, isTrue);
    (s, f) = s.showAnswer();
    expect(f, isA<AnswerShown>());
    expect(s.isPassed, isTrue);
    expect(s.state.locked, isTrue);
    expect(s.state.slots, ['fs1', 'fs2', 'fs3', 'fs4']);
    expect(s.liveStars, 1);
    expect(s.canShowAnswer, isFalse);
    (s, _) = s.next();
    expect(s.stepIndex, 1);
  }));

  test('the answer shown on the last step finishes the case on "go on"', () => at(() {
    var s = start();
    for (var i = 0; i < 5; i++) {
      (s, _) = pass(s);
      (s, _) = s.next();
    }
    for (var i = 0; i < 3; i++) {
      // The right order with the first two cards swapped.
      (s, _) = s.update((st) => answered(s.stage, st).move('fis1', const SlotZone(1))).check();
    }
    expect(s.canShowAnswer, isTrue);
    (s, _) = s.showAnswer();
    final (_, f) = s.next();
    expect((f! as CaseFinished).result.flawlessSteps, 5);
  }));

  group('step 2 timer', () {
    test('runs only on step 2, and counts down by the clock', () => at(() {
      var s = start();
      expect(s.deadline, isNull);
      (s, _) = pass(s);
      expect(s.deadline, isNull, reason: 'a pass stops nothing on step 1');
      (s, _) = s.next();
      expect(s.secondsLeft, 20);
      now = now.add(const Duration(milliseconds: 500));
      expect(s.secondsLeft, 20, reason: 'rounded up like the countdown');
      now = now.add(const Duration(milliseconds: 9600));
      expect(s.secondsLeft, 10);
      now = now.add(const Duration(seconds: 15));
      expect(s.secondsLeft, 0);
    }));

    test('a timeout counts a mistake, keeps the cards, and retry restarts the full time', () => at(() {
      var s = start();
      (s, _) = pass(s);
      (s, _) = s.next();
      s = s.update((st) => st.move('fe1', const TrayZone('ftr1')));
      now = now.add(const Duration(seconds: 20));
      Feedback? f;
      (s, f) = s.timeOut();
      expect(f, isA<TimedOut>().having((t) => t.strike, 'strike', 1));
      expect(s.mistakes, 1);
      expect(s.deadline, isNull);
      expect(s.state.trays!['ftr1'], ['fe1']);
      expect(s.timeOut().$2, isNull, reason: 'no timer runs until retry');
      s = s.retry();
      expect(s.secondsLeft, 20);
    }));

    test('a timeout and wrong checks share the 3 strikes', () => at(() {
      var s = start();
      (s, _) = pass(s);
      (s, _) = s.next();
      Feedback? f;
      (s, f) = s.timeOut();
      s = s.retry();
      (s, f) = fail(s);
      expect(f, isA<StepFailed>().having((x) => x.strike, 'strike', 2));
      expect(s.deadline, isNull, reason: 'a check stops the timer');
      s = s.retry();
      (s, f) = s.timeOut();
      expect(f, isA<TimedOut>().having((t) => t.canShowAnswer, 'mercy', true));
    }));

    test('a not-ready check leaves the timer running', () => at(() {
      var s = start();
      (s, _) = pass(s);
      (s, _) = s.next();
      final deadline = s.deadline;
      (s, _) = s.check();
      expect(s.deadline, deadline);
    }));

    test('passed, it never runs again; unpassed, going back and forth restarts it', () => at(() {
      var s = start();
      (s, _) = pass(s);
      (s, _) = s.next();
      s = s.update((st) => st.move('fe5', const TrayZone('ftr2')));
      now = now.add(const Duration(seconds: 12));
      s = s.goTo(0);
      expect(s.deadline, isNull);
      s = s.goTo(1);
      expect(s.secondsLeft, 20);
      expect(s.state.trays!['ftr2'], ['fe5'], reason: 'cards kept while away');
      (s, _) = pass(s);
      expect(s.deadline, isNull);
      s = s.goTo(0).goTo(1);
      expect(s.deadline, isNull);
      expect(s.state.locked, isTrue);
    }));
  });

  test('go on needs a passed step; reset gives fresh cards to an unpassed one only', () => at(() {
    var s = start();
    expect(s.next().$2, isNull);
    expect(s.next().$1.stepIndex, 0);
    s = s.update((st) => st.toggleOption('fc1').tapCard('fs1'));
    (s, _) = fail(s);
    s = s.resetStep();
    expect(s.state.selected, isEmpty);
    expect(s.state.slots, [null, null, null, null]);
    expect(s.mistakes, 1, reason: 'reset does not forgive');
    (s, _) = pass(s);
    expect(s.resetStep(), same(s));
  }));

  test('leaving is free only before any step is done or any mistake made', () => at(() {
    var s = start();
    expect(s.canLeaveFreely, isTrue);
    expect(fail(s).$1.canLeaveFreely, isFalse);
    (s, _) = pass(s);
    expect(s.canLeaveFreely, isFalse);
  }));
}
