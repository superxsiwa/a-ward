import 'dart:math';

import 'package:clock/clock.dart';

import 'case_model.dart';
import 'rules.dart';
import 'step_checker.dart';
import 'step_state.dart';

/// What the player is told after an action.
sealed class Feedback {
  const Feedback();
}

/// The step cannot be checked yet (a toast); nothing is counted.
class NotReady extends Feedback {
  const NotReady(this.reason);

  final Incomplete reason;
}

/// The step is right; the player goes on.
class StepPassed extends Feedback {
  const StepPassed();
}

/// The step is wrong. [strike] counts this step's mistakes; [canShowAnswer] once it reaches
/// [mercyStrikes].
class StepFailed extends Feedback {
  const StepFailed(this.errors, {required this.strike, required this.canShowAnswer});

  final List<StepError> errors;
  final int strike;
  final bool canShowAnswer;
}

/// The timed step ran out of time; counted like a wrong check.
class TimedOut extends Feedback {
  const TimedOut({required this.strike, required this.canShowAnswer});

  final int strike;
  final bool canShowAnswer;
}

/// The mercy rule laid out the answer; the player studies it and goes on.
class AnswerShown extends Feedback {
  const AnswerShown();
}

/// The last step is done.
class CaseFinished extends Feedback {
  const CaseFinished(this.result);

  final CaseResult result;
}

/// The outcome of a finished case, for progress and milestones.
class CaseResult {
  const CaseResult({
    required this.bedNum,
    required this.stars,
    required this.mistakes,
    required this.traysSorted,
    required this.flawlessSteps,
    required this.isEmergency,
  });

  final int bedNum;
  final int stars;
  final int mistakes;

  /// Cards placed in trays on steps passed by a check (not by the mercy rule).
  final int traysSorted;

  /// Steps passed by a check with no mistake on them.
  final int flawlessSteps;

  /// The case counts toward the emergency milestones: status alert or critical, or a step
  /// whose monitor alarms.
  final bool isEmergency;
}

/// One play of one bed: the current step, every step's cards, mistakes and the step timer.
///
/// Ported from the game state in superxsiwa's App.tsx (`openBed`, `loadStep`, `checkStep`,
/// `handleStepTimeout`, `handleMercySkip`, `handleNextStep`, `finishCase`). Immutable: every
/// action returns the next session, with the [Feedback] to show when there is one.
class CaseSession {
  const CaseSession._({
    required this.bed,
    required this.stepIndex,
    required this.states,
    required this.done,
    required this.mistakes,
    required this.stepMistakes,
    required this.deadline,
    required this.traysSorted,
    required this.flawlessSteps,
    required this.finished,
    required this._random,
  });

  /// A fresh play of [bed], on step 1. [random] shuffles the pools.
  factory CaseSession.start(BedCase bed, {Random? random}) {
    final r = random ?? Random();
    return CaseSession._(
      bed: bed,
      stepIndex: 0,
      states: {bed.stages.first.id: StepState.fresh(bed.stages.first, r)},
      done: const {},
      mistakes: 0,
      stepMistakes: const {},
      deadline: null,
      traysSorted: 0,
      flawlessSteps: 0,
      finished: false,
      random: r,
    );
  }

  final BedCase bed;
  final int stepIndex;

  /// The cards of every step visited so far, by step id.
  final Map<String, StepState> states;

  /// Ids of the steps passed, by a check or by the mercy rule.
  final Set<String> done;

  /// Mistakes on this play of the case; they decide the stars.
  final int mistakes;
  final Map<String, int> stepMistakes;

  /// When the timed step runs out; null while no timer runs.
  final DateTime? deadline;
  final int traysSorted;
  final int flawlessSteps;
  final bool finished;
  final Random _random;

  Stage get stage => bed.stages[stepIndex];
  StepState get state => states[stage.id]!;
  bool get isFirstStep => stepIndex == 0;
  bool get isLastStep => stepIndex == bed.stages.length - 1;
  bool get isPassed => done.contains(stage.id);
  int get liveStars => starsForMistakes(mistakes);
  int get strikes => stepMistakes[stage.id] ?? 0;

  /// The mercy rule: after [mercyStrikes] mistakes on an unpassed step.
  bool get canShowAnswer => !isPassed && strikes >= mercyStrikes;

  /// Leaving now loses nothing, so no confirmation is needed.
  bool get canLeaveFreely => done.isEmpty && mistakes == 0;

  /// Whole seconds left on the timed step (rounded up, as the countdown shows them), or null.
  int? get secondsLeft {
    final d = deadline;
    if (d == null) return null;
    final ms = d.difference(clock.now()).inMilliseconds;
    return ms <= 0 ? 0 : (ms + 999) ~/ 1000;
  }

  CaseSession _copy({
    int? stepIndex,
    Map<String, StepState>? states,
    Set<String>? done,
    int? mistakes,
    Map<String, int>? stepMistakes,
    DateTime? Function()? deadline,
    int? traysSorted,
    int? flawlessSteps,
    bool? finished,
  }) => CaseSession._(
    bed: bed,
    stepIndex: stepIndex ?? this.stepIndex,
    states: states ?? this.states,
    done: done ?? this.done,
    mistakes: mistakes ?? this.mistakes,
    stepMistakes: stepMistakes ?? this.stepMistakes,
    deadline: deadline == null ? this.deadline : deadline(),
    traysSorted: traysSorted ?? this.traysSorted,
    flawlessSteps: flawlessSteps ?? this.flawlessSteps,
    finished: finished ?? this.finished,
    random: _random,
  );

  CaseSession _withState(StepState s) => _copy(states: {...states, stage.id: s});

  DateTime? _timerFor(int index, Set<String> done) =>
      index == timedStepIndex && !done.contains(bed.stages[index].id)
      ? clock.now().add(const Duration(seconds: timedStepSeconds))
      : null;

  /// Applies a card or option move made on the current step.
  CaseSession update(StepState Function(StepState s) move) {
    if (finished || state.locked) return this;
    return _withState(move(state));
  }

  /// The check button (`checkStep`).
  (CaseSession, Feedback?) check() {
    if (finished || state.locked) return (this, null);
    final result = checkStep(stage, state);
    switch (result) {
      case CheckIncomplete(:final reason):
        // The timer keeps running.
        return (this, NotReady(reason));
      case CheckDone(passed: true):
        final trays = state.trays;
        final sorted = trays == null ? 0 : trays.values.fold(0, (n, t) => n + t.length);
        final next = _withState(state.lock())._copy(
          done: {...done, stage.id},
          deadline: () => null,
          traysSorted: traysSorted + sorted,
          flawlessSteps: flawlessSteps + (strikes == 0 ? 1 : 0),
        );
        return isLastStep ? next._finish() : (next, const StepPassed());
      case CheckDone(:final errors, :final wrongItems, :final wrongOptions):
        final strike = strikes + 1;
        final next = _withState(state.markWrong(wrongItems, wrongOptions))._copy(
          mistakes: mistakes + 1,
          stepMistakes: {...stepMistakes, stage.id: strike},
          deadline: () => null,
        );
        return (next, StepFailed(errors, strike: strike, canShowAnswer: strike >= mercyStrikes));
    }
  }

  /// The timed step's clock reached zero (`handleStepTimeout`). The cards stay where they are.
  (CaseSession, Feedback?) timeOut() {
    if (finished || deadline == null || state.locked) return (this, null);
    final strike = strikes + 1;
    final next = _copy(
      mistakes: mistakes + 1,
      stepMistakes: {...stepMistakes, stage.id: strike},
      deadline: () => null,
    );
    return (next, TimedOut(strike: strike, canShowAnswer: strike >= mercyStrikes));
  }

  /// "Try again" after a wrong check or a timeout: the timed step gets its full time back.
  CaseSession retry() {
    if (finished) return this;
    return _copy(deadline: () => _timerFor(stepIndex, done));
  }

  /// The mercy rule (`handleMercySkip`): lay out the answer and count the step as done.
  (CaseSession, Feedback?) showAnswer() {
    if (finished || !canShowAnswer) return (this, null);
    final next = _withState(state.solved(stage))._copy(
      done: {...done, stage.id},
      deadline: () => null,
    );
    return (next, const AnswerShown());
  }

  /// Opens step [index] (`loadStep`): its cards as they were left, or fresh ones. The timed step
  /// restarts its full time unless it is already passed.
  CaseSession goTo(int index) {
    if (finished || index < 0 || index >= bed.stages.length) return this;
    final target = bed.stages[index];
    return _copy(
      stepIndex: index,
      states: states.containsKey(target.id)
          ? states
          : {...states, target.id: StepState.fresh(target, _random)},
      deadline: () => _timerFor(index, done),
    );
  }

  /// "Go on" after a passed step or a shown answer (`handleNextStep`).
  (CaseSession, Feedback?) next() {
    if (finished || !isPassed) return (this, null);
    return isLastStep ? _finish() : (goTo(stepIndex + 1), null);
  }

  /// The reset button: fresh cards for an unpassed step. Mistakes stay counted.
  CaseSession resetStep() {
    if (finished || isPassed) return this;
    return _withState(StepState.fresh(stage, _random));
  }

  (CaseSession, Feedback) _finish() {
    final next = _copy(finished: true, deadline: () => null);
    return (
      next,
      CaseFinished(
        CaseResult(
          bedNum: bed.bedNum,
          stars: liveStars,
          mistakes: mistakes,
          traysSorted: traysSorted,
          flawlessSteps: flawlessSteps,
          isEmergency:
              bed.status != CaseStatus.stable || bed.stages.any((s) => isAlarmVitals(s.vitals)),
        ),
      ),
    );
  }
}
