import 'package:criticalcare/app/app.dart';
import 'package:criticalcare/app/sfx.dart';
import 'package:criticalcare/data/progress_store.dart';
import 'package:criticalcare/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/cases.dart';
import '../support/fake_store.dart';
import 'bed01_play_test.dart' show settle, tapText;

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bundledCasesProvider.overrideWith((ref) async => [for (var n = 1; n <= 8; n++) bed(n)]),
          progressStoreProvider.overrideWithValue(MemoryProgressStore()),
          sfxProvider.overrideWithValue(SilentSfx()),
        ],
        child: const CriticalCareApp(),
      ),
    );
    await settle(tester);
  }

  for (final (name, open) in [
    ('settings', (WidgetTester t) => t.tap(find.byTooltip('ตั้งค่า'))),
    ('case sheets', (WidgetTester t) => tapText(t, '📖 ชีทเฉลยเคส')),
  ]) {
    testWidgets('Android back from $name returns to the ward', (tester) async {
      await pumpApp(tester);
      await open(tester);
      await settle(tester);
      expect(find.text('วอร์ดหัวใจ 8 เตียง'), findsNothing);
      final handled = await tester.binding.handlePopRoute();
      await settle(tester);
      expect(handled, isTrue, reason: 'the app must not close');
      expect(find.text('วอร์ดหัวใจ 8 เตียง'), findsOneWidget);
    });
  }
}
