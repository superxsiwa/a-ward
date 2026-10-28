import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/progress_store.dart';

/// His playtime tracker: 5 more seconds every 5 seconds, on any screen, but only while the app is
/// in the foreground (his web page also counted a hidden tab).
class PlayClock extends ConsumerStatefulWidget {
  const PlayClock({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PlayClock> createState() => _PlayClockState();
}

class _PlayClockState extends ConsumerState<PlayClock> {
  static const _tick = Duration(seconds: 5);

  late final AppLifecycleListener _lifecycle;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onStateChange: _changed);
    _changed(WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed);
  }

  void _changed(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _timer ??= Timer.periodic(
        _tick,
        (_) => ref.read(progressProvider.notifier).addPlayTime(_tick.inSeconds),
      );
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
