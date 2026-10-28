/// superxsiwa's 20 goals (`MILESTONE_GOALS` in MilestoneDefs.ts): each earns 1 to 3 stars as its
/// value passes three tiers. Titles, descriptions and tiers are his, unchanged.
library;

import 'progress.dart';

/// What the goals are measured on (his `MilestoneContextData`).
class MilestoneContext {
  const MilestoneContext({required this.progress, required this.shiftsCleared});

  final Progress progress;

  /// Worked roster days cleared (days off not counted).
  final int shiftsCleared;

  PlayerStats get stats => progress.stats;
}

class Milestone {
  const Milestone({
    required this.id,
    required this.title,
    required this.icon,
    required this.unit,
    required this.tiers,
    required this.desc,
    required this.value,
  });

  final String id;
  final String title;
  final String icon;
  final String unit;

  /// The values for 1, 2 and 3 stars.
  final List<num> tiers;
  final String desc;
  final num Function(MilestoneContext c) value;

  /// His `getMilestoneStars`.
  int starsFor(MilestoneContext c) {
    final v = value(c);
    if (v >= tiers[2]) return 3;
    if (v >= tiers[1]) return 2;
    if (v >= tiers[0]) return 1;
    return 0;
  }

  /// How far the bar is from the last tier reached to the next one, 0 to 1 (his `pct`).
  double barFor(MilestoneContext c) {
    final stars = starsFor(c);
    if (stars == 3) return 1;
    final next = tiers[stars];
    final previous = stars == 0 ? 0 : tiers[stars - 1];
    return ((value(c) - previous) / (next - previous)).clamp(0, 1).toDouble();
  }
}

/// A number the way his page prints it (JavaScript): 3.0 as "3", 1.5 as "1.5".
String formatValue(num v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

/// Play time in hours, rounded to one decimal like his `toFixed(1)`.
double playHours(PlayerStats s) => (s.totalPlaySeconds / 360).round() / 10;

Milestone _bed(String id, String title, String icon, int bedNum, String desc) => Milestone(
  id: id,
  title: title,
  icon: icon,
  unit: 'ดาว',
  tiers: const [1, 2, 3],
  desc: desc,
  value: (c) => c.progress.bed(bedNum).stars,
);

final List<Milestone> milestones = [
  Milestone(
    id: 'cases',
    title: 'ยอดหัตถการที่สำเร็จ',
    icon: '💉',
    unit: 'ครั้ง',
    tiers: const [5, 15, 30],
    desc: 'ทำหัตถการการพยาบาลผู้ป่วย CCU สำเร็จตามจำนวนครั้ง',
    value: (c) => c.stats.totalCompletedCases,
  ),
  Milestone(
    id: 'hours',
    title: 'ชั่วโมงบินเวร CCU',
    icon: '⏱️',
    unit: 'ชั่วโมง',
    tiers: const [0.5, 1.5, 3.0],
    desc: 'สะสมเวลาปฏิบัติการพยาบาลและเรียนรู้ในหอผู้ป่วยวิกฤต',
    value: (c) => playHours(c.stats),
  ),
  Milestone(
    id: 'perfect',
    title: 'ความแม่นยำระดับ 3 ดาว',
    icon: '🎯',
    unit: 'เคส',
    tiers: const [3, 8, 16],
    desc: 'ทำเคสได้ถูกต้อง 100% ไม่มีข้อผิดพลาดจนได้ 3 ดาวเต็ม',
    value: (c) => c.stats.perfectCases,
  ),
  Milestone(
    id: 'shifts',
    title: 'ผ่านเวรประจำวันครบ',
    icon: '📋',
    unit: 'เวร',
    tiers: const [2, 7, 14],
    desc: 'ขึ้นเวรตามตารางและดูแลคนไข้ครบทุกเตียงประจำเวรนั้น',
    value: (c) => c.shiftsCleared,
  ),
  Milestone(
    id: 'beds_unlocked',
    title: 'พิชิตเตียงในวอร์ด CCU',
    icon: '🛏️',
    unit: 'เตียง',
    tiers: const [2, 5, 8],
    desc: 'ผ่านเคสหัตถการประจำเตียงต่างๆ ในวอร์ดครบตามจำนวน',
    value: (c) => c.progress.passedCount,
  ),
  _bed(
    'case_sheath',
    'ผู้เชี่ยวชาญ Femoral Sheath',
    '🩹',
    1,
    'เตียง 01: ถอดสายสวนหลอดเลือดแดงขาหนีบและกดหยุดเลือดอย่างปลอดภัย',
  ),
  _bed(
    'case_cvc',
    'หัตถการสายสวนดำใหญ่ (CVC)',
    '🩸',
    2,
    'เตียง 02: เตรียมผู้ป่วยและจัดถาดปลอดเชื้อช่วยแพทย์ใส่สาย CVC',
  ),
  _bed(
    'case_ett',
    'กู้ทางเดินหายใจฉุกเฉิน (ETT)',
    '🫁',
    3,
    'เตียง 03: เตรียมอุปกรณ์ท่อช่วยหายใจและดูดเสมหะเคส Acute Pulmonary Edema',
  ),
  _bed(
    'case_tpm',
    'กระตุ้นหัวใจชั่วคราว (TPM)',
    '⚡',
    4,
    'เตียง 04: ปรับ Rate/Output เครื่อง TPM ช่วยชีวิต Complete Heart Block',
  ),
  _bed(
    'case_levo',
    'บริหารยาวาสโซเพรสเซอร์ (Levophed)',
    '🧪',
    5,
    'เตียง 05: ไตเตรทยากู้ความดัน Titration ยาหลอดเลือดดำส่วนกลาง',
  ),
  _bed(
    'case_drain',
    'ระบายน้ำหุ้มหัวใจ (Pericardial)',
    '🫀',
    6,
    'เตียง 06: ตรวจสอบ Three-way stopcock และปริมาณสิ่งคัดหลั่งป้องกัน Tamponade',
  ),
  _bed(
    'case_cardioversion',
    'ช็อกไฟฟ้ากู้ชีพ (Cardioversion)',
    '💓',
    7,
    'เตียง 07: เปิดโหมด Sync ชาร์จพลังงาน Defibrillator เคสหัวใจเต้นผิดจังหวะ',
  ),
  _bed(
    'case_rp_bleed',
    'รับมือภาวะช็อกเลือดออกหลังช่องท้อง',
    '🚨',
    8,
    'เตียง 08: วินิจฉัย RP Bleed และเปิดเส้นเลือดให้สารน้ำกู้ภาวะ Hypovolemic Shock',
  ),
  Milestone(
    id: 'tray_master',
    title: 'ปรมาจารย์จัดถาดเครื่องมือ',
    icon: '🧰',
    unit: 'ชิ้น',
    tiers: const [15, 45, 90],
    desc: 'หยิบจัดอุปกรณ์ปลอดเชื้อลงถาดหัตถการถูกต้องแม่นยำ',
    value: (c) => c.stats.trayItemsSorted,
  ),
  Milestone(
    id: 'zero_mistakes',
    title: 'ก้าวไร้ที่ติ (Flawless Steps)',
    icon: '🛡️',
    unit: 'ขั้นตอน',
    tiers: const [10, 30, 60],
    desc: 'ผ่านขั้นตอนหัตถการโดยไม่เกิดข้อผิดพลาดในการเลือกคำตอบ',
    value: (c) => c.stats.stepsWithoutMistake,
  ),
  Milestone(
    id: 'emergency_hero',
    title: 'ผู้พิชิตเคสวิกฤตฉุกเฉิน',
    icon: '🚑',
    unit: 'ครั้ง',
    tiers: const [3, 8, 15],
    desc: 'ผ่านเคสที่มีสถานะวิกฤตสัญญาณชีพออดเตือน (Alarm & Critical cases)',
    value: (c) => c.stats.emergencyCasesDone,
  ),
  Milestone(
    id: 'continuous_learning',
    title: 'นักทบทวนฝึกฝนซ้ำ',
    icon: '🔁',
    unit: 'ครั้ง',
    tiers: const [2, 6, 12],
    desc: 'เข้าเล่นซ้ำเพื่อทบทวนทักษะและยกระดับความแม่นยำ',
    value: (c) => c.stats.replayedCases,
  ),
  Milestone(
    id: 'star_collector',
    title: 'นักสะสมดวงดาว CCU',
    icon: '⭐',
    unit: 'ดาว',
    tiers: const [8, 16, 24],
    desc: 'สะสมดาวความสำเร็จจากการดูแลผู้ป่วยทั่วทั้งวอร์ด',
    value: (c) => c.progress.totalStars,
  ),
  Milestone(
    id: 'safety_champion',
    title: 'แชมป์ความปลอดภัยผู้ป่วย (Patient Safety)',
    icon: '🏥',
    unit: 'เคส',
    tiers: const [4, 8, 12],
    desc: 'ปฏิบัติตามมาตรฐานความปลอดภัยสากล 2 Identify & Sterile Technique',
    value: (c) {
      final s = c.stats;
      final safe = s.stepsWithoutMistake ~/ 4;
      return s.totalCompletedCases < safe ? s.totalCompletedCases : safe;
    },
  ),
  Milestone(
    id: 'ccu_legend',
    title: 'ตำนานพยาบาลผู้พิทักษ์หัวใจ',
    icon: '👑',
    unit: 'เป้าหมาย',
    tiers: const [5, 10, 18],
    desc: 'พิชิตเป้าหมาย Milestones อื่นๆ ในหอผู้ป่วยวิกฤตหัวใจ',
    value: (c) => milestones.where((g) => g.id != 'ccu_legend' && g.starsFor(c) >= 1).length,
  ),
];

/// Stars from all the goals (his `mStars`).
int milestoneStars(MilestoneContext c) => milestones.fold(0, (n, g) => n + g.starsFor(c));
