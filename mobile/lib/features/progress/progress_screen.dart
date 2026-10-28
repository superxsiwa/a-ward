import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../app/top_bar.dart';
import '../../data/progress_store.dart';
import '../../data/providers.dart';
import '../../game/milestones.dart';
import '../../game/progress.dart';
import '../../game/roster.dart';
import '../../l10n/generated/app_localizations.dart';

/// His ProgressPage: the bed stars ring with level and rank, play time, cases and milestone
/// stars, then his 20 goals with their stars and bars.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final progress = ref.watch(wardProgressProvider);
    final roster = ref.watch(rosterProvider).value ?? Roster.empty;
    final beds = ref.watch(casesProvider).value?.length ?? 8;
    final c = MilestoneContext(progress: progress, shiftsCleared: roster.shiftsCleared);
    final mStars = milestoneStars(c);
    return Scaffold(
      appBar: const PlayerBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.progressTitle,
                  style: const TextStyle(
                    fontFamily: displayFont,
                    fontWeight: FontWeight.w600,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 10),
                _RingCard(progress: progress, beds: beds, milestoneStars: mStars, l: l),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      l.goalsTitle,
                      style: const TextStyle(
                        fontFamily: displayFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(l.goalsSub, style: const TextStyle(fontSize: 12.5, color: AppColors.ink3)),
                  ],
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, box) {
                    final perRow = box.maxWidth >= 760 ? 2 : 1;
                    final cards = [for (final g in milestones) _GoalCard(goal: g, c: c, l: l)];
                    return Column(
                      children: [
                        for (var i = 0; i < cards.length; i += perRow)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (var j = i; j < i + perRow; j++) ...[
                                    if (j > i) const SizedBox(width: 10),
                                    Expanded(child: j < cards.length ? cards[j] : const SizedBox()),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingCard extends StatelessWidget {
  const _RingCard({
    required this.progress,
    required this.beds,
    required this.milestoneStars,
    required this.l,
  });

  final Progress progress;
  final int beds;
  final int milestoneStars;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final max = beds * 3;
    final stars = progress.totalStars;
    final stats = progress.stats;
    final minutes = stats.totalPlaySeconds ~/ 60;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder, width: 2),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: CustomPaint(
              painter: _Ring(max > 0 ? min(1, stars / max) : 0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$stars',
                      style: const TextStyle(
                        fontFamily: displayFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 30,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.ringOf(max),
                      style: const TextStyle(fontSize: 12.5, color: AppColors.ink3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.levelRank(progress.level, progress.rank),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: displayFont,
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: AppColors.sky700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l.progressHint(progress.passedCount, beds, stars + milestoneStars),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: AppColors.ink2),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Stat(
                  label: l.statHours,
                  value: minutes < 60
                      ? l.minutesShort(minutes)
                      : l.hoursShort((stats.totalPlaySeconds / 3600).toStringAsFixed(1)),
                ),
                const SizedBox(width: 8),
                _Stat(label: l.statCases, value: l.timesCount(stats.totalCompletedCases)),
                const SizedBox(width: 8),
                _Stat(
                  label: l.statMilestones,
                  value: l.milestoneStarsOf(milestoneStars, milestones.length * 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// His `ring`: the bed stars won so far as a gold arc from the top.
class _Ring extends CustomPainter {
  const _Ring(this.fraction);

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2 + 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arc, 0, 2 * pi, false, paint..color = const Color(0xFFE5EEF6));
    if (fraction > 0) {
      canvas.drawArc(arc, -pi / 2, 2 * pi * fraction, false, paint..color = AppColors.gold);
    }
  }

  @override
  bool shouldRepaint(_Ring old) => old.fraction != fraction;
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: displayFont,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.sky700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.c, required this.l});

  final Milestone goal;
  final MilestoneContext c;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final stars = goal.starsFor(c);
    final done = stars == 3;
    final value = goal.value(c);
    final now = goal.id == 'hours'
        ? l.hoursValue(formatValue(value), c.stats.totalPlaySeconds ~/ 60)
        : '${formatValue(value)} ${goal.unit}';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        gradient: done
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFF0FDF4)],
              )
            : null,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: done ? const Color(0xFF86EFAC) : AppColors.cardBorder, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(goal.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(
                        fontFamily: displayFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(goal.desc, style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Semantics(
                label: l.liveStars(stars),
                excludeSemantics: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var n = 1; n <= 3; n++)
                      Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: stars >= n ? AppColors.gold : AppColors.stepIdle,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: 8),
          _Bar(fraction: goal.barFor(c), done: done),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 2,
            children: [
              Text.rich(
                TextSpan(
                  text: '${l.goalNow} ',
                  children: [
                    TextSpan(
                      text: now,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
              ),
              Text(
                done
                    ? l.goalMax
                    : l.goalNext(stars + 1, '${formatValue(goal.tiers[stars])} ${goal.unit}'),
                style: TextStyle(
                  fontSize: 12.5,
                  color: done ? const Color(0xFF16A34A) : AppColors.ink3,
                  fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.done});

  final double fraction;
  final bool done;

  @override
  Widget build(BuildContext context) => Container(
    height: 9,
    decoration: BoxDecoration(
      color: const Color(0xFFE5EEF6),
      borderRadius: BorderRadius.circular(99),
    ),
    alignment: AlignmentDirectional.centerStart,
    child: FractionallySizedBox(
      widthFactor: fraction,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          gradient: LinearGradient(
            colors: done
                ? const [Color(0xFF4ADE80), Color(0xFF16A34A)]
                : const [AppColors.sky400, AppColors.gold],
          ),
        ),
      ),
    ),
  );
}
