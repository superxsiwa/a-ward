import 'dart:convert';

import 'package:flutter/services.dart';

import '../game/case_model.dart';

/// The cases shipped in the app: assets/cases/bed01.json .. bed08.json, converted from
/// superxsiwa's backend/src/services/beds by tool/convert_cases.mjs.
const bundledCaseCount = 8;

String bundledCaseAsset(int bedNum) => 'assets/cases/bed${'$bedNum'.padLeft(2, '0')}.json';

/// The bundled asset for a case image such as `./assets/equipment/syringe.png`, or null when
/// the path does not name an equipment PNG.
String? equipmentAsset(String img) {
  final m = RegExp(r'(?:^|/)equipment/([a-z0-9_]+\.png)$').firstMatch(img);
  return m == null ? null : 'assets/equipment/${m[1]}';
}

class CaseRepository {
  CaseRepository(this._bundle);

  final AssetBundle _bundle;

  Future<List<BedCase>> loadBundled() async => [
    for (final json in await loadBundledJson()) BedCase.fromJson(json),
  ];

  /// The shipped cases as JSON, for the export.
  Future<List<Map<String, Object?>>> loadBundledJson() async => [
    for (var n = 1; n <= bundledCaseCount; n++)
      jsonDecode(await _bundle.loadString(bundledCaseAsset(n))) as Map<String, Object?>,
  ];
}
