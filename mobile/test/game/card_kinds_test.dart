import 'dart:convert';
import 'dart:io';

import 'package:criticalcare/game/card_kinds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a leading emoji goes, the rest of the text stays', () {
    expect(withoutLeadingEmoji('💓 วัด V/S ทุก 5 นาที'), 'วัด V/S ทุก 5 นาที');
    expect(withoutLeadingEmoji('🗣️ สังเกตอาการ'), 'สังเกตอาการ', reason: 'with VS16');
    expect(withoutLeadingEmoji('🧑‍⚕️ แพทย์'), 'แพทย์', reason: 'a ZWJ sequence');
    expect(withoutLeadingEmoji('👍🏽 ดี'), 'ดี', reason: 'a skin tone');
    expect(withoutLeadingEmoji('กดห้ามเลือด 💓'), 'กดห้ามเลือด 💓', reason: 'only a leading one');
    expect(withoutLeadingEmoji('5 นาที'), '5 นาที', reason: 'digits are not removed');
    expect(withoutLeadingEmoji('💓'), '💓', reason: 'never an empty card');
  });

  test('bed 01 step 4: kinds follow the words, not the answer', () {
    expect(cardKindOf('💓 วัด V/S ทุก 5 นาที ระวัง Bradycardia'), CardKind.monitor);
    expect(cardKindOf('กดห้ามเลือดแรงจนชีพจรหลังเท้าคลำไม่ได้เลยตลอด 20 นาที'), CardKind.handsOn);
    expect(cardKindOf('🦶 ตรวจคลำชีพจรหลังเท้า สีผิว'), CardKind.handsOn);
    expect(cardKindOf('🗣️ สังเกตอาการคลื่นไส้ และพูดคุยกับคนไข้'), CardKind.talk);
    expect(cardKindOf('ให้คนไข้งอเข่าขวาขึ้น-ลงทุก 5 นาทีป้องกันเมื่อย'), CardKind.position);
  });

  test('"พยาบาล" (nursing) is not a drug', () {
    expect(cardKindOf('ปฏิบัติการพยาบาล'), CardKind.care);
    expect(cardKindOf('ให้ยา Atropine'), CardKind.medicine);
  });

  test('every text card in the shipped cases loses at most its leading emoji', () {
    for (var n = 1; n <= 8; n++) {
      final bed = jsonDecode(File('assets/cases/bed0$n.json').readAsStringSync()) as Map;
      for (final stage in bed['stageData'] as List) {
        for (final task in (stage as Map).values.whereType<Map>()) {
          for (final item in (task['pool'] as List?) ?? const []) {
            final text = (item as Map)['text'] as String;
            final shown = withoutLeadingEmoji(text);
            expect(shown, isNotEmpty);
            expect(text.endsWith(shown), isTrue, reason: 'bed $n: $text');
          }
        }
      }
    }
  });
}
