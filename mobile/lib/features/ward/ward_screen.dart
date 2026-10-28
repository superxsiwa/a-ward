import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/progress_store.dart';
import '../../data/providers.dart';
import '../../game/case_model.dart';
import '../../game/progress.dart';
import '../../game/rules.dart';
import '../../l10n/generated/app_localizations.dart';
import '../about/about_screen.dart';
import '../game/monitor.dart';

/// The 8-bed CCU ward, after superxsiwa's WardPage: a banner with "start" / "continue", the bed
/// cards with their monitor, patient, status and stars, and the nurse station between bays.
class WardScreen extends ConsumerStatefulWidget {
  const WardScreen({super.key});

  @override
  ConsumerState<WardScreen> createState() => _WardScreenState();
}

class _WardScreenState extends ConsumerState<WardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _noticeOnce());
  }

  /// The "for training only" notice, once per device.
  Future<void> _noticeOnce() async {
    final store = ref.read(progressStoreProvider);
    if (await store.noticeSeen() || !mounted) return;
    final l = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: const TrainingNotice(),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.noticeOk))],
      ),
    );
    await store.markNoticeSeen();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cases = ref.watch(bundledCasesProvider);
    final progress = ref.watch(progressProvider).value ?? Progress.empty;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.appTitle),
            Text(
              l.levelRank(progress.level, progress.rank),
              style: const TextStyle(fontFamily: bodyFont, fontSize: 13.5, color: AppColors.ink2),
            ),
          ],
        ),
        actions: [
          _StarPill(stars: progress.totalStars, max: (cases.value?.length ?? 8) * 3, l: l),
          IconButton(
            tooltip: l.settingsTitle,
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: switch (cases) {
        AsyncData(:final value) => _Ward(cases: value, progress: progress, l: l),
        AsyncError() => Center(child: Text(l.casesLoadError)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Ward extends StatelessWidget {
  const _Ward({required this.cases, required this.progress, required this.l});

  final List<BedCase> cases;
  final Progress progress;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final next = progress.nextBed([for (final c in cases) c.bedNum]);
    void open(int bedNum) => context.push('/bed/$bedNum');
    final cards = [
      for (final c in cases)
        _BedCard(bedCase: c, record: progress.bed(c.bedNum), l: l, onTap: () => open(c.bedNum)),
    ];
    final station = _Station(cases: cases, progress: progress, l: l);
    return LayoutBuilder(
      builder: (context, box) {
        final perRow = box.maxWidth >= 700 ? 4 : 2;
        List<Widget> rows(List<Widget> items) => [
          for (var i = 0; i < items.length; i += perRow)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = i; j < i + perRow; j++) ...[
                      if (j > i) const SizedBox(width: 12),
                      Expanded(child: j < items.length ? items[j] : const SizedBox()),
                    ],
                  ],
                ),
              ),
            ),
        ];
        final half = cards.length ~/ 2;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Banner(
                    count: cases.length,
                    l: l,
                    label: progress.passedCount == 0 ? l.startNow : l.continuePlay,
                    onStart: next == null ? null : () => open(next),
                  ),
                  const SizedBox(height: 14),
                  ...rows(cards.sublist(0, half)),
                  station,
                  const SizedBox(height: 12),
                  ...rows(cards.sublist(half)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.count, required this.l, required this.label, this.onStart});

  final int count;
  final AppLocalizations l;
  final String label;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppColors.sky500, AppColors.sky700]),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
          ),
          child: const Text(
            'CCU',
            style: TextStyle(
              fontFamily: displayFont,
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.wardTitle(count),
                style: const TextStyle(
                  fontFamily: displayFont,
                  fontWeight: FontWeight.w600,
                  fontSize: 19,
                  color: Colors.white,
                ),
              ),
              Text(l.wardHint, style: const TextStyle(fontSize: 13.5, color: Colors.white)),
            ],
          ),
        ),
        if (onStart != null) ...[
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              textStyle: const TextStyle(fontFamily: displayFont, fontWeight: FontWeight.w600),
            ),
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(label),
          ),
        ],
      ],
    ),
  );
}

class _BedCard extends StatelessWidget {
  const _BedCard({
    required this.bedCase,
    required this.record,
    required this.l,
    required this.onTap,
  });

  final BedCase bedCase;
  final BedRecord record;
  final AppLocalizations l;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (statusFill, statusInk, edge) = record.passed
        ? (const Color(0xFFDCFCE7), const Color(0xFF15803D), const Color(0xFF86EFAC))
        : switch (bedCase.status) {
            CaseStatus.critical => (
              const Color(0xFFFEE2E2),
              const Color(0xFFB91C1C),
              const Color(0xFFFECACA),
            ),
            CaseStatus.alert => (
              const Color(0xFFFEF3C7),
              const Color(0xFFB45309),
              const Color(0xFFFDE68A),
            ),
            CaseStatus.stable => (
              const Color(0xFFDCFCE7),
              const Color(0xFF15803D),
              const Color(0xFFBBF7D0),
            ),
          };
    final vitals = bedCase.stages.first.vitals;
    return Semantics(
      button: true,
      label: '${bedCase.bedCode} ${bedCase.caseTitle}',
      excludeSemantics: true,
      child: Material(
        color: record.passed ? const Color(0xFFF4FDF7) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: edge, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.sky500,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        bedCase.bedNum.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          fontFamily: displayFont,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusFill,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          record.passed ? l.bedPassed : bedCase.statusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusInk,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _BedArt(bedCase: bedCase, vitals: vitals),
                const SizedBox(height: 8),
                Text(
                  bedCase.caseTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: displayFont,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
                if (bedCase.stayDuration != null)
                  Text(
                    bedCase.stayDuration!,
                    style: const TextStyle(fontSize: 11, color: AppColors.ink3),
                  ),
                const Spacer(),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (var n = 1; n <= 3; n++)
                      Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: record.stars >= n ? AppColors.gold : AppColors.stepIdle,
                      ),
                    const Spacer(),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: record.passed ? AppColors.success : AppColors.sky500,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        record.passed ? Icons.check_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The bed seen from the door: a small monitor with the first step's heart rate and trace, the
/// mattress and pillow, and the patient.
class _BedArt extends StatelessWidget {
  const _BedArt({required this.bedCase, required this.vitals});

  final BedCase bedCase;
  final Vitals vitals;

  @override
  Widget build(BuildContext context) {
    final alarm = isAlarmVitals(vitals);
    final patient = bedCase.patientName.startsWith('นาง') ? '👵' : '👴';
    return SizedBox(
      height: 78,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.sky50,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Positioned(
            right: 6,
            top: 6,
            width: 70,
            height: 36,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.monitorBottom,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: alarm ? AppColors.alarm : const Color(0xFF28526F),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    top: 10,
                    child: EcgTrace(
                      hr: vitals.hr,
                      color: alarm ? AppColors.ecgAlarm : AppColors.ecg,
                    ),
                  ),
                  Positioned(
                    left: 4,
                    top: 1,
                    child: Text(
                      '♥ ${vitals.hr}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: alarm ? AppColors.ecgAlarm : const Color(0xFF86EFAC),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 6,
            bottom: 6,
            right: 90,
            height: 30,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                  bottom: Radius.circular(9),
                ),
                border: Border.all(color: const Color(0xFFAED6EF), width: 2),
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 22,
            child: Container(
              width: 20,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.sky100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFB9DCF2), width: 1.5),
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 14,
            child: Text(patient, style: const TextStyle(fontSize: 26, height: 1)),
          ),
        ],
      ),
    );
  }
}

class _Station extends StatelessWidget {
  const _Station({required this.cases, required this.progress, required this.l});

  final List<BedCase> cases;
  final Progress progress;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.cardBorder, width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('👩‍⚕️', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.nurseStation,
                    style: const TextStyle(fontFamily: displayFont, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    l.passedOf(progress.passedCount, cases.length),
                    style: const TextStyle(fontSize: 13.5, color: AppColors.ink2),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final c in cases)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: progress.bed(c.bedNum).passed ? AppColors.success : AppColors.stepIdle,
                ),
              ),
          ],
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(onPressed: () => context.push('/sheets'), child: Text(l.caseSheets)),
        ),
      ],
    ),
  );
}

class _StarPill extends StatelessWidget {
  const _StarPill({required this.stars, required this.max, required this.l});

  final int stars;
  final int max;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) => Semantics(
    label: l.totalStars(stars, max),
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.bubbleBorder, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
          const SizedBox(width: 2),
          Text('$stars', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('/$max', style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
        ],
      ),
    ),
  );
}
