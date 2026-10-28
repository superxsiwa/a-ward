import 'package:criticalcare/game/case_session.dart';
import 'package:criticalcare/game/milestones.dart';
import 'package:criticalcare/game/progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MilestoneContext ctx({
    PlayerStats stats = const PlayerStats(),
    Map<int, BedRecord> beds = const {},
    int shifts = 0,
  }) => MilestoneContext(
    progress: Progress(beds: beds, stats: stats),
    shiftsCleared: shifts,
  );

  Milestone goal(String id) => milestones.firstWhere((g) => g.id == id);

  test('his 20 goals, each with three rising tiers', () {
    expect(milestones, hasLength(20));
    expect(milestones.map((g) => g.id).toSet(), hasLength(20));
    for (final g in milestones) {
      expect(g.tiers, hasLength(3), reason: g.id);
      expect(g.tiers[0] < g.tiers[1] && g.tiers[1] < g.tiers[2], isTrue, reason: g.id);
    }
  });

  test('stars come from the tiers (getMilestoneStars)', () {
    final cases = goal('cases');
    expect(cases.starsFor(ctx(stats: const PlayerStats(totalCompletedCases: 4))), 0);
    expect(cases.starsFor(ctx(stats: const PlayerStats(totalCompletedCases: 5))), 1);
    expect(cases.starsFor(ctx(stats: const PlayerStats(totalCompletedCases: 15))), 2);
    expect(cases.starsFor(ctx(stats: const PlayerStats(totalCompletedCases: 99))), 3);
  });

  test('the bar runs from the last tier reached to the next', () {
    final cases = goal('cases');
    expect(cases.barFor(ctx(stats: const PlayerStats(totalCompletedCases: 10))), 0.5);
    expect(cases.barFor(ctx(stats: const PlayerStats(totalCompletedCases: 0))), 0);
    expect(cases.barFor(ctx(stats: const PlayerStats(totalCompletedCases: 30))), 1);
  });

  test('play hours round to one decimal, like toFixed(1)', () {
    expect(playHours(const PlayerStats(totalPlaySeconds: 1790)), 0.5);
    expect(playHours(const PlayerStats(totalPlaySeconds: 1700)), 0.5);
    expect(playHours(const PlayerStats(totalPlaySeconds: 1600)), 0.4);
    expect(goal('hours').starsFor(ctx(stats: const PlayerStats(totalPlaySeconds: 5400))), 2);
  });

  test('numbers print the way his page prints them', () {
    expect(formatValue(3.0), '3');
    expect(formatValue(1.5), '1.5');
    expect(formatValue(12), '12');
  });

  test('each bed goal follows that bed\'s best stars', () {
    final c = ctx(beds: const {4: BedRecord(passed: true, stars: 2)});
    expect(goal('case_tpm').starsFor(c), 2);
    expect(goal('case_sheath').starsFor(c), 0);
  });

  test('shifts count the roster days worked', () {
    expect(goal('shifts').starsFor(ctx(shifts: 7)), 2);
  });

  test('patient safety is capped by the cases done', () {
    final s = goal('safety_champion');
    expect(
      s.value(ctx(stats: const PlayerStats(totalCompletedCases: 3, stepsWithoutMistake: 40))),
      3,
    );
    expect(
      s.value(ctx(stats: const PlayerStats(totalCompletedCases: 30, stepsWithoutMistake: 40))),
      10,
    );
  });

  test('the legend counts the other goals with at least one star', () {
    final c = ctx(
      stats: const PlayerStats(totalCompletedCases: 5, perfectCases: 3, trayItemsSorted: 15),
      beds: const {1: BedRecord(passed: true, stars: 3), 2: BedRecord(passed: true, stars: 1)},
      shifts: 2,
    );
    // cases, perfect, shifts, beds_unlocked, case_sheath, case_cvc, tray_master.
    expect(goal('ccu_legend').value(c), 7);
    expect(goal('ccu_legend').starsFor(c), 1);
    expect(milestoneStars(c), greaterThan(7));
  });

  test('play time survives saving and a finished case', () {
    final p = Progress.empty.played(25);
    expect(Progress.fromJson(p.toJson()).stats.totalPlaySeconds, 25);
    const done = CaseResult(
      bedNum: 1,
      stars: 3,
      mistakes: 0,
      traysSorted: 0,
      flawlessSteps: 6,
      isEmergency: false,
    );
    expect(p.record(done).progress.stats.totalPlaySeconds, 25);
  });
}
