import 'case_model.dart';
import 'rules.dart';

/// One reason a case cannot be played as written.
class CaseIssue {
  const CaseIssue(this.path, this.message);

  final String path;
  final String message;

  @override
  String toString() => '$path: $message';
}

/// Checks that [bedCase] can be played: every expected id exists in its pool, every tray step
/// can be finished, each step has one task the game can show, the vitals read as numbers.
///
/// It never judges whether the clinical content is right; that is the nurse's review.
/// [imageExists] answers whether a pool item's `img` can be shown.
List<CaseIssue> validateCase(BedCase bedCase, {bool Function(String img)? imageExists}) {
  final issues = <CaseIssue>[];
  void issue(String path, String message) => issues.add(CaseIssue(path, message));
  void notBlank(String path, String value) => _notBlank(path, value, issue);

  if (bedCase.bedNum < 1) issue(r'$.bedNum', 'must be 1 or more');
  notBlank(r'$.bedCode', bedCase.bedCode);
  notBlank(r'$.patientName', bedCase.patientName);
  notBlank(r'$.caseTitle', bedCase.caseTitle);
  notBlank(r'$.dxBadge', bedCase.dxBadge);
  notBlank(r'$.doctorName', bedCase.doctorName);

  if (bedCase.stages.length != stepsPerCase) {
    issue(r'$.stageData', 'has ${bedCase.stages.length} steps, expected $stepsPerCase');
  }
  final stageIds = <String>{};
  for (final (i, stage) in bedCase.stages.indexed) {
    final at = '\$.stageData[$i]';
    if (!stageIds.add(stage.id)) issue('$at.id', 'step id ${stage.id} is used twice');
    notBlank('$at.name', stage.name);
    notBlank('$at.reading', stage.reading);
    notBlank('$at.doctorSpeech', stage.doctorSpeech);
    _checkVitals('$at.vitals', stage.vitals, issue);
    _checkStage(at, stage, issue, imageExists);
  }
  return issues;
}

final _bp = RegExp(r'^\d{2,3}/\d{2,3}$');
final _spo2 = RegExp(r'^\d{1,3}%$');

void _checkVitals(String at, Vitals v, void Function(String, String) issue) {
  if (v.hr <= 0) issue('$at.hr', 'must be above 0');
  if (v.map <= 0) issue('$at.map', 'must be above 0');
  if (!_bp.hasMatch(v.bp)) issue('$at.bp', '"${v.bp}" is not systolic/diastolic');
  if (!_spo2.hasMatch(v.spo2) || int.parse(v.spo2.replaceAll('%', '')) > 100) {
    issue('$at.spo2', '"${v.spo2}" is not a percentage');
  }
}

void _checkStage(
  String at,
  Stage stage,
  void Function(String, String) issue,
  bool Function(String img)? imageExists,
) {
  final poolTasks = [
    if (stage.sequence != null) 'sequenceTask',
    if (stage.trays != null) 'traysTask',
    if (stage.unorderedDrop != null) 'unorderedDropTask',
  ];
  if (poolTasks.length > 1) {
    issue(at, 'has ${poolTasks.join(' and ')}; a step can show one of them');
  }
  if (poolTasks.isEmpty && stage.choices == null) issue(at, 'has no task');

  final choices = stage.choices;
  if (choices != null) {
    final c = '$at.choices1toN';
    _notBlank('$c.prompt', choices.prompt, issue);
    if (choices.options.isEmpty) issue('$c.options', 'is empty');
    _unique('$c.options', [for (final o in choices.options) o.id], issue);
    if (choices.options.isNotEmpty && !choices.options.any((o) => o.correct)) {
      issue('$c.options', 'has no correct option');
    }
  }

  final sequence = stage.sequence;
  if (sequence != null) {
    final c = '$at.sequenceTask';
    final pool = _checkPool('$c.pool', sequence.pool, issue, imageExists);
    if (sequence.correctOrder.isEmpty) issue('$c.correctOrder', 'is empty');
    _unique('$c.correctOrder', sequence.correctOrder, issue);
    _inPool('$c.correctOrder', sequence.correctOrder, pool, issue);
  }

  final trays = stage.trays;
  if (trays != null) {
    final c = '$at.traysTask';
    final pool = _checkPool('$c.pool', trays.pool, issue, imageExists);
    if (trays.trays.isEmpty) issue('$c.trays', 'is empty');
    _unique('$c.trays', [for (final t in trays.trays) t.id], issue);
    final placed = <String>[];
    for (final (i, tray) in trays.trays.indexed) {
      final key = trays.ordered ? 'expectedOrder' : 'expectedIds';
      final expected = trays.ordered ? tray.expectedOrder : tray.expectedIds;
      if (expected == null) {
        issue('$c.trays[$i]', 'has no $key');
        continue;
      }
      _inPool('$c.trays[$i].$key', expected, pool, issue);
      placed.addAll(expected);
    }
    _unique('$c.trays (all expected ids)', placed, issue);
    // The step only checks once the pool is empty, so a card no tray expects can never be right.
    for (final id in pool.difference(placed.toSet())) {
      issue('$c.pool', '"$id" belongs in no tray, so the step cannot be passed');
    }
  }

  final drop = stage.unorderedDrop;
  if (drop != null) {
    final c = '$at.unorderedDropTask';
    final pool = _checkPool('$c.pool', drop.pool, issue, imageExists);
    if (drop.expectedIds.isEmpty) issue('$c.expectedIds', 'is empty');
    _unique('$c.expectedIds', drop.expectedIds, issue);
    _inPool('$c.expectedIds', drop.expectedIds, pool, issue);
  }
}

void _notBlank(String path, String value, void Function(String, String) issue) {
  if (value.trim().isEmpty) issue(path, 'is empty');
}

Set<String> _checkPool(
  String at,
  List<PoolItem> pool,
  void Function(String, String) issue,
  bool Function(String img)? imageExists,
) {
  if (pool.isEmpty) issue(at, 'is empty');
  _unique(at, [for (final p in pool) p.id], issue);
  for (final (i, item) in pool.indexed) {
    if (item.text.trim().isEmpty) issue('$at[$i].text', 'is empty');
    final img = item.img;
    if (img != null && imageExists != null && !imageExists(img)) {
      issue('$at[$i].img', '"$img" is not a bundled image');
    }
  }
  return {for (final p in pool) p.id};
}

void _unique(String at, List<String> ids, void Function(String, String) issue) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) issue(at, '"$id" appears twice');
  }
}

void _inPool(String at, List<String> ids, Set<String> pool, void Function(String, String) issue) {
  for (final id in ids) {
    if (!pool.contains(id)) issue(at, '"$id" is not in the pool');
  }
}
