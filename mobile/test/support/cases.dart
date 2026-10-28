import 'dart:convert';
import 'dart:io';

import 'package:criticalcare/game/case_model.dart';
import 'package:criticalcare/game/step_board.dart';

/// The raw JSON of bundled bed [n], read from disk (tests run in mobile/).
Map<String, Object?> bedJson(int n) =>
    jsonDecode(File('assets/cases/bed0$n.json').readAsStringSync()) as Map<String, Object?>;

BedCase bed(int n) => BedCase.fromJson(bedJson(n));

/// A deep copy of [json] that can be edited.
Map<String, Object?> copyJson(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;

/// Step [i] of [json] (as a map), for editing.
Map<String, Object?> stageOf(Map<String, Object?> json, int i) =>
    (json['stageData'] as List)[i] as Map<String, Object?>;

/// [s] with the right answer for [stage] put in by ordinary moves, ready for a passing check.
StepBoard answered(Stage stage, StepBoard s) {
  for (final o in stage.choices?.options ?? const <ChoiceOption>[]) {
    if (o.correct != s.selected.contains(o.id)) s = s.toggleOption(o.id);
  }
  for (final (i, id) in (stage.sequence?.correctOrder ?? const <String>[]).indexed) {
    s = s.move(id, SlotZone(i));
  }
  final trays = stage.trays;
  for (final t in trays?.trays ?? const <Tray>[]) {
    for (final id in (trays!.ordered ? t.expectedOrder : t.expectedIds)!) {
      s = s.move(id, TrayZone(t.id));
    }
  }
  for (final id in stage.unorderedDrop?.expectedIds ?? const <String>[]) {
    s = s.move(id, const DropBoxZone());
  }
  return s;
}
