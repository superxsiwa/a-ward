import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/sfx.dart';
import '../../app/theme.dart';
import '../../app/top_bar.dart';
import '../../data/progress_store.dart';
import '../../data/providers.dart';
import '../../game/case_model.dart';
import '../../game/roster.dart';
import '../../l10n/generated/app_localizations.dart';

// His THAI_MONTHS and WEEKDAYS_LONG, and the calendar's weekday row (Thai only in v1).
const _months = [
  'มกราคม',
  'กุมภาพันธ์',
  'มีนาคม',
  'เมษายน',
  'พฤษภาคม',
  'มิถุนายน',
  'กรกฎาคม',
  'สิงหาคม',
  'กันยายน',
  'ตุลาคม',
  'พฤศจิกายน',
  'ธันวาคม',
];
const _weekdays = ['อาทิตย์', 'จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์'];
const _weekdaysShort = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];

/// The year as Thai calendars print it (Buddhist era).
int _thaiYear(int year) => year + 543;

/// The monthly shift calendar, after superxsiwa's RosterPage: the month's days with their shift,
/// the playable day in gold, and the chosen day's shifts with the beds each one looks after.
class RosterScreen extends ConsumerStatefulWidget {
  const RosterScreen({super.key});

  @override
  ConsumerState<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends ConsumerState<RosterScreen> {
  late RosterMonth _month = RosterMonth.of(clock.now());

  /// The day the player tapped; null follows the playable day.
  int? _picked;

  @override
  void initState() {
    super.initState();
    ref.read(rosterProvider.notifier).ensure(_month);
  }

  void _showMonth(RosterMonth month) {
    ref.read(sfxProvider).play(Sound.pick);
    setState(() {
      _month = month;
      _picked = null;
    });
    ref.read(rosterProvider.notifier).ensure(month);
  }

  void _pick(int day) {
    ref.read(sfxProvider).play(Sound.pick);
    setState(() => _picked = day);
  }

  void _locked(int playable) {
    final l = AppLocalizations.of(context);
    ref.read(sfxProvider)
      ..play(Sound.bad)
      ..buzz(Buzz.error);
    _toast(l.dayLocked(playable));
  }

  Future<void> _reroll() async {
    final l = AppLocalizations.of(context);
    ref.read(sfxProvider).play(Sound.pick);
    await ref.read(rosterProvider.notifier).reroll(_month);
    if (mounted) _toast(l.rerolled);
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(milliseconds: 2200),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Goes on duty for [day]'s [shift] (or, on a day off, just to the whole ward).
  void _toWard(int day, ShiftDef? shift) {
    ref.read(sfxProvider).play(Sound.pick);
    final duty = ref.read(dutyProvider.notifier);
    if (shift == null) {
      duty.end();
    } else {
      duty.start(Duty(_month, day, shift));
    }
    setState(() => _picked = null);
    context.go('/ward');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final roster = ref.watch(rosterProvider).value;
    final cases = ref.watch(bundledCasesProvider).value;
    return Scaffold(
      appBar: const PlayerBar(),
      body: roster == null || cases == null || !roster.has(_month)
          ? const Center(child: CircularProgressIndicator())
          : _body(l, roster, cases),
    );
  }

  Widget _body(AppLocalizations l, Roster roster, List<BedCase> cases) {
    final playable = roster.playableDay(_month);
    final picked = _picked;
    final day = picked != null && roster.stateOf(_month, picked) != DayState.locked
        ? picked
        : playable ?? _month.days;
    final now = clock.now();
    final calendar = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MonthBar(
          title: '${_months[_month.month - 1]} ${_thaiYear(_month.year)}',
          l: l,
          onPrevious: () => _showMonth(_month.previous),
          onNext: () => _showMonth(_month.next),
        ),
        const SizedBox(height: 8),
        _Calendar(
          month: _month,
          roster: roster,
          selected: day,
          today: _month.contains(now) ? now.day : null,
          l: l,
          onPick: _pick,
          onLocked: () => _locked(playable!),
        ),
      ],
    );
    final dayBox = _DayBox(
      month: _month,
      day: day,
      roster: roster,
      cases: cases,
      l: l,
      onWard: (shift) => _toWard(day, shift),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(l: l, onReroll: playable == null ? null : _reroll),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, box) => box.maxWidth >= 760
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: calendar),
                          const SizedBox(width: 12),
                          Expanded(child: dayBox),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [calendar, const SizedBox(height: 12), dayBox],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.l, required this.onReroll});

  final AppLocalizations l;
  final VoidCallback? onReroll;

  @override
  Widget build(BuildContext context) {
    final hint = l.rosterHint.split(l.rosterHintMark);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.sky500, AppColors.sky700]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      l.rosterBadge,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              if (onReroll != null)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  onPressed: onReroll,
                  child: Text(l.reroll),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.rosterTitle,
            style: const TextStyle(
              fontFamily: displayFont,
              fontWeight: FontWeight.w600,
              fontSize: 19,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                for (final (i, part) in hint.indexed) ...[
                  if (i > 0)
                    TextSpan(
                      text: l.rosterHintMark,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFFDE047)),
                    ),
                  TextSpan(text: part),
                ],
              ],
            ),
            style: const TextStyle(fontSize: 13.5, color: Colors.white, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.title,
    required this.l,
    required this.onPrevious,
    required this.onNext,
  });

  final String title;
  final AppLocalizations l;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.cardBorder, width: 2),
    ),
    child: Row(
      children: [
        IconButton(
          tooltip: l.prevMonth,
          icon: const Icon(Icons.chevron_left_rounded, color: AppColors.sky600),
          onPressed: onPrevious,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: displayFont,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        IconButton(
          tooltip: l.nextMonth,
          icon: const Icon(Icons.chevron_right_rounded, color: AppColors.sky600),
          onPressed: onNext,
        ),
      ],
    ),
  );
}

/// The shift pill's label and colours (his `cal-shift-pill` classes).
(String, Color, Color) _pill(Shift shift, AppLocalizations l) => switch (shift) {
  Shift.morning => (l.pillMorning, const Color(0xFFFEF3C7), const Color(0xFFB45309)),
  Shift.afternoon => (l.pillAfternoon, const Color(0xFFFFEDD5), const Color(0xFFC2410C)),
  Shift.night => (l.pillNight, const Color(0xFFEDE9FE), const Color(0xFF6D28D9)),
  Shift.off => (l.pillOff, const Color(0xFFE2E8F0), const Color(0xFF64748B)),
};

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.month,
    required this.roster,
    required this.selected,
    required this.today,
    required this.l,
    required this.onPick,
    required this.onLocked,
  });

  final RosterMonth month;
  final Roster roster;
  final int selected;
  final int? today;
  final AppLocalizations l;
  final ValueChanged<int> onPick;
  final VoidCallback onLocked;

  @override
  Widget build(BuildContext context) {
    final lead = month.firstWeekday;
    final cells = [for (var i = 0; i < lead; i++) null, for (var d = 1; d <= month.days; d++) d];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final (i, name) in _weekdaysShort.indexed)
                Expanded(
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: i == 0
                          ? const Color(0xFFEF4444)
                          : i == 6
                          ? AppColors.sky600
                          : AppColors.ink3,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var w = 0; w < cells.length; w += 7)
            Row(
              children: [
                for (final d in cells.sublist(w, w + 7))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: d == null
                          ? const SizedBox()
                          : _DayCell(
                              day: d,
                              shift: roster.shiftOn(month, d),
                              state: roster.stateOf(month, d),
                              selected: d == selected,
                              today: d == today,
                              sunday: (lead + d - 1) % 7 == 0,
                              l: l,
                              onTap: () => roster.stateOf(month, d) == DayState.locked
                                  ? onLocked()
                                  : onPick(d),
                            ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// One day: its number and shift pill. The playable day glows gold and gently pulses (FR-03);
/// a locked day shakes when tapped.
class _DayCell extends StatefulWidget {
  const _DayCell({
    required this.day,
    required this.shift,
    required this.state,
    required this.selected,
    required this.today,
    required this.sunday,
    required this.l,
    required this.onTap,
  });

  final int day;
  final Shift shift;
  final DayState state;
  final bool selected;
  final bool today;
  final bool sunday;
  final AppLocalizations l;
  final VoidCallback onTap;

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> with TickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 1));
  late final _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

  bool get _playable => widget.state == DayState.playable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(_DayCell old) {
    super.didUpdateWidget(old);
    _syncPulse();
  }

  void _syncPulse() {
    if (_playable && !MediaQuery.disableAnimationsOf(context)) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _tap() {
    if (widget.state == DayState.locked && !MediaQuery.disableAnimationsOf(context)) {
      _shake.forward(from: 0);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    final done = widget.state == DayState.done;
    final playable = _playable;
    // His cascade: done, then playable, then selected, then today decide the fill and edge.
    final (fill, edge) = done
        ? (const Color(0xFFF0FDF4), const Color(0xFFBBF7D0))
        : playable
        ? (const Color(0xFFFFFBEB), AppColors.gold)
        : widget.selected
        ? (AppColors.sky100, AppColors.sky600)
        : widget.today
        ? (AppColors.sky50, AppColors.sky400)
        : (const Color(0xFFF8FAFC), Colors.transparent);
    final ring = widget.selected && !playable;
    final number = widget.sunday
        ? const Color(0xFFEF4444)
        : widget.today
        ? AppColors.sky600
        : done
        ? const Color(0xFF15803D)
        : playable
        ? AppColors.goldEdge
        : AppColors.ink;
    final (pillText, pillFill, pillInk) = _pill(widget.shift, l);
    final stateText = switch (widget.state) {
      DayState.done => l.dayDone,
      DayState.playable => l.dayPlayable,
      DayState.locked => l.dayNotYet,
    };
    final cell = Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ring ? AppColors.sky600 : edge,
          width: ring ? 2.5 : (playable ? 2 : 1.5),
        ),
        boxShadow: playable
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${widget.day}',
                style: TextStyle(
                  fontFamily: displayFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.2,
                  color: number,
                ),
              ),
              // Icons, not the ▶ and ✓ characters: the phone draws ▶ as an emoji.
              if (playable)
                const Icon(Icons.play_arrow_rounded, size: 14, color: Color(0xFFD97706))
              else if (done)
                const Icon(Icons.check_rounded, size: 14, color: Color(0xFF16A34A)),
            ],
          ),
          const SizedBox(height: 3),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            decoration: BoxDecoration(color: pillFill, borderRadius: BorderRadius.circular(6)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                pillText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: pillInk,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      selected: widget.selected,
      label: '${widget.day} $pillText $stateText',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulse, _shake]),
        builder: (context, child) {
          final t = _shake.value;
          return Transform.translate(
            offset: Offset(sin(t * pi * 4) * 6 * (1 - t), 0),
            child: Transform.scale(
              scale: 1 + 0.03 * Curves.easeInOut.transform(_pulse.value),
              child: child,
            ),
          );
        },
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(borderRadius: BorderRadius.circular(12), onTap: _tap, child: cell),
        ),
      ),
    );
  }
}

/// The chosen day: its date and shift, then his three shift cards with their beds and, on the
/// player's own shift, the way into the ward.
class _DayBox extends StatelessWidget {
  const _DayBox({
    required this.month,
    required this.day,
    required this.roster,
    required this.cases,
    required this.l,
    required this.onWard,
  });

  final RosterMonth month;
  final int day;
  final Roster roster;
  final List<BedCase> cases;
  final AppLocalizations l;
  final ValueChanged<ShiftDef?> onWard;

  @override
  Widget build(BuildContext context) {
    final shift = roster.shiftOn(month, day);
    final mine = shiftDef(shift);
    final state = roster.stateOf(month, day);
    final weekday = _weekdays[(month.firstWeekday + day - 1) % 7];
    final bedNums = [for (final c in cases) c.bedNum];
    final shiftName = mine == null ? '☕ ${l.offName}' : '${mine.icon} ${mine.name}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.dayTitle(weekday, day, _months[month.month - 1], _thaiYear(month.year)),
            style: const TextStyle(
              fontFamily: displayFont,
              fontWeight: FontWeight.w600,
              fontSize: 16.5,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l.myShiftToday(shiftName),
                style: const TextStyle(fontSize: 14, color: AppColors.ink2),
              ),
              if (state == DayState.done) _Badge(text: l.shiftPassed),
            ],
          ),
          const Divider(height: 22, thickness: 1.5, color: Color(0xFFE2E8F0)),
          if (mine == null) ...[
            _OffCard(l: l, onWard: () => onWard(null)),
            const SizedBox(height: 10),
          ],
          // The player's own shift first (his page keeps the fixed order, which puts the night
          // shift's button far below the calendar on a phone).
          for (final def in [?mine, ...shiftDefs.where((d) => d != mine)]) ...[
            _ShiftCard(
              def: def,
              mine: def == mine,
              state: state,
              cases: [for (final n in def.bedsIn(bedNums)) cases.firstWhere((c) => c.bedNum == n)],
              done: state == DayState.done
                  ? def.bedsIn(bedNums).toSet()
                  : roster.doneOn(month, day),
              l: l,
              onWard: () => onWard(def),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFDCFCE7),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
    ),
  );
}

class _OffCard extends StatelessWidget {
  const _OffCard({required this.l, required this.onWard});

  final AppLocalizations l;
  final VoidCallback onWard;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.cardBorder, width: 2),
    ),
    child: Column(
      children: [
        const Text('☕🌴', style: TextStyle(fontSize: 36)),
        const SizedBox(height: 6),
        Text(
          l.offTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: displayFont,
            fontWeight: FontWeight.w600,
            fontSize: 15.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.offHint,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13.5, color: AppColors.ink2),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onWard,
          icon: const Icon(Icons.bed_rounded),
          label: Text(l.seeWholeWard),
        ),
      ],
    ),
  );
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({
    required this.def,
    required this.mine,
    required this.state,
    required this.cases,
    required this.done,
    required this.l,
    required this.onWard,
  });

  final ShiftDef def;
  final bool mine;
  final DayState state;
  final List<BedCase> cases;

  /// The player's beds finished on this day (only shown on the player's shift).
  final Set<int> done;
  final AppLocalizations l;
  final VoidCallback onWard;

  @override
  Widget build(BuildContext context) {
    final count = cases.where((c) => done.contains(c.bedNum)).length;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mine ? AppColors.sky50 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: mine ? AppColors.sky400 : AppColors.cardBorder,
          width: mine ? 2.5 : 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(def.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      def.name,
                      style: const TextStyle(
                        fontFamily: displayFont,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (mine) _Badge(text: l.yourShift),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.sky100,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  def.time,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.sky700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            mine
                ? l.shiftMetaDone(def.chargeNurse, count, cases.length)
                : l.shiftMeta(def.chargeNurse, cases.length),
            style: const TextStyle(fontSize: 13, color: AppColors.ink2),
          ),
          const SizedBox(height: 8),
          for (final c in cases) ...[
            _AssignedBed(bedCase: c, done: mine && done.contains(c.bedNum), l: l),
            const SizedBox(height: 6),
          ],
          if (mine && state != DayState.locked) ...[
            const SizedBox(height: 4),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                textStyle: const TextStyle(fontFamily: displayFont, fontWeight: FontWeight.w600),
              ),
              onPressed: onWard,
              icon: const Icon(Icons.bed_rounded),
              label: Text(state == DayState.done ? l.reviewShift : l.enterShift),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssignedBed extends StatelessWidget {
  const _AssignedBed({required this.bedCase, required this.done, required this.l});

  final BedCase bedCase;
  final bool done;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: done ? const Color(0xFFF0FDF4) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: done ? const Color(0xFFBBF7D0) : AppColors.optionBorder,
        width: 1.5,
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: done ? AppColors.success : AppColors.sky500,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            l.bedNo(bedCase.bedNum.toString().padLeft(2, '0')),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bedCase.caseTitle,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, height: 1.3),
              ),
              Text(
                [bedCase.patientName, ?bedCase.stayDuration].join(' · '),
                style: const TextStyle(fontSize: 12, color: AppColors.ink3),
              ),
            ],
          ),
        ),
        if (done) ...[
          const SizedBox(width: 6),
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
        ],
      ],
    ),
  );
}
