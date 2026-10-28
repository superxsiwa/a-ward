import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../game/case_model.dart';
import '../../game/rules.dart';

/// The bedside monitor: bed, patient, HR / BP / SpO2 / MAP tiles and a moving ECG trace.
/// It turns red and shows ALARM on alarm vitals.
class BedsideMonitor extends StatelessWidget {
  const BedsideMonitor({super.key, required this.bedCase, required this.vitals});

  final BedCase bedCase;
  final Vitals vitals;

  @override
  Widget build(BuildContext context) {
    final alarm = isAlarmVitals(vitals);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.topLeft,
          radius: 1.6,
          colors: [AppColors.monitorTop, AppColors.monitorBottom],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: alarm ? AppColors.alarm : AppColors.monitorEdge, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                Text(
                  bedCase.bedCode,
                  style: const TextStyle(
                    fontFamily: displayFont,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bedCase.patientName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF9FC3DE)),
                  ),
                ),
                if (alarm) const _AlarmBadge(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
            child: Row(
              children: [
                _Tile(label: 'HR', value: '${vitals.hr}', color: AppColors.hr),
                _Tile(label: 'BP', value: vitals.bp, color: AppColors.bp, small: true),
                _Tile(label: 'SpO₂', value: vitals.spo2, color: AppColors.spo2),
                _Tile(label: 'MAP', value: '${vitals.map}', color: AppColors.map),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: EcgTrace(hr: vitals.hr, color: alarm ? AppColors.ecgAlarm : AppColors.ecg),
          ),
        ],
      ),
    );
  }
}

class _AlarmBadge extends StatelessWidget {
  const _AlarmBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
    decoration: BoxDecoration(color: AppColors.alarm, borderRadius: BorderRadius.circular(99)),
    child: const Text(
      'ALARM',
      style: TextStyle(
        fontFamily: displayFont,
        fontWeight: FontWeight.w600,
        fontSize: 11,
        letterSpacing: 0.6,
        color: Colors.white,
      ),
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, required this.color, this.small = false});

  final String label;
  final String value;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
              color: AppColors.monitorLabel,
            ),
          ),
          SizedBox(
            height: 24,
            child: FittedBox(
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  fontSize: small ? 16 : 19,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// ECG lead II: four beats across the width, scrolling left at [hr] beats per minute
/// (his EcgWave). Still when the platform asks for reduced motion.
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

/// The doctor's avatar and speech bubble for the current step.
class DoctorBubble extends StatelessWidget {
  const DoctorBubble({super.key, required this.bedCase, required this.speech});

  final BedCase bedCase;
  final String speech;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFDBEAFE)],
          ),
        ),
        child: Text(bedCase.doctorAvatar, style: const TextStyle(fontSize: 28)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 9, 13, 9),
          decoration: BoxDecoration(
            color: AppColors.bubbleFill,
            border: const Border.fromBorderSide(
              BorderSide(color: AppColors.bubbleBorder, width: 2),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bedCase.doctorName,
                style: const TextStyle(
                  fontFamily: displayFont,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.bubbleName,
                ),
              ),
              Text(
                speech.replaceFirst(RegExp(r'^💬\s*', unicode: true), ''),
                style: const TextStyle(fontSize: 14.5, height: 1.5, color: AppColors.bubbleInk),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
