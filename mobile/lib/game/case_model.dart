/// The case data: one bed, one procedure, 6 steps.
///
/// The JSON shape is superxsiwa's `BedCasePayload` (backend/src/services/beds/types.ts) unchanged,
/// so the bundled cases and his "award_ccu_cases.json" exports go through the same parser.
/// Parsing checks types only; [validateCase] checks that a case can be played.
library;

enum CaseStatus { stable, alert, critical }

class CaseFormatException implements Exception {
  CaseFormatException(this.path, this.message);

  /// Where in the JSON, for example `stageData[1].traysTask.trays[0].expectedIds`.
  final String path;
  final String message;

  @override
  String toString() => 'CaseFormatException at $path: $message';
}

class Vitals {
  const Vitals({required this.hr, required this.bp, required this.spo2, required this.map});

  final int hr;

  /// Systolic/diastolic as written in the case, for example `126/78`.
  final String bp;

  /// As written in the case, for example `99%`.
  final String spo2;
  final int map;
}

class PoolItem {
  const PoolItem({required this.id, required this.text, this.img});

  final String id;
  final String text;

  /// Image path as written in the case, for example `./assets/equipment/syringe.png`.
  final String? img;
}

class ChoiceOption {
  const ChoiceOption({required this.id, required this.text, required this.correct});

  final String id;
  final String text;
  final bool correct;
}

/// Pick every option that applies (1..N).
class ChoicesTask {
  const ChoicesTask({required this.prompt, required this.options});

  final String prompt;
  final List<ChoiceOption> options;
}

/// Put cards into numbered slots in the right order.
class SequenceTask {
  const SequenceTask({required this.prompt, required this.pool, required this.correctOrder});

  final String prompt;
  final List<PoolItem> pool;
  final List<String> correctOrder;
}

class Tray {
  const Tray({
    required this.id,
    required this.name,
    required this.sterile,
    this.expectedIds,
    this.expectedOrder,
  });

  final String id;

  /// May start with a 🟩 or 🟦 marker; see [displayName].
  final String name;
  final bool sterile;
  final List<String>? expectedIds;
  final List<String>? expectedOrder;

  /// The name without its leading 🟩 / 🟦 marker (his `cleanTray`). `unicode` as in his `/u`
  /// flag: without it the class matches half of the emoji's surrogate pair.
  String get displayName => name.replaceFirst(RegExp(r'^[🟩🟦]\s*', unicode: true), '');
}

/// Sort every pool item into trays; when [ordered], the order inside each tray counts too.
class TraysTask {
  const TraysTask({
    required this.ordered,
    required this.prompt,
    required this.trays,
    required this.pool,
  });

  final bool ordered;
  final String prompt;
  final List<Tray> trays;
  final List<PoolItem> pool;
}

/// Drop the safe cards into one box, in any order; the pool also holds unsafe cards.
class UnorderedDropTask {
  const UnorderedDropTask({required this.prompt, required this.expectedIds, required this.pool});

  final String prompt;
  final List<String> expectedIds;
  final List<PoolItem> pool;
}

class Stage {
  const Stage({
    required this.id,
    required this.name,
    required this.mechanic,
    required this.reading,
    required this.doctorSpeech,
    required this.vitals,
    this.choices,
    this.sequence,
    this.trays,
    this.unorderedDrop,
  });

  /// A number or a string in the JSON; kept as text.
  final String id;
  final String name;
  final String mechanic;
  final String reading;
  final String doctorSpeech;
  final Vitals vitals;
  final ChoicesTask? choices;
  final SequenceTask? sequence;
  final TraysTask? trays;
  final UnorderedDropTask? unorderedDrop;

  /// The cards the player moves. His code takes the first task that has a pool.
  List<PoolItem> get pool => sequence?.pool ?? trays?.pool ?? unorderedDrop?.pool ?? const [];
}

class BedCase {
  const BedCase({
    required this.bedNum,
    required this.bedCode,
    required this.patientName,
    this.patientAge,
    required this.caseTitle,
    required this.dxBadge,
    required this.status,
    required this.statusText,
    required this.doctorName,
    required this.doctorAvatar,
    this.stayDuration,
    this.clinicalNote,
    required this.stages,
  });

  final int bedNum;
  final String bedCode;
  final String patientName;
  final int? patientAge;
  final String caseTitle;
  final String dxBadge;
  final CaseStatus status;
  final String statusText;
  final String doctorName;
  final String doctorAvatar;
  final String? stayDuration;
  final String? clinicalNote;

  /// `stageData` in the JSON.
  final List<Stage> stages;

  factory BedCase.fromJson(Object? json) => _Reader(json, r'$').bedCase();
}

/// Reads one JSON value at [path], so every type error names where it happened.
class _Reader {
  _Reader(this.value, this.path);

  final Object? value;
  final String path;

  Never _fail(String message) => throw CaseFormatException(path, message);

  Map<String, Object?> get _map {
    final v = value;
    if (v is Map<String, Object?>) return v;
    _fail('expected an object');
  }

  bool has(String key) => _map[key] != null;

  _Reader operator [](String key) => _Reader(_map[key], '$path.$key');

  String string() => value is String ? value as String : _fail('expected text');

  String? optString() => value == null ? null : string();

  bool boolean() => value is bool ? value as bool : _fail('expected true or false');

  int integer() {
    final v = value;
    if (v is int) return v;
    if (v is double && v == v.roundToDouble()) return v.toInt();
    _fail('expected a whole number');
  }

  int? optInt() => value == null ? null : integer();

  /// A number or a string, kept as text (stage ids are `number | string`).
  String idText() {
    final v = value;
    if (v is String) return v;
    if (v is num) return integer().toString();
    _fail('expected a number or text');
  }

  List<_Reader> list() {
    final v = value;
    if (v is! List) _fail('expected a list');
    return [for (var i = 0; i < v.length; i++) _Reader(v[i], '$path[$i]')];
  }

  List<String> strings() => [for (final r in list()) r.string()];

  List<String>? optStrings() => value == null ? null : strings();

  T? opt<T>(String key, T Function(_Reader r) read) => has(key) ? read(this[key]) : null;

  BedCase bedCase() {
    final status = this['status'].string();
    return BedCase(
      bedNum: this['bedNum'].integer(),
      bedCode: this['bedCode'].string(),
      patientName: this['patientName'].string(),
      patientAge: this['patientAge'].optInt(),
      caseTitle: this['caseTitle'].string(),
      dxBadge: this['dxBadge'].string(),
      status: CaseStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => this['status']._fail('expected stable, alert or critical'),
      ),
      statusText: this['statusText'].string(),
      doctorName: this['doctorName'].string(),
      doctorAvatar: this['doctorAvatar'].string(),
      stayDuration: this['stayDuration'].optString(),
      clinicalNote: this['clinicalNote'].optString(),
      stages: [for (final s in this['stageData'].list()) s.stage()],
    );
  }

  Stage stage() => Stage(
    id: this['id'].idText(),
    name: this['name'].string(),
    mechanic: this['mechanic'].string(),
    reading: this['reading'].string(),
    doctorSpeech: this['doctorSpeech'].string(),
    vitals: this['vitals'].vitals(),
    choices: opt('choices1toN', (r) => r.choices()),
    sequence: opt('sequenceTask', (r) => r.sequence()),
    trays: opt('traysTask', (r) => r.trays()),
    unorderedDrop: opt('unorderedDropTask', (r) => r.unorderedDrop()),
  );

  Vitals vitals() => Vitals(
    hr: this['hr'].integer(),
    bp: this['bp'].string(),
    spo2: this['spo2'].string(),
    map: this['map'].integer(),
  );

  ChoicesTask choices() => ChoicesTask(
    prompt: this['prompt'].string(),
    options: [
      for (final o in this['options'].list())
        ChoiceOption(
          id: o['id'].string(),
          text: o['text'].string(),
          correct: o['correct'].boolean(),
        ),
    ],
  );

  List<PoolItem> pool() => [
    for (final p in this['pool'].list())
      PoolItem(id: p['id'].string(), text: p['text'].string(), img: p['img'].optString()),
  ];

  SequenceTask sequence() => SequenceTask(
    prompt: this['prompt'].string(),
    pool: pool(),
    correctOrder: this['correctOrder'].strings(),
  );

  TraysTask trays() => TraysTask(
    ordered: this['ordered'].boolean(),
    prompt: this['prompt'].string(),
    trays: [
      for (final t in this['trays'].list())
        Tray(
          id: t['id'].string(),
          name: t['name'].string(),
          sterile: t['sterile'].boolean(),
          expectedIds: t['expectedIds'].optStrings(),
          expectedOrder: t['expectedOrder'].optStrings(),
        ),
    ],
    pool: pool(),
  );

  UnorderedDropTask unorderedDrop() => UnorderedDropTask(
    prompt: this['prompt'].string(),
    expectedIds: this['expectedIds'].strings(),
    pool: pool(),
  );
}
