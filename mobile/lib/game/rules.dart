/// The scoring and timing rules, ported from superxsiwa's frontend/src/App.tsx.
library;

import 'case_model.dart';

/// Every case is played in 6 steps.
const stepsPerCase = 6;

/// Stars for a finished case: no mistakes 3, one or two 2, more 1 (`liveStars`).
int starsForMistakes(int mistakes) => switch (mistakes) {
  0 => 3,
  1 || 2 => 2,
  _ => 1,
};

/// The star that goes dark when the case's mistake count reaches [mistakes]: the 1st mistake
/// costs star 3, the 3rd costs star 2 (`setLostStarAnim`). Null when no star is lost.
int? starLostAt(int mistakes) => switch (mistakes) {
  1 => 3,
  3 => 2,
  _ => null,
};

/// After this many mistakes on one step the player may see the answer and go on (mercy rule).
const mercyStrikes = 3;

/// The timed step: the equipment step, an unordered trays task. His code timed the step at
/// position 2 (App.tsx:458), which is that step in all 8 cases; following the task instead keeps
/// the timer right when cases are edited (decision Q-B, 2026-10-28, his commit 70f3c85 describes
/// it as the "step 2 equipment task").
bool isTimedStage(Stage stage) => stage.trays != null && !stage.trays!.ordered;

/// Seconds allowed on the timed step, restarted on every retry.
const timedStepSeconds = 20;

/// The bedside monitor alarms on these vitals (`isAlarmVitals` in WardPage.tsx).
bool isAlarmVitals(Vitals v) {
  final spo2 = _leadingInt(v.spo2);
  return v.hr >= 120 || v.hr < 50 || (spo2 != null && spo2 <= 90) || v.map < 65;
}

/// JavaScript `parseInt`: the leading digits, so `99%` reads as 99; null where it gives NaN.
int? _leadingInt(String s) {
  final m = RegExp(r'^\s*(\d+)').firstMatch(s);
  return m == null ? null : int.parse(m[1]!);
}
