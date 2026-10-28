import 'package:flutter/material.dart';

/// Colours from superxsiwa's frontend/src/styles/style.css.
abstract final class AppColors {
  static const ink = Color(0xFF0F2742);
  static const ink2 = Color(0xFF44607A);
  static const ink3 = Color(0xFF7B93A8);

  static const sky50 = Color(0xFFF0F9FF);
  static const sky100 = Color(0xFFE0F2FE);
  static const sky300 = Color(0xFF7DD3FC);
  static const sky400 = Color(0xFF38BDF8);
  static const sky500 = Color(0xFF0EA5E9);
  static const sky600 = Color(0xFF0284C7);
  static const sky700 = Color(0xFF0369A1);

  static const cardBorder = Color(0xFFDCECF7);
  static const chipBorder = Color(0xFFBFE1F6);
  static const optionBorder = Color(0xFFD4E6F3);
  static const ghostBorder = Color(0xFFC9DCEA);

  static const success = Color(0xFF22C55E);
  static const successEdge = Color(0xFF15803D);
  static const danger = Color(0xFFF43F5E);
  static const dangerEdge = Color(0xFFBE123C);
  static const gold = Color(0xFFF59E0B);
  static const goldEdge = Color(0xFFB45309);

  static const wrongFill = Color(0xFFFFF1F2);
  static const wrongBorder = Color(0xFFFB7185);
  static const pickedFill = Color(0xFFFEF9C3);
  static const pickedBorder = Color(0xFFFACC15);

  static const monitorTop = Color(0xFF123556);
  static const monitorBottom = Color(0xFF06182A);
  static const monitorEdge = Color(0xFF23557C);
  static const monitorLabel = Color(0xFF8FB3CF);
  static const alarm = Color(0xFFEF4444);
  static const ecg = Color(0xFF4ADE80);
  static const ecgAlarm = Color(0xFFF87171);
  static const hr = Color(0xFF4ADE80);
  static const bp = Color(0xFFFDA4AF);
  static const spo2 = Color(0xFF67E8F9);
  static const map = Color(0xFFFDE047);

  static const bubbleFill = Color(0xFFFFFBEA);
  static const bubbleBorder = Color(0xFFFDE68A);
  static const bubbleInk = Color(0xFF78350F);
  static const bubbleName = Color(0xFFB45309);
  static const readingHead = Color(0xFFFFFBEB);
  static const readingInk = Color(0xFF92400E);
  static const readingBody = Color(0xFF57534E);

  static const mechFill = Color(0xFFFCE7F3);
  static const mechBorder = Color(0xFFFBCFE8);
  static const mechInk = Color(0xFFBE185D);

  static const trayFill = Color(0xFFDBEAFE);
  static const trayEdge = Color(0xFF93C5FD);
  static const trayInk = Color(0xFF1E3A8A);
  static const sterileFill = Color(0xFFD1FAE5);
  static const sterileEdge = Color(0xFF6EE7B7);
  static const sterileInk = Color(0xFF065F46);

  static const slotFill = Color(0xFFF5FBFF);
  static const slotBorder = Color(0xFF9CCFF0);
  static const poolBorder = Color(0xFFACD6EE);

  static const stepIdle = Color(0xFFE2EDF5);
  static const stepIdleEdge = Color(0xFFC9DBE8);

  static const page = Color(0xFFEAF6FE);
}

/// Mitr for headings and buttons, Prompt for body text, as in his frontend.
const displayFont = 'Mitr';
const bodyFont = 'Prompt';

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.sky500,
      primary: AppColors.sky500,
      surface: Colors.white,
      onSurface: AppColors.ink,
    ),
    fontFamily: bodyFont,
    scaffoldBackgroundColor: AppColors.page,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: TextStyle(
        fontFamily: displayFont,
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: AppColors.ink,
      ),
    ),
  );
}
