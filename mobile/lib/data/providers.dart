import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/case_model.dart';
import 'case_repository.dart';

final caseRepositoryProvider = Provider((ref) => CaseRepository(rootBundle));

/// The 8 cases shipped in the app, beds 1 to 8.
final bundledCasesProvider = FutureProvider<List<BedCase>>(
  (ref) => ref.watch(caseRepositoryProvider).loadBundled(),
);
