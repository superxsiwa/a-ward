import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/sfx.dart';
import '../../app/theme.dart';
import '../../data/progress_store.dart';
import '../../data/providers.dart';
import '../../game/case_model.dart';
import '../../game/case_session.dart';
import '../../game/progress.dart';
import '../../game/step_board.dart';
import '../../game/rules.dart';
import '../../game/step_checker.dart';
import '../../l10n/generated/app_localizations.dart';
import 'monitor.dart';
import 'task_views.dart';

/// One bed played step by step. The rules live in [CaseSession]; this screen shows the session
/// and turns taps into session actions.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.bedNum});

  final int bedNum;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

/// The panel that replaces the bottom buttons after a check, a timeout or a shown answer.
class _Panel {
  const _Panel({required this.ok, required this.title, required this.sub, this.errors = const []});

  final bool ok;
  final String title;
  final String sub;
  final List<String> errors;
}

class _GameScreenState extends ConsumerState<GameScreen> {
  CaseSession? _session;
  _Panel? _panel;
  Timer? _ticker;
  final _scroll = ScrollController();
  final _viewport = GlobalKey();
  final _random = Random();
  Offset? _dragPoint;
  Timer? _autoScroll;

  @override
  void initState() {
    super.initState();
    ref.read(bundledCasesProvider.future).then((cases) {
      if (!mounted) return;
      final bed = cases.firstWhere((c) => c.bedNum == widget.bedNum, orElse: () => cases.first);
      _setSession(CaseSession.start(bed));
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _autoScroll?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  // Session and timer

  void _setSession(CaseSession next) {
    setState(() => _session = next);
    if (next.deadline == null) {
      _ticker?.cancel();
      _ticker = null;
    } else {
      _ticker ??= Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
    }
  }

  void _tick() {
    final s = _session;
    if (s == null || s.deadline == null) return;
    if ((s.secondsLeft ?? 1) <= 0) {
      _apply(s.timeOut());
    } else {
      setState(() {});
    }
  }

  void _apply((CaseSession, GameFeedback?) result) {
    final (next, feedback) = result;
    _setSession(next);
    if (feedback != null) _show(feedback, next);
  }

  void _show(GameFeedback f, CaseSession s) {
    final l = AppLocalizations.of(context);
    final sfx = ref.read(sfxProvider);
    switch (f) {
      case NotReady():
        sfx.play(Sound.pick);
      case StepPassed() || AnswerShown():
        sfx
          ..play(Sound.ok)
          ..buzz(Buzz.success);
      case StepFailed() || TimedOut():
        sfx
          ..play(Sound.bad)
          ..buzz(Buzz.error);
      case CaseFinished():
        break;
    }
    switch (f) {
      case NotReady(:final reason):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(l.notReady(_incompleteText(l, reason))),
              duration: const Duration(milliseconds: 2200),
              behavior: SnackBarBehavior.floating,
            ),
          );
      case StepPassed():
        final praise = [l.praise1, l.praise2, l.praise3, l.praise4][_random.nextInt(4)];
        setState(() => _panel = _Panel(ok: true, title: praise, sub: l.passedSub));
      case StepFailed(:final errors, :final strike, :final canShowAnswer):
        setState(
          () => _panel = _Panel(
            ok: false,
            title: canShowAnswer ? l.mercyTitle : l.failedTitle(strike),
            sub: canShowAnswer ? l.mercySub : l.failedSub,
            errors: [for (final e in errors) _errorText(l, e)],
          ),
        );
      case TimedOut(:final strike, :final canShowAnswer):
        setState(
          () => _panel = _Panel(
            ok: false,
            title: canShowAnswer ? l.timeoutMercyTitle : l.timeoutTitle(strike),
            sub: canShowAnswer ? l.timeoutMercySub : l.timeoutSub,
            errors: [l.errorTimeout],
          ),
        );
      case AnswerShown():
        setState(() => _panel = _Panel(ok: true, title: l.answerTitle, sub: l.answerSub));
      case CaseFinished(:final result):
        setState(() => _panel = null);
        _finish(s.bed, result);
    }
  }

  String _incompleteText(AppLocalizations l, Incomplete reason) => switch (reason) {
    NoOptionSelected() => l.notReadyOption,
    EmptySlots() => l.notReadySlots,
    CardsLeftInPool() => l.notReadyPool,
    TooFewInDropBox(:final needed) => l.notReadyDropBox(needed),
  };

  String _errorText(AppLocalizations l, StepError e) => switch (e) {
    WrongOptionSelected() => l.errorWrongOption,
    MissingOptions() => l.errorMissingOptions,
    WrongSequence() => l.errorSequence,
    WrongTray(:final tray, ordered: true) => l.errorTrayOrder(tray.displayName),
    WrongTray(:final tray) => l.errorTrayWrong(tray.displayName),
    UnsafeAction() => l.errorUnsafe,
  };

  // Actions

  /// A card or option move, with his sounds: "drop" when a card lands, "pick" when one is picked
  /// up or taken back.
  void _move(StepBoard Function(StepBoard b) move) {
    final s = _session!;
    final next = s.update(move);
    if (identical(next, s)) return;
    _setSession(next);
    final before = s.board;
    final after = next.board;
    final sfx = ref.read(sfxProvider);
    final picked = after.picked != before.picked || after.selected.length != before.selected.length;
    if (after.pool.length > before.pool.length || picked) {
      sfx.play(Sound.pick);
    } else {
      sfx
        ..play(Sound.drop)
        ..buzz(Buzz.tick);
    }
  }

  void _tap(VoidCallback action) {
    ref.read(sfxProvider).play(Sound.pick);
    action();
  }

  void _check() => _apply(_session!.check());

  void _showAnswer() {
    setState(() => _panel = null);
    _apply(_session!.showAnswer());
  }

  void _retry() {
    setState(() => _panel = null);
    _setSession(_session!.retry());
  }

  void _goOn() {
    setState(() => _panel = null);
    final (next, feedback) = _session!.next();
    _setSession(next);
    _scrollToTop();
    if (feedback != null) _show(feedback, next);
  }

  void _goTo(int index) {
    setState(() => _panel = null);
    _setSession(_session!.goTo(index));
    _scrollToTop();
  }

  void _scrollToTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _replay() => _setSession(CaseSession.start(_session!.bed));

  Future<void> _confirmLeave() async {
    final l = AppLocalizations.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.leaveTitle),
        content: Text(l.leaveBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.leaveCase),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      _ticker?.cancel();
      context.pop();
    }
  }

  /// Saves the result, then shows it with the stars gained, a level-up, and the next bed (his
  /// `finishCase` + win modal).
  Future<void> _finish(BedCase bed, CaseResult result) async {
    final l = AppLocalizations.of(context);
    final outcome = await ref.read(progressProvider.notifier).record(result);
    final sfx = ref.read(sfxProvider)
      ..play(Sound.win)
      ..buzz(Buzz.win);
    for (var i = 0; i < result.stars; i++) {
      Future.delayed(Duration(milliseconds: 450 + i * 320), () {
        if (mounted) sfx.play(Sound.values[Sound.star0.index + i]);
      });
    }
    final cases = ref.read(bundledCasesProvider).value ?? const <BedCase>[];
    final next = outcome.progress.nextBed([for (final c in cases) c.bedNum]);
    if (!mounted) return;
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ResultDialog(
        bed: bed,
        result: result,
        outcome: outcome,
        hasNext: next != null && next != bed.bedNum,
        l: l,
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'next':
        context.pushReplacement('/bed/$next');
      case 'replay':
        _replay();
        _scrollToTop();
      default:
        context.pop();
    }
  }

  // Auto scroll while a card is dragged near the top or bottom (his PointerDnD autoScroll).

  void _dragMoved(Offset p) {
    _dragPoint = p;
    _autoScroll ??= Timer.periodic(const Duration(milliseconds: 16), (_) => _scrollStep());
  }

  void _dragEnded() {
    _dragPoint = null;
    _autoScroll?.cancel();
    _autoScroll = null;
  }

  void _scrollStep() {
    final p = _dragPoint;
    final box = _viewport.currentContext?.findRenderObject() as RenderBox?;
    if (p == null || box == null || !_scroll.hasClients) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    final double dy = p.dy < top + 70
        ? -min(16.0, (top + 70 - p.dy) / 4)
        : p.dy > bottom - 70
        ? min(16.0, (p.dy - (bottom - 70)) / 4)
        : 0;
    if (dy == 0) return;
    final pos = _scroll.position;
    _scroll.jumpTo((pos.pixels + dy).clamp(pos.minScrollExtent, pos.maxScrollExtent));
  }

  // Layout

  @override
  Widget build(BuildContext context) {
    final s = _session;
    if (s == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: s.canLeaveFreely || s.finished,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => Navigator.maybePop(context)),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.bed.bedCode),
              Text(
                s.bed.caseTitle,
                style: const TextStyle(fontFamily: bodyFont, fontSize: 13.5, color: AppColors.ink2),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            Semantics(
              label: l.liveStars(s.liveStars),
              child: Row(
                children: [
                  for (var n = 1; n <= 3; n++)
                    Icon(
                      Icons.star_rounded,
                      size: 26,
                      color: s.liveStars >= n ? AppColors.gold : AppColors.stepIdle,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: SingleChildScrollView(
          key: _viewport,
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Stepper(session: s, l: l),
                  const SizedBox(height: 14),
                  _StepHead(session: s, l: l),
                  const SizedBox(height: 14),
                  BedsideMonitor(bedCase: s.bed, vitals: s.stage.vitals),
                  const SizedBox(height: 12),
                  DoctorBubble(bedCase: s.bed, speech: s.stage.doctorSpeech),
                  const SizedBox(height: 14),
                  _Reading(text: s.stage.reading, l: l, key: ValueKey('reading-${s.stage.id}')),
                  const SizedBox(height: 14),
                  TaskView(
                    stage: s.stage,
                    board: s.board,
                    onMove: _move,
                    drag: DragHooks(
                      onStart: () {
                        ref.read(sfxProvider)
                          ..play(Sound.pick)
                          ..buzz(Buzz.tick);
                      },
                      onMove: _dragMoved,
                      onEnd: _dragEnded,
                    ),
                    enabled: !s.waitingForRetry,
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: _panel == null
              ? _Dock(
                  session: s,
                  l: l,
                  onBack: () => _tap(() => _goTo(s.stepIndex - 1)),
                  onCheck: _check,
                  onShowAnswer: _showAnswer,
                  onGoOn: () => _tap(_goOn),
                  onReset: () => _tap(() => _setSession(s.resetStep())),
                )
              : _FeedbackPanel(
                  panel: _panel!,
                  l: l,
                  canShowAnswer: s.canShowAnswer,
                  timed: isTimedStage(s.stage),
                  onGoOn: () => _tap(_goOn),
                  onRetry: () => _tap(_retry),
                  onShowAnswer: _showAnswer,
                ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.session, required this.l});

  final CaseSession session;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final stages = session.bed.stages;
    return Row(
      children: [
        for (final (i, stage) in stages.indexed) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i <= session.stepIndex ? AppColors.sky500 : AppColors.stepIdle,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          _StepDot(
            number: i + 1,
            done: session.done.contains(stage.id),
            now: i == session.stepIndex,
            label: l.stepDot(i + 1),
          ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.number,
    required this.done,
    required this.now,
    required this.label,
  });

  final int number;
  final bool done;
  final bool now;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (fill, edge, ink) = done
        ? (AppColors.success, AppColors.successEdge, Colors.white)
        : now
        ? (AppColors.sky500, AppColors.sky700, Colors.white)
        : (AppColors.stepIdle, AppColors.stepIdleEdge, AppColors.ink3);
    return Semantics(
      label: label,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 3))],
        ),
        child: done
            ? Icon(Icons.check_rounded, size: 18, color: ink)
            : Text(
                '$number',
                style: TextStyle(
                  fontFamily: displayFont,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: ink,
                ),
              ),
      ),
    );
  }
}

class _StepHead extends StatelessWidget {
  const _StepHead({required this.session, required this.l});

  final CaseSession session;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final seconds = session.secondsLeft;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          session.stage.name.replaceFirst(RegExp(r'^\d+\.\s*'), ''),
          style: const TextStyle(
            fontFamily: displayFont,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        Text(
          l.stepOf(session.stepIndex + 1, session.bed.stages.length),
          style: const TextStyle(fontSize: 13.5, color: AppColors.ink3),
        ),
        _Pill(
          text: '🎮 ${session.stage.mechanic}',
          fill: AppColors.mechFill,
          edge: AppColors.mechBorder,
          ink: AppColors.mechInk,
        ),
        if (seconds != null) _Countdown(seconds: seconds, l: l),
      ],
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.seconds, required this.l});

  final int seconds;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final (fill, edge, ink) = seconds <= 5
        ? (const Color(0xFFFEF2F2), const Color(0xFFFCA5A5), const Color(0xFFB91C1C))
        : seconds <= 10
        ? (const Color(0xFFFEFCE8), const Color(0xFFFDE047), const Color(0xFF854D0E))
        : (const Color(0xFFF0FDF4), const Color(0xFF86EFAC), const Color(0xFF166534));
    return _Pill(
      text: '⏱️ ${l.secondsShort(seconds)}',
      fill: fill,
      edge: edge,
      ink: ink,
      big: true,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.fill,
    required this.edge,
    required this.ink,
    this.big = false,
  });

  final String text;
  final Color fill;
  final Color edge;
  final Color ink;
  final bool big;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: big ? 12 : 10, vertical: 2),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: edge, width: big ? 1.5 : 1),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: big ? 14 : 11, fontWeight: FontWeight.w600, color: ink),
    ),
  );
}

/// The knowledge box, open by default.
class _Reading extends StatefulWidget {
  const _Reading({super.key, required this.text, required this.l});

  final String text;
  final AppLocalizations l;

  @override
  State<_Reading> createState() => _ReadingState();
}

class _ReadingState extends State<_Reading> {
  var _open = true;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.bubbleBorder, width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.readingHead,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.l.reading,
                      style: const TextStyle(
                        fontFamily: displayFont,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.readingInk,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more, color: AppColors.readingInk),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _open
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(13, 10, 13, 13),
                  child: Text(
                    widget.text,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.65,
                      color: AppColors.readingBody,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    ),
  );
}

/// The bottom buttons: back, then check / show answer / go on, then reset.
class _Dock extends StatelessWidget {
  const _Dock({
    required this.session,
    required this.l,
    required this.onBack,
    required this.onCheck,
    required this.onShowAnswer,
    required this.onGoOn,
    required this.onReset,
  });

  final CaseSession session;
  final AppLocalizations l;
  final VoidCallback onBack;
  final VoidCallback onCheck;
  final VoidCallback onShowAnswer;
  final VoidCallback onGoOn;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final Widget main;
    if (!s.isPassed) {
      // After 3 mistakes "try again" really retries: check stays, the answer is offered above it
      // (decision Q-A, 2026-10-28; his version replaced check with show answer).
      main = GameButton(
        label: l.check,
        icon: Icons.check_rounded,
        color: AppColors.sky500,
        edge: AppColors.sky700,
        onTap: onCheck,
      );
    } else if (!s.isLastStep) {
      main = GameButton(
        label: l.goOn,
        trailing: Icons.arrow_forward_rounded,
        color: AppColors.gold,
        edge: AppColors.goldEdge,
        onTap: onGoOn,
      );
    } else {
      // A Center here would take the whole screen height inside the bar's Row.
      main = Text(
        l.allStepsDone,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF16A34A),
          fontSize: 15.5,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (s.canShowAnswer) ...[
            GameButton(
              label: l.showAnswerGoOn,
              color: AppColors.gold,
              edge: AppColors.goldEdge,
              onTap: onShowAnswer,
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              if (!s.isFirstStep) ...[
                _GhostButton(icon: Icons.arrow_back_rounded, label: l.previous, onTap: onBack),
                const SizedBox(width: 8),
              ],
              Expanded(child: main),
              const SizedBox(width: 8),
              _GhostButton(
                icon: Icons.undo_rounded,
                tooltip: l.resetStep,
                onTap: s.isPassed ? null : onReset,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({
    required this.panel,
    required this.l,
    required this.canShowAnswer,
    required this.timed,
    required this.onGoOn,
    required this.onRetry,
    required this.onShowAnswer,
  });

  final _Panel panel;
  final AppLocalizations l;
  final bool canShowAnswer;
  final bool timed;
  final VoidCallback onGoOn;
  final VoidCallback onRetry;
  final VoidCallback onShowAnswer;

  @override
  Widget build(BuildContext context) {
    final accent = panel.ok ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: panel.ok ? const Color(0xFFF0FDF4) : const Color(0xFFFFF1F2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66022850),
            blurRadius: 34,
            offset: Offset(0, -14),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: accent,
                  child: Icon(
                    panel.ok ? Icons.check_rounded : Icons.close_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        panel.title,
                        style: const TextStyle(
                          fontFamily: displayFont,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      Text(panel.sub, style: const TextStyle(fontSize: 14, color: AppColors.ink2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (panel.errors.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final e in panel.errors)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '•  ',
                      style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                    ),
                    Expanded(child: Text(e, style: const TextStyle(fontSize: 15))),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          if (panel.ok)
            GameButton(
              label: l.goOn,
              color: AppColors.success,
              edge: AppColors.successEdge,
              onTap: onGoOn,
            )
          else if (canShowAnswer)
            Row(
              children: [
                Expanded(
                  child: _GhostButton(label: l.tryAgainShort, onTap: onRetry),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: GameButton(
                    label: l.showAnswerGoOn,
                    color: AppColors.gold,
                    edge: AppColors.goldEdge,
                    onTap: onShowAnswer,
                  ),
                ),
              ],
            )
          else
            GameButton(
              label: timed ? l.tryAgainTimed : l.tryAgain,
              color: AppColors.danger,
              edge: AppColors.dangerEdge,
              onTap: onRetry,
            ),
        ],
      ),
    );
  }
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.bed,
    required this.result,
    required this.outcome,
    required this.hasNext,
    required this.l,
  });

  final BedCase bed;
  final RecordOutcome outcome;
  final CaseResult result;
  final bool hasNext;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                l.caseDone,
                style: const TextStyle(
                  fontFamily: displayFont,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            bed.bedCode,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: displayFont,
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
          ),
          Text(
            bed.caseTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.ink2),
          ),
          const SizedBox(height: 10),
          Semantics(
            label: l.liveStars(result.stars),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var n = 1; n <= 3; n++)
                  Icon(
                    Icons.star_rounded,
                    size: 62,
                    color: result.stars >= n ? AppColors.gold : AppColors.stepIdle,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            result.stars == 3
                ? l.caseDonePerfect
                : outcome.gainedStars > 0
                ? l.caseDoneGained(outcome.gainedStars)
                : l.caseDoneReplay,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15.5),
          ),
          if (outcome.levelUp case final level?) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.bubbleBorder, width: 2),
              ),
              child: Text(
                l.levelUp(level, ranks[level - 1]),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.readingInk),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (hasNext) ...[
            GameButton(
              label: l.nextBed,
              color: AppColors.gold,
              edge: AppColors.goldEdge,
              onTap: () => Navigator.pop(context, 'next'),
            ),
            const SizedBox(height: 10),
          ],
          GameButton(
            label: l.backToWard,
            icon: Icons.bed_rounded,
            color: AppColors.sky500,
            edge: AppColors.sky700,
            onTap: () => Navigator.pop(context, 'ward'),
          ),
          const SizedBox(height: 10),
          _GhostButton(
            icon: Icons.undo_rounded,
            label: l.replayForStars,
            onTap: () => Navigator.pop(context, 'replay'),
          ),
        ],
      ),
    ),
  );
}

/// His chunky game button: solid colour with a darker bottom edge.
class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.color,
    required this.edge,
    required this.onTap,
    this.icon,
    this.trailing,
  });

  final String label;
  final Color color;
  final Color edge;
  final VoidCallback onTap;
  final IconData? icon;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 5))],
    ),
    child: Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, color: Colors.white), const SizedBox(width: 8)],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: displayFont,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailing, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({this.icon, this.label, this.tooltip, required this.onTap});

  final IconData? icon;
  final String? label;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final ink = enabled ? AppColors.ink2 : AppColors.ink3.withValues(alpha: 0.5);
    final button = Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.ghostBorder, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 48, minWidth: label == null ? 48 : 0),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) Icon(icon, color: ink, size: 20),
                if (icon != null && label != null) const SizedBox(width: 6),
                if (label != null)
                  Flexible(
                    child: Text(
                      label!,
                      style: TextStyle(
                        fontFamily: displayFont,
                        fontWeight: FontWeight.w600,
                        fontSize: 15.5,
                        color: ink,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
