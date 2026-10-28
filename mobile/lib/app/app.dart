import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../features/about/about_screen.dart';
import '../features/game/game_screen.dart';
import '../features/sheets/sheets_screen.dart';
import '../features/ward/ward_screen.dart';
import '../l10n/generated/app_localizations.dart';
import 'theme.dart';

final _router = GoRouter(
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
      ],
    ),
  ],
);

class CriticalCareApp extends StatelessWidget {
  const CriticalCareApp({super.key});

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
  );
}
