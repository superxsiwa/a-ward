import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/case_repository.dart';
import '../../game/case_model.dart';
import '../../game/step_board.dart';
import '../../l10n/generated/app_localizations.dart';

/// Applies one move to the current step's cards.
typedef StepMove = void Function(StepBoard Function(StepBoard s) move);

/// Drag callbacks, so the page can scroll while a card is held near its edge.
class DragHooks {
  const DragHooks({required this.onMove, required this.onEnd});

  final void Function(Offset globalPosition) onMove;
  final VoidCallback onEnd;
}

/// Every task of [stage], in his order: choices, sequence, trays, drop box.
class TaskView extends StatelessWidget {
  const TaskView({
    super.key,
    required this.stage,
    required this.board,
    required this.onMove,
    required this.drag,
    this.enabled = true,
  });

  final Stage stage;
  final StepBoard board;
  final StepMove onMove;
  final DragHooks drag;

  /// False while a timeout waits for "try again": the cards stay put.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ctx = _TaskContext(board: board, onMove: onMove, drag: drag, enabled: enabled);
    final choices = stage.choices;
    final sequence = stage.sequence;
    final trays = stage.trays;
    final drop = stage.unorderedDrop;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (choices != null) _TaskCard(prompt: choices.prompt, children: [_Choices(choices, ctx)]),
        if (sequence != null && board.slots != null)
          _TaskCard(
            prompt: sequence.prompt,
            children: [
              _Pool(ctx, hint: l.hintSequence),
              _Slots(ctx),
            ],
          ),
        if (trays != null && board.trays != null)
          _TaskCard(
            prompt: trays.prompt.replaceAll('**', ''),
            children: [
              _Pool(ctx, hint: l.hintTrays),
              for (final t in trays.trays) _TrayBox(ctx, tray: t, ordered: trays.ordered),
            ],
          ),
        if (drop != null && board.dropBox != null)
          _TaskCard(
            prompt: drop.prompt,
            children: [
              _Pool(ctx, hint: l.hintDropBox),
              _DropBox(ctx, needed: drop.expectedIds.length),
            ],
          ),
      ],
    );
  }
}

class _TaskContext {
  const _TaskContext({
    required this.board,
    required this.onMove,
    required this.drag,
    required this.enabled,
  });

  final StepBoard board;
  final StepMove onMove;
  final DragHooks drag;
  final bool enabled;

  /// Nothing can move: the step is passed, or a timeout waits for "try again".
  bool get frozen => board.locked || !enabled;

  void tapCard(String id) => onMove((s) => s.tapCard(id));
  void tapZone(Zone zone) => onMove((s) => s.tapZone(zone));
  void drop(String id, Zone zone) => onMove((s) => s.move(id, zone));
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.prompt, required this.children});

  final String prompt;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: const Border(
        left: BorderSide(color: AppColors.cardBorder, width: 2),
        top: BorderSide(color: AppColors.cardBorder, width: 2),
        right: BorderSide(color: AppColors.cardBorder, width: 2),
        bottom: BorderSide(color: AppColors.cardBorder, width: 5),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          prompt,
          style: const TextStyle(
            fontFamily: displayFont,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        for (final c in children) ...[const SizedBox(height: 10), c],
      ],
    ),
  );
}

class _Choices extends StatelessWidget {
  const _Choices(this.task, this.ctx);

  final ChoicesTask task;
  final _TaskContext ctx;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final o in task.options)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _OptionRow(
            option: o,
            on: ctx.board.selected.contains(o.id),
            wrong: ctx.board.wrongOptions.contains(o.id),
            onTap: () => ctx.onMove((s) => s.toggleOption(o.id)),
          ),
        ),
    ],
  );
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.on,
    required this.wrong,
    required this.onTap,
  });

  final ChoiceOption option;
  final bool on;
  final bool wrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = wrong ? AppColors.wrongFill : (on ? AppColors.sky100 : Colors.white);
    final edge = wrong ? AppColors.wrongBorder : (on ? AppColors.sky400 : AppColors.optionBorder);
    final box = wrong ? AppColors.danger : (on ? AppColors.sky500 : Colors.white);
    return Semantics(
      checked: on,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: edge, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: box,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: on || wrong ? box : const Color(0xFFB4CADE),
                      width: 2.5,
                    ),
                  ),
                  child: on ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option.text,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A drop zone: receives dragged cards and, while a card is picked up, taps.
class _Zone extends StatelessWidget {
  const _Zone({required this.ctx, required this.zone, required this.builder});

  final _TaskContext ctx;
  final Zone zone;
  final Widget Function(bool hover) builder;

  @override
  Widget build(BuildContext context) => DragTarget<String>(
    onWillAcceptWithDetails: (_) => !ctx.frozen,
    onAcceptWithDetails: (d) => ctx.drop(d.data, zone),
    builder: (context, candidates, _) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ctx.tapZone(zone),
      child: builder(candidates.isNotEmpty),
    ),
  );
}

class _Pool extends StatelessWidget {
  const _Pool(this.ctx, {required this.hint});

  final _TaskContext ctx;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pool = ctx.board.pool;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Zone(
          ctx: ctx,
          zone: const PoolZone(),
          builder: (hover) => Container(
            constraints: const BoxConstraints(minHeight: 66),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hover ? AppColors.sky100 : const Color(0xFFF4FBFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: hover ? AppColors.sky500 : AppColors.poolBorder, width: 2),
            ),
            child: pool.isEmpty
                ? Center(
                    child: Text(
                      l.poolEmpty,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.ink3),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final id in pool) _CardChip(ctx, id: id)],
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(hint, style: const TextStyle(fontSize: 11.5, height: 1.5, color: AppColors.ink3)),
      ],
    );
  }
}

class _Slots extends StatelessWidget {
  const _Slots(this.ctx);

  final _TaskContext ctx;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final slots = ctx.board.slots!;
    return Column(
      children: [
        for (final (i, id) in slots.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _Zone(
              ctx: ctx,
              zone: SlotZone(i),
              builder: (hover) => Container(
                constraints: const BoxConstraints(minHeight: 58),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: hover
                      ? AppColors.sky100
                      : (id == null ? AppColors.slotFill : Colors.white),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: hover
                        ? AppColors.sky500
                        : (id == null ? AppColors.slotBorder : const Color(0xFFD3EAFA)),
                    width: 2.5,
                  ),
                ),
                child: Row(
                  children: [
                    _NumberBadge(i + 1, color: AppColors.sky500, edge: AppColors.sky700, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: id == null
                          ? Text(
                              l.slotPlaceholder,
                              style: const TextStyle(fontSize: 12, color: AppColors.ink3),
                            )
                          : _CardChip(ctx, id: id, expand: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TrayBox extends StatelessWidget {
  const _TrayBox(this.ctx, {required this.tray, required this.ordered});

  final _TaskContext ctx;
  final Tray tray;
  final bool ordered;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cards = ctx.board.trays![tray.id] ?? const <String>[];
    final fill = tray.sterile ? AppColors.sterileFill : AppColors.trayFill;
    final edge = tray.sterile ? AppColors.sterileEdge : AppColors.trayEdge;
    final ink = tray.sterile ? AppColors.sterileInk : AppColors.trayInk;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: _Zone(
        ctx: ctx,
        zone: TrayZone(tray.id),
        builder: (hover) => Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: hover ? Colors.white : fill,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: hover ? AppColors.sky500 : edge, width: 3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Colors.white.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  children: [
                    Text(tray.sterile ? '✨' : '🧰'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tray.displayName,
                        style: TextStyle(
                          fontFamily: displayFont,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: ink,
                        ),
                      ),
                    ),
                    _CountPill('${cards.length}', color: edge),
                  ],
                ),
              ),
              Container(
                constraints: const BoxConstraints(minHeight: 110),
                padding: const EdgeInsets.all(10),
                child: cards.isEmpty
                    ? Center(
                        child: Text(l.trayPlaceholder, style: TextStyle(fontSize: 12, color: ink)),
                      )
                    : Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final (i, id) in cards.indexed)
                            // Dropping on a card puts the dragged card in front of it.
                            DragTarget<String>(
                              onWillAcceptWithDetails: (d) => !ctx.frozen && d.data != id,
                              onAcceptWithDetails: (d) =>
                                  ctx.drop(d.data, TrayZone(tray.id, before: id)),
                              builder: (context, candidates, _) => _InsertMark(
                                show: candidates.isNotEmpty,
                                child: _CardChip(ctx, id: id, number: ordered ? i + 1 : null),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropBox extends StatelessWidget {
  const _DropBox(this.ctx, {required this.needed});

  final _TaskContext ctx;
  final int needed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cards = ctx.board.dropBox!;
    return _Zone(
      ctx: ctx,
      zone: const DropBoxZone(),
      builder: (hover) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: hover ? Colors.white : AppColors.sterileFill,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: hover ? AppColors.sky500 : AppColors.sterileEdge, width: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: Colors.white.withValues(alpha: 0.6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  const Text('📋'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.dropBoxTitle,
                      style: const TextStyle(
                        fontFamily: displayFont,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.sterileInk,
                      ),
                    ),
                  ),
                  _CountPill('${cards.length}/$needed', color: AppColors.sterileEdge),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(minHeight: 110),
              padding: const EdgeInsets.all(10),
              child: cards.isEmpty
                  ? Center(
                      child: Text(
                        l.dropBoxPlaceholder,
                        style: const TextStyle(fontSize: 12, color: AppColors.sterileInk),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final id in cards)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _CardChip(ctx, id: id, expand: true),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card: tap to place or take back, press and hold to drag.
class _CardChip extends StatelessWidget {
  const _CardChip(this.ctx, {required this.id, this.number, this.expand = false});

  final _TaskContext ctx;
  final String id;
  final int? number;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final item = ctx.board.items[id];
    if (item == null) return const SizedBox.shrink();
    final face = _CardFace(
      item: item,
      picked: ctx.board.picked == id,
      wrong: ctx.board.wrongItems.contains(id),
      number: number,
      expand: expand,
    );
    if (ctx.frozen) return face;
    return LongPressDraggable<String>(
      data: id,
      delay: const Duration(milliseconds: 150),
      hapticFeedbackOnStart: false,
      onDragUpdate: (d) => ctx.drag.onMove(d.globalPosition),
      onDragEnd: (_) => ctx.drag.onEnd(),
      onDraggableCanceled: (_, _) => ctx.drag.onEnd(),
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 48),
          child: Transform.rotate(
            angle: -0.035,
            child: _CardFace(
              item: item,
              picked: false,
              wrong: false,
              number: null,
              expand: false,
              lifted: true,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: face),
      child: GestureDetector(onTap: () => ctx.tapCard(id), child: face),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.item,
    required this.picked,
    required this.wrong,
    required this.number,
    required this.expand,
    this.lifted = false,
  });

  final PoolItem item;
  final bool picked;
  final bool wrong;
  final int? number;
  final bool expand;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final fill = wrong ? AppColors.wrongFill : (picked ? AppColors.pickedFill : Colors.white);
    final edge = wrong
        ? AppColors.wrongBorder
        : (picked ? AppColors.pickedBorder : (lifted ? AppColors.sky400 : AppColors.chipBorder));
    final decoration = BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(15),
      border: Border(
        left: BorderSide(color: edge, width: 2),
        top: BorderSide(color: edge, width: 2),
        right: BorderSide(color: edge, width: 2),
        bottom: BorderSide(color: edge, width: 4),
      ),
      boxShadow: [
        if (picked)
          BoxShadow(color: AppColors.pickedBorder.withValues(alpha: 0.4), spreadRadius: 4),
        if (lifted)
          const BoxShadow(
            color: Color(0x80023C6E),
            blurRadius: 30,
            offset: Offset(0, 18),
            spreadRadius: -8,
          ),
      ],
    );
    final asset = item.img == null ? null : equipmentAsset(item.img!);
    final Widget body;
    if (asset != null) {
      body = Container(
        width: 76,
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.all(6),
        decoration: decoration,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(asset, width: 44, height: 44, fit: BoxFit.contain),
                const SizedBox(height: 4),
                Text(
                  item.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10.5, height: 1.25, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (number != null)
              Positioned(
                left: -2,
                top: -2,
                child: _NumberBadge(
                  number!,
                  color: AppColors.gold,
                  edge: AppColors.goldEdge,
                  size: 22,
                ),
              ),
          ],
        ),
      );
    } else {
      body = Container(
        constraints: const BoxConstraints(minHeight: 46),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: decoration,
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (number != null) ...[
              _NumberBadge(number!, color: AppColors.gold, edge: AppColors.goldEdge, size: 24),
              const SizedBox(width: 8),
            ] else ...[
              const Icon(Icons.drag_indicator, size: 18, color: Color(0xFF9DBDD4)),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                item.text,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }
    return Semantics(button: true, selected: picked, child: body);
  }
}

/// A bar on the left of a card while another card hovers over it: it will go in front.
class _InsertMark extends StatelessWidget {
  const _InsertMark({required this.show, required this.child});

  final bool show;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: show ? 5 : 0,
        height: 60,
        margin: EdgeInsets.only(right: show ? 5 : 0),
        decoration: BoxDecoration(color: AppColors.sky500, borderRadius: BorderRadius.circular(3)),
      ),
      Flexible(child: child),
    ],
  );
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge(this.n, {required this.color, required this.edge, required this.size});

  final int n;
  final Color color;
  final Color edge;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 2))],
    ),
    child: Text(
      '$n',
      style: TextStyle(
        fontFamily: displayFont,
        fontWeight: FontWeight.w600,
        fontSize: size * 0.5,
        color: Colors.white,
      ),
    ),
  );
}

class _CountPill extends StatelessWidget {
  const _CountPill(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
    ),
  );
}
