/// What a text card is about, for its icon (presentation only, Thanee's visual concept
/// 2026-10-28). Chosen from words in the card's own text, never from whether it is right, so the
/// icon gives nothing away.
library;

enum CardKind { record, talk, medicine, monitor, position, handsOn, assess, equipment, care }

/// The first rule that matches wins, so the more specific kinds come first.
final _rules = <(CardKind, RegExp)>[
  (
    CardKind.record,
    RegExp(r'บันทึก|รายงาน|ส่งเวร|ISBAR|SBAR|เอกสาร|ลงชื่อ|ใบยินยอม', caseSensitive: false),
  ),
  (
    CardKind.talk,
    RegExp(
      r'พูดคุย|อธิบาย|แจ้ง|บอก|ถาม|ให้ข้อมูล|ปลอบ|สื่อสาร|ประสาน|กลั้นหายใจ',
      caseSensitive: false,
    ),
  ),
  // "ยา" (drug) but not inside "พยาบาล" (nursing).
  (
    CardKind.medicine,
    RegExp(
      r'(?<!พ)ยา|สารน้ำ|ให้เลือด|\bIV\b|Levophed|Norepinephrine|Atropine|Heparin|Adrenaline|NSS',
      caseSensitive: false,
    ),
  ),
  (
    CardKind.monitor,
    RegExp(r'วัด|V/S|สัญญาณชีพ|EKG|ECG|มอนิเตอร์|monitor|SpO2|ความดัน', caseSensitive: false),
  ),
  (
    CardKind.position,
    RegExp(r'ท่า|นอน|งอ|เหยียด|ศีรษะ|พลิก|ลุก|นั่ง|เดิน|Fowler', caseSensitive: false),
  ),
  (
    CardKind.handsOn,
    RegExp(r'กด|คลำ|ทำแผล|ถอด|ปิด|เปิด|เช็ด|ทำความสะอาด|ดูด|ใส่|จับ|อัด|ปล่อย|ยก|ติด(?!ตาม)|Clamp'),
  ),
  (CardKind.assess, RegExp(r'ตรวจ|ประเมิน|สังเกต|เฝ้าระวัง|ติดตาม|ฟัง|ดู')),
  (CardKind.equipment, RegExp(r'เตรียม|อุปกรณ์|เครื่อง|ถาด|ชุด')),
];

CardKind cardKindOf(String text) {
  for (final (kind, rule) in _rules) {
    if (rule.hasMatch(text)) return kind;
  }
  return CardKind.care;
}

// The analyzer's checker does not know Unicode property escapes; the Dart VM and browsers do
// (card_kinds_test covers ZWJ sequences, VS16 and skin tones).
final _leadingEmoji = RegExp(
  // ignore: valid_regexps
  r'^\s*(?:\p{Extended_Pictographic}|\p{Regional_Indicator})(?:\uFE0F|\u200D\p{Extended_Pictographic}|\p{Emoji_Modifier}|\p{Regional_Indicator})*\uFE0F?\s*',
  unicode: true,
);

/// [text] without a leading emoji. In step 4 of every case only the right cards begin with one
/// (finding F-emoji), so the card shows its icon instead and the emoji stays in the case file.
String withoutLeadingEmoji(String text) {
  final rest = text.replaceFirst(_leadingEmoji, '');
  return rest.isEmpty ? text : rest;
}
