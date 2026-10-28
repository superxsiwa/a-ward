import 'package:flutter/material.dart';

class EcgTrace extends StatefulWidget {
  const EcgTrace({super.key, required this.hr, required this.color});

  final int hr;
  final Color color;

  @override
  State<EcgTrace> createState() => _EcgTraceState();
}

class _EcgTraceState extends State<EcgTrace> with SingleTickerProviderStateMixin {
  late final AnimationController _beat = AnimationController(vsync: this, duration: _period);

  Duration get _period => Duration(milliseconds: (60000 / widget.hr.clamp(30, 300)).round());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _run();
  }

  @override
  void didUpdateWidget(EcgTrace old) {
    super.didUpdateWidget(old);
    if (old.hr != widget.hr) {
      _beat.duration = _period;
      _run();
    }
  }

  void _run() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _beat.stop();
    } else {
      _beat.repeat();
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.infinite,
      painter: _EcgPainter(phase: _beat, color: widget.color),
    ),
  );
}

class _EcgPainter extends CustomPainter {
  _EcgPainter({required this.phase, required this.color}) : super(repaint: phase);

  final Animation<double> phase;
  final Color color;

  /// One beat in a 60 x 30 box (his BEAT_PATH: `M0 15 h12 l3 -3 l3 3 h6 l2 4 l3 -16 l3 22
  /// l2 -10 h8 l4 -5 l5 5 h9`), as absolute points.
  static const _beat = [
    Offset(0, 15),
    Offset(12, 15),
    Offset(15, 12),
    Offset(18, 15),
    Offset(24, 15),
    Offset(26, 19),
    Offset(29, 3),
    Offset(32, 25),
    Offset(34, 15),
    Offset(42, 15),
    Offset(46, 10),
    Offset(51, 15),
    Offset(60, 15),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final beatWidth = size.width / 4;
    final sx = beatWidth / 60;
    final sy = size.height / 30;
    final path = Path();
    final shift = -phase.value * beatWidth;
    for (var b = 0; b <= 5; b++) {
      final x0 = shift + b * beatWidth;
      for (final (i, p) in _beat.indexed) {
        final point = Offset(x0 + p.dx * sx, p.dy * sy);
        if (b == 0 && i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
    }
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_EcgPainter old) => old.color != color || old.phase != phase;
}
