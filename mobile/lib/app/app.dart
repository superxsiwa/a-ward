import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../features/about/about_screen.dart';
import '../features/game/game_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/sheets/sheets_screen.dart';
import '../features/ward/ward_screen.dart';
import '../l10n/generated/app_localizations.dart';
import 'theme.dart';

GoRouter _buildRouter() => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WardScreen(),
      routes: [
        GoRoute(
          path: 'bed/:bedNum',
          builder: (context, state) =>
              GameScreen(bedNum: int.tryParse(state.pathParameters['bedNum']!) ?? 1),
        ),
        GoRoute(
          path: 'sheets',
          builder: (context, state) => const SheetsScreen(),
          routes: [
            GoRoute(
              path: ':bedNum',
              builder: (context, state) =>
                  SheetScreen(bedNum: int.tryParse(state.pathParameters['bedNum']!) ?? 1),
            ),
          ],
        ),
        GoRoute(path: 'about', builder: (context, state) => const AboutScreen()),
        GoRoute(path: 'settings', builder: (context, state) => const SettingsScreen()),
      ],
    ),
  ],
);

class CriticalCareApp extends StatefulWidget {
  const CriticalCareApp({super.key});

  @override
  State<CriticalCareApp> createState() => _CriticalCareAppState();
}

class _CriticalCareAppState extends State<CriticalCareApp> {
  // One router per app instance: a global one kept the last location across widget tests.
  late final GoRouter _router = _buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    theme: buildTheme(),
    routerConfig: _router,
    locale: const Locale('th'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    debugShowCheckedModeBanner: false,
    builder: (context, child) => _WideScreenText(child: child!),
  );
}

/// On wide screens (a desktop browser, a tablet in landscape) the phone's point sizes read
/// small, so text grows by 20% on top of the device's own text size setting.
class _WideScreenText extends StatelessWidget {
  const _WideScreenText({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width < 1100) return child;
    return MediaQuery(
      data: mq.copyWith(textScaler: _Scaled(mq.textScaler, 1.2)),
      child: child,
    );
  }
}

class _Scaled extends TextScaler {
  const _Scaled(this.base, this.factor);

  final TextScaler base;
  final double factor;

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.scale(1) * factor;
}
