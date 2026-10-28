import 'package:criticalcare/data/progress_store.dart';
import 'package:criticalcare/game/progress.dart';

/// Progress kept in memory, for widget tests (no platform channel).
class MemoryProgressStore implements ProgressStore {
  MemoryProgressStore({this.progress = Progress.empty, this.seen = true});

  Progress progress;
  bool seen;
  int saves = 0;

  @override
  Future<Progress> load() async => progress;

  @override
  Future<void> save(Progress p) async {
    progress = p;
    saves++;
  }

  @override
  Future<bool> noticeSeen() async => seen;

  @override
  Future<void> markNoticeSeen() async => seen = true;
}
