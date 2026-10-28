import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../game/case_model.dart';
import '../../game/rules.dart';
import 'monitor.dart';

/// How the bedside reacts to the player: calm, alarming after a wrong check or a timeout, settled
/// once the step is passed. The monitor always shows the step's own numbers, never invented ones.
enum SceneMood { calm, alarm, passed }

/// The bedside at the top of each step (Thanee's visual concept, 2026-10-28): the doctor with the
/// step's line, the patient in bed, and the monitor on its stand.
class BedsideScene extends StatelessWidget {
  const BedsideScene({
    super.key,
    required this.bedCase,
    required this.vitals,
    required this.speech,
    this.mood = SceneMood.calm,
  });

  final BedCase bedCase;
  final Vitals vitals;
  final String speech;
  final SceneMood mood;

  @override
  Widget build(BuildContext context) {
    final (fill, edge, floor) = switch (mood) {
      SceneMood.calm => (const Color(0xFFDCEFFB), const Color(0xFFCDE6F6), const Color(0xFFC7E3F4)),
      SceneMood.alarm => (
        const Color(0xFFFDECEC),
        const Color(0xFFFCA5A5),
        const Color(0xFFF9D9D9),
      ),
      SceneMood.passed => (
        const Color(0xFFE6F8EE),
        const Color(0xFF86EFAC),
        const Color(0xFFD3F2E0),
      ),
    };
    const fade = Duration(milliseconds: 250);
    return AnimatedContainer(
      duration: fade,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: edge, width: 2),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 44,
            child: AnimatedContainer(duration: fade, color: floor),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Doctor(bedCase: bedCase, speech: speech),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: _Bed(
                            female: bedCase.patientName.startsWith('นาง'),
                            settled: mood == SceneMood.passed,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SceneMonitor(vitals: vitals, mood: mood),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Doctor extends StatelessWidget {
  const _Doctor({required this.bedCase, required this.speech});

  final BedCase bedCase;
  final String speech;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: AppColors.sky300, width: 2),
        ),
        child: Text(bedCase.doctorAvatar, style: const TextStyle(fontSize: 24)),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 7, 11, 8),
          decoration: const BoxDecoration(
            color: AppColors.bubbleFill,
            border: Border.fromBorderSide(BorderSide(color: AppColors.bubbleBorder, width: 2)),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
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
                  fontSize: 12.5,
                  color: AppColors.bubbleName,
                ),
              ),
              Text(
                speech.replaceFirst(RegExp(r'^💬\s*', unicode: true), ''),
                style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.bubbleInk),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

/// The patient in bed, drawn; a green tick by the head once the step is passed.
class _Bed extends StatelessWidget {
  const _Bed({required this.female, required this.settled});

  final bool female;
  final bool settled;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 214 / 112,
    child: Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _BedPainter(female: female)),
        ),
        if (settled)
          Align(
            alignment: const Alignment(-0.3, -0.85),
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.successEdge, offset: Offset(0, 2))],
              ),
              child: const Icon(Icons.check_rounded, size: 17, color: Colors.white),
            ),
          ),
      ],
    ),
  );
}

class _BedPainter extends CustomPainter {
  const _BedPainter({required this.female});

  final bool female;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 214, size.height / 112);
    Paint fill(Color c) => Paint()..color = c;
    RRect box(double x, double y, double w, double h, double r) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));
    const rail = Color(0xFF9CCFF0);
    canvas
      ..drawRRect(box(4, 8, 12, 78, 5), fill(rail))
      ..drawRRect(box(20, 84, 6, 20, 2), fill(rail))
      ..drawRRect(box(188, 84, 6, 20, 2), fill(rail))
      ..drawCircle(const Offset(23, 106), 4, fill(AppColors.ink3))
      ..drawCircle(const Offset(191, 106), 4, fill(AppColors.ink3))
      ..drawRRect(box(10, 60, 200, 25, 9), fill(Colors.white))
      ..drawRRect(
        box(10, 60, 200, 25, 9),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFAED6EF),
      )
      ..drawRRect(box(18, 42, 48, 22, 11), fill(AppColors.sky100));
    const hair = Color(0xFFCBD5E1);
    if (female) canvas.drawCircle(const Offset(29, 33), 7, fill(hair));
    canvas.drawCircle(const Offset(42, 41), 15, fill(const Color(0xFFF2C9A0)));
    final top = Path()
      ..moveTo(27, 39)
      ..arcToPoint(const Offset(57, 39), radius: const Radius.circular(15))
      ..quadraticBezierTo(50, 31, 42, 32)
      ..quadraticBezierTo(33, 32, 27, 39)
      ..close();
    canvas
      ..drawPath(top, fill(hair))
      ..drawRRect(box(58, 46, 146, 20, 10), fill(AppColors.sky300))
      ..drawCircle(const Offset(198, 52), 10, fill(AppColors.sky300))
      ..drawLine(
        const Offset(72, 53),
        const Offset(190, 53),
        Paint()
          ..color = AppColors.sky400
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_BedPainter old) => old.female != female;
}

/// The monitor on its stand: heart rate large, BP / SpO2 / MAP small, the moving trace. It
/// alarms on his alarm values and while a wrong check is shown; it turns green when passed.
class _SceneMonitor extends StatelessWidget {
  const _SceneMonitor({required this.vitals, required this.mood});

  final Vitals vitals;
  final SceneMood mood;

  @override
  Widget build(BuildContext context) {
    final alarm = mood == SceneMood.alarm || isAlarmVitals(vitals);
    final edge = alarm
        ? AppColors.alarm
        : mood == SceneMood.passed
        ? AppColors.success
        : AppColors.monitorEdge;
    return Semantics(
      label:
          'HR ${vitals.hr} · BP ${vitals.bp} · SpO₂ ${vitals.spo2} · MAP ${vitals.map}'
          '${alarm ? ' · ALARM' : ''}',
      excludeSemantics: true,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (alarm)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.alarm,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 13, color: Colors.white),
                      SizedBox(width: 3),
                      Text(
                        'ALARM',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
              decoration: BoxDecoration(
                color: AppColors.monitorBottom,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: edge, width: 2),
                boxShadow: [
                  if (mood == SceneMood.alarm)
                    BoxShadow(color: AppColors.alarm.withValues(alpha: 0.45), blurRadius: 16),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'HR',
                        style: TextStyle(fontSize: 10.5, color: AppColors.monitorLabel),
                      ),
                      const Spacer(),
                      Text(
                        '${vitals.hr}',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 26,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: alarm ? AppColors.ecgAlarm : AppColors.hr,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Each reading shrinks rather than overflow at large text sizes.
                  Row(
                    children: [
                      for (final (i, (label, value, color)) in [
                        ('BP', vitals.bp, AppColors.bp),
                        ('SpO₂', vitals.spo2, AppColors.spo2),
                        ('MAP', '${vitals.map}', AppColors.map),
                      ].indexed) ...[
                        if (i > 0) const SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: _Reading(label: label, value: value, color: color),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(
                    height: 20,
                    // The trace paints past its box; the monitor's glass ends here.
                    child: ClipRect(
                      child: EcgTrace(
                        hr: vitals.hr,
                        color: alarm ? AppColors.ecgAlarm : AppColors.ecg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Center(child: Container(width: 4, height: 22, color: const Color(0xFF9CCFF0))),
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF9CCFF0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Reading extends StatelessWidget {
  const _Reading({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 9, color: AppColors.monitorLabel)),
      Text(
        value,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    ],
  );
}
