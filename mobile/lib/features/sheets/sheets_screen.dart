import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/providers.dart';
import '../../game/case_model.dart';
import '../../l10n/generated/app_localizations.dart';

/// Every case with its answers, for the clinical reviewer and instructors: one read-only page per
/// bed, all 6 steps with the correct answers marked (open question 5).
class SheetsScreen extends ConsumerWidget {
  const SheetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cases = ref.watch(bundledCasesProvider).value ?? const <BedCase>[];
    return Scaffold(
      appBar: AppBar(title: Text(l.sheetsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(l.sheetsIntro, style: const TextStyle(color: AppColors.ink2)),
          ),
          for (final c in cases)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.sky100,
                  child: Text(
                    c.bedNum.toString().padLeft(2, '0'),
                    style: const TextStyle(color: AppColors.sky700, fontWeight: FontWeight.w600),
                  ),
                ),
                title: Text(c.caseTitle),
                subtitle: Text(c.dxBadge),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/sheets/${c.bedNum}'),
              ),
            ),
        ],
      ),
    );
  }
}

class SheetScreen extends ConsumerWidget {
  const SheetScreen({super.key, required this.bedNum});

  final int bedNum;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cases = ref.watch(bundledCasesProvider).value ?? const <BedCase>[];
    final c = cases.where((x) => x.bedNum == bedNum).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(c == null ? l.sheetsTitle : l.sheetTitle(c.bedCode))),
      body: c == null
          ? const SizedBox()
          : SelectionArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                children: [
                  _Header(c: c, l: l),
                  for (final s in c.stages) _StageSheet(stage: s, l: l),
                ],
              ),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.c, required this.l});

  final BedCase c;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) => _Box(
    children: [
      Text(c.caseTitle, style: _h1),
      const SizedBox(height: 4),
      Text('${c.patientName} · ${c.dxBadge} · ${c.statusText}'),
      Text('${l.sheetDoctor}: ${c.doctorName}'),
      if (c.clinicalNote != null) Text('${l.sheetNote}: ${c.clinicalNote}'),
    ],
  );
}

class _StageSheet extends StatelessWidget {
  const _StageSheet({required this.stage, required this.l});

  final Stage stage;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final v = stage.vitals;
    String text(String id) => stage.pool.firstWhere((p) => p.id == id).text;
    final choices = stage.choices;
    final sequence = stage.sequence;
    final trays = stage.trays;
    final drop = stage.unorderedDrop;
    return _Box(
      children: [
        Text(stage.name, style: _h2),
        Text(
          '${stage.mechanic} · HR ${v.hr} · BP ${v.bp} · SpO₂ ${v.spo2} · MAP ${v.map}',
          style: const TextStyle(fontSize: 12, color: AppColors.ink3),
        ),
        const SizedBox(height: 6),
        Text(
          stage.doctorSpeech.replaceFirst(RegExp(r'^💬\s*', unicode: true), ''),
          style: const TextStyle(color: AppColors.bubbleInk),
        ),
        Text(stage.reading, style: const TextStyle(color: AppColors.readingBody)),
        if (choices != null) ...[
          _prompt(choices.prompt),
          for (final o in choices.options)
            _Line(ok: o.correct, text: o.text, note: o.correct ? l.sheetCorrect : l.sheetWrong),
        ],
        if (sequence != null) ...[
          _prompt('${sequence.prompt} · ${l.sheetOrder}'),
          for (final (i, id) in sequence.correctOrder.indexed) _Numbered(i + 1, text(id)),
        ],
        if (trays != null) ...[
          _prompt(
            '${trays.prompt.replaceAll('**', '')} · '
            '${trays.ordered ? l.sheetInOrder : l.sheetAnyOrder}',
          ),
          for (final t in trays.trays) ...[
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${t.sterile ? '✨' : '🧰'} ${t.displayName}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            for (final (i, id) in (trays.ordered ? t.expectedOrder : t.expectedIds)!.indexed)
              trays.ordered ? _Numbered(i + 1, text(id)) : _Line(ok: true, text: text(id)),
          ],
        ],
        if (drop != null) ...[
          _prompt(drop.prompt),
          for (final p in drop.pool)
            _Line(
              ok: drop.expectedIds.contains(p.id),
              text: p.text,
              note: drop.expectedIds.contains(p.id) ? l.sheetSafe : l.sheetUnsafe,
            ),
        ],
      ],
    );
  }

  Widget _prompt(String s) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 4),
    child: Text(
      s,
      style: const TextStyle(fontFamily: displayFont, fontWeight: FontWeight.w600),
    ),
  );
}

const _h1 = TextStyle(fontFamily: displayFont, fontWeight: FontWeight.w600, fontSize: 18);
const _h2 = TextStyle(fontFamily: displayFont, fontWeight: FontWeight.w600, fontSize: 16);

class _Box extends StatelessWidget {
  const _Box({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.cardBorder, width: 2),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.ok, required this.text, this.note});

  final bool ok;
  final String text;
  final String? note;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ok ? '✓ ' : '✗ ',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: ok ? AppColors.successEdge : AppColors.dangerEdge,
          ),
        ),
        Expanded(child: Text(note == null ? text : '$text  ($note)')),
      ],
    ),
  );
}

class _Numbered extends StatelessWidget {
  const _Numbered(this.n, this.text);

  final int n;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Text('$n.', style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
