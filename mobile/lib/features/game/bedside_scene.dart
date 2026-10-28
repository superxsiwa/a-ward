import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../game/case_model.dart';
import '../../game/rules.dart';
import 'monitor.dart';

/// How the bedside reacts to the player: calm, alarming after a wrong check or a timeout, settled
/// once the step is passed. The monitor always shows the step's own numbers, never invented ones.
enum SceneMood { calm, alarm, passed }

/// The bedside at the top of each step: the doctor's line, then the monitor across the full width
/// with the patient in its header (Thanee 2026-10-28: the monitor is the focus; a drawn bed took
/// too much room).
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Doctor(bedCase: bedCase, speech: speech),
      const SizedBox(height: 10),
      _Monitor(bedCase: bedCase, vitals: vitals, mood: mood),
    ],
  );
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

/// The bedside monitor across the full width: the patient and bed in its header, HR / BP / SpO2 /
/// MAP, the moving trace. It alarms on his alarm values and while a wrong check or a timeout is
/// shown (red frame, glow, ALARM, red heart rate); it turns green once the step is passed.
class _Monitor extends StatelessWidget {
  const _Monitor({required this.bedCase, required this.vitals, required this.mood});

  final BedCase bedCase;
  final Vitals vitals;
  final SceneMood mood;

  @override
  Widget build(BuildContext context) {
    final alarm = mood == SceneMood.alarm || isAlarmVitals(vitals);
    final passed = mood == SceneMood.passed;
    final edge = alarm
        ? AppColors.alarm
        : passed
        ? AppColors.success
        : AppColors.monitorEdge;
    return Semantics(
      label:
          '${bedCase.patientName} · HR ${vitals.hr} · BP ${vitals.bp} · SpO₂ ${vitals.spo2} · '
          'MAP ${vitals.map}${alarm ? ' · ALARM' : ''}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment.topLeft,
            radius: 1.6,
            colors: [AppColors.monitorTop, AppColors.monitorBottom],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: edge, width: 3),
          boxShadow: [
            if (mood == SceneMood.alarm)
              BoxShadow(color: AppColors.alarm.withValues(alpha: 0.45), blurRadius: 18),
            if (passed) BoxShadow(color: AppColors.success.withValues(alpha: 0.35), blurRadius: 14),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 0),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    child: Text(
                      bedCase.patientName.startsWith('นาง') ? '👵' : '👴',
                      style: const TextStyle(fontSize: 19),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bedCase.patientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: displayFont,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          bedCase.bedCode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF9FC3DE)),
                        ),
                      ],
                    ),
                  ),
                  if (alarm)
                    const _Chip(
                      color: AppColors.alarm,
                      icon: Icons.warning_amber_rounded,
                      text: 'ALARM',
                    )
                  else if (passed)
                    const _Chip(color: AppColors.success, icon: Icons.check_rounded),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Tile(
                    label: 'HR',
                    value: '${vitals.hr}',
                    color: alarm ? AppColors.ecgAlarm : AppColors.hr,
                    size: 32,
                  ),
                  _Tile(label: 'BP', value: vitals.bp, color: AppColors.bp, size: 19),
                  _Tile(label: 'SpO₂', value: vitals.spo2, color: AppColors.spo2, size: 22),
                  _Tile(label: 'MAP', value: '${vitals.map}', color: AppColors.map, size: 22),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              // The trace paints past its box; the monitor's glass ends here.
              child: ClipRect(
                child: EcgTrace(hr: vitals.hr, color: alarm ? AppColors.ecgAlarm : AppColors.ecg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.color, required this.icon, this.text});

  final Color color;
  final IconData icon;
  final String? text;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: text == null ? 4 : 8, vertical: 3),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white),
        if (text != null) ...[
          const SizedBox(width: 3),
          Text(
            text!,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ],
      ],
    ),
  );
}

/// One reading: its label and value; the value shrinks rather than overflow at large text sizes.
class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, required this.color, required this.size});

  final String label;
  final String value;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.monitorLabel)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: size,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}
