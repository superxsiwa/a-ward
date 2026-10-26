import { BedProgressRecord, PlayerStats } from '../types/game';

export const RANKS = [
  'นักศึกษาพยาบาลฝึกหัด',
  'พยาบาลฝึกงาน',
  'พยาบาลน้องใหม่ CCU',
  'พยาบาล CCU ฝีมือดี',
  'พยาบาลชำนาญการ',
  'หัวหน้าเวร CCU',
  'พยาบาล CCU ดาวเด่น',
  'ผู้เชี่ยวชาญ CCU',
  'ตำนานแห่งหอผู้ป่วยวิกฤต',
];

export const THAI_MONTHS = [
  'มกราคม',
  'กุมภาพันธ์',
  'มีนาคม',
  'เมษายน',
  'พฤษภาคม',
  'มิถุนายน',
  'กรกฎาคม',
  'สิงหาคม',
  'กันยายน',
  'ตุลาคม',
  'พฤศจิกายน',
  'ธันวาคม',
];

export interface ShiftDefinition {
  id: 'morning' | 'afternoon' | 'night';
  name: string;
  badgeClass: string;
  pillClass: string;
  time: string;
  icon: string;
  chargeNurse: string;
  desc: string;
  bedIndices: number[];
}

export const SHIFTS: ShiftDefinition[] = [
  {
    id: 'morning',
    name: 'เวรเช้า (Morning Shift)',
    badgeClass: 'badge-morning',
    pillClass: 's-morning',
    time: '07:00 – 15:00 น.',
    icon: '🌅',
    chargeNurse: 'พว. ณิชาภา (RN)',
    desc: 'รับส่งเวรเช้า ตรวจเยี่ยมคนไข้ post-catheterization และเตรียมหัตถการใส่สาย CVC',
    bedIndices: [0, 1],
  },
  {
    id: 'afternoon',
    name: 'เวรบ่าย (Afternoon Shift)',
    badgeClass: 'badge-afternoon',
    pillClass: 's-afternoon',
    time: '15:00 – 23:00 น.',
    icon: '☀️',
    chargeNurse: 'พว. กานดา (RN)',
    desc: 'ดูแลเคสวิกฤต ETT, ใส่ Temporary Pacemaker และบริหารยา Levophed ทางหลอดเลือด',
    bedIndices: [2, 3, 4],
  },
  {
    id: 'night',
    name: 'เวรดึก (Night Shift)',
    badgeClass: 'badge-night',
    pillClass: 's-night',
    time: '23:00 – 07:00 น.',
    icon: '🌙',
    chargeNurse: 'พว. ปวีณา (RN)',
    desc: 'เฝ้าระวัง Pericardial Tamponade, ติดตาม Cardioversion และรับมือภาวะฉุกเฉิน RP Bleed',
    bedIndices: [5, 6, 7],
  },
];

export const BED_STAY_INFO: Record<number, { stay: string; note: string }> = {
  1: { stay: 'วันที่ 2 ใน CCU', note: 'Post-PCI วันที่ 2 เตรียมถอดสาย Femoral Sheath' },
  2: { stay: 'วันที่ 1 ใน CCU', note: 'เพิ่ง admit จาก ER เมื่อคืน อาการ Septic Shock' },
  3: { stay: 'วันที่ 3 ใน CCU', note: 'Pulmonary Edema เหนื่อยหอบวิกฤต เตรียม Intubation' },
  4: { stay: 'วันที่ 2 ใน CCU', note: 'Mobitz II progression สู่ CHB ต้องใส่ TPM ด่วน' },
  5: { stay: 'วันที่ 4 ใน CCU', note: 'Cardiogenic Shock วันที่ 4 ปรับ Levophed' },
  6: { stay: 'วันที่ 5 ใน CCU', note: 'Post Pericardiocentesis วันที่ 5 เฝ้าระวัง Tamponade' },
  7: { stay: 'วันที่ 1 ใน CCU', note: 'VT with pulse ฉุกเฉิน เตรียมทำ Cardioversion' },
  8: { stay: 'วันที่ 2 ใน CCU', note: 'ปวดหลัง BP ดรอปหลังสวนหัวใจ สงสัย RP Bleed' },
};

export const EQUIPMENT_ICONS = [
  { label: '(ไม่มีรูปอุปกรณ์)', value: '' },
  { label: '🩺 หูฟังแพทย์ (Stethoscope)', value: './assets/equipment/stethoscope.png' },
  { label: '💉 เข็มฉีดยา (Syringe)', value: './assets/equipment/syringe.png' },
  { label: '✂️ กรรไกร/คีมคีบ (Scissors/Forceps)', value: './assets/equipment/scissors_forceps.png' },
  { label: '🧰 กล่องชุดทำแผล (First Aid Kit)', value: './assets/equipment/first_aid_kit.png' },
  { label: '💧 ถุงน้ำเกลือ/สารน้ำ (IV Bag)', value: './assets/equipment/iv_bag.png' },
  { label: '💊 ขวดยา (Medicine Bottle)', value: './assets/equipment/medicine_bottle.png' },
  { label: '📟 เครื่องวัดความดัน (BP Monitor)', value: './assets/equipment/bp_monitor.png' },
  { label: '📈 มอนิเตอร์คลื่นหัวใจ (ECG Monitor)', value: './assets/equipment/ecg_monitor.png' },
  { label: '🫁 หน้ากากออกซิเจน (Oxygen Mask)', value: './assets/equipment/oxygen_mask.png' },
  { label: '🔦 ไฟฉายส่องคอ/ม่านตา (Penlight)', value: './assets/equipment/penlight.png' },
  { label: '👆 เครื่องวัดออกซิเจนปลายนิ้ว (Pulse Oximeter)', value: './assets/equipment/pulse_oximeter.png' },
  { label: '📋 แฟ้มเวชระเบียน (Medical Chart)', value: './assets/equipment/medical_chart.png' },
  { label: '🌡️ เทอร์โมมิเตอร์ดิจิทัล', value: './assets/equipment/thermometer_digital.png' },
  { label: '🧪 ท่อ/เทอร์โมมิเตอร์แก้ว', value: './assets/equipment/thermometer_glass.png' },
  { label: '🔨 ค้อนเคาะรีเฟล็กซ์', value: './assets/equipment/reflex_hammer.png' },
  { label: '👂 เครื่องส่องหู (Otoscope)', value: './assets/equipment/otoscope.png' },
];

export interface MilestoneContextData {
  playerStats: PlayerStats;
  progress: Record<number, BedProgressRecord>;
  rosterDaysProgress: Record<string, { passed: boolean }>;
  totalStars: number;
  passedCount: number;
}

export interface MilestoneGoalDef {
  id: string;
  title: string;
  icon: string;
  unit: string;
  tiers: [number, number, number];
  desc: string;
  getValue: (ctx: MilestoneContextData) => number;
  formatVal?: (val: number, ctx: MilestoneContextData) => string;
}

export function getMilestoneStars(goal: MilestoneGoalDef, ctx: MilestoneContextData): number {
  const val = goal.getValue(ctx);
  if (val >= goal.tiers[2]) return 3;
  if (val >= goal.tiers[1]) return 2;
  if (val >= goal.tiers[0]) return 1;
  return 0;
}

export const MILESTONE_GOALS: MilestoneGoalDef[] = [
  {
    id: 'cases',
    title: 'ยอดหัตถการที่สำเร็จ',
    icon: '💉',
    unit: 'ครั้ง',
    tiers: [5, 15, 30],
    getValue: (c) => c.playerStats.totalCompletedCases,
    desc: 'ทำหัตถการการพยาบาลผู้ป่วย CCU สำเร็จตามจำนวนครั้ง',
  },
  {
    id: 'hours',
    title: 'ชั่วโมงบินเวร CCU',
    icon: '⏱️',
    unit: 'ชั่วโมง',
    tiers: [0.5, 1.5, 3.0],
    getValue: (c) => +(c.playerStats.totalPlaySeconds / 3600).toFixed(1),
    formatVal: (v, c) => `${v} ชม. (${Math.floor(c.playerStats.totalPlaySeconds / 60)} นาที)`,
    desc: 'สะสมเวลาปฏิบัติการพยาบาลและเรียนรู้ในหอผู้ป่วยวิกฤต',
  },
  {
    id: 'perfect',
    title: 'ความแม่นยำระดับ 3 ดาว',
    icon: '🎯',
    unit: 'เคส',
    tiers: [3, 8, 16],
    getValue: (c) => c.playerStats.perfectCases,
    desc: 'ทำเคสได้ถูกต้อง 100% ไม่มีข้อผิดพลาดจนได้ 3 ดาวเต็ม',
  },
  {
    id: 'shifts',
    title: 'ผ่านเวรประจำวันครบ',
    icon: '📋',
    unit: 'เวร',
    tiers: [2, 7, 14],
    getValue: (c) =>
      Math.max(
        c.playerStats.shiftsCompleted || 0,
        Object.values(c.rosterDaysProgress).filter((p) => p && p.passed).length
      ),
    desc: 'ขึ้นเวรตามตารางและดูแลคนไข้ครบทุกเตียงประจำเวรนั้น',
  },
  {
    id: 'beds_unlocked',
    title: 'พิชิตเตียงในวอร์ด CCU',
    icon: '🛏️',
    unit: 'เตียง',
    tiers: [2, 5, 8],
    getValue: (c) => c.passedCount,
    desc: 'ผ่านเคสหัตถการประจำเตียงต่างๆ ในวอร์ดครบตามจำนวน',
  },
  {
    id: 'case_sheath',
    title: 'ผู้เชี่ยวชาญ Femoral Sheath',
    icon: '🩹',
    unit: 'ดาว',
    tiers: [1, 2, 3],
    getValue: (c) => c.progress[1]?.stars || 0,
    desc: 'เตียง 01: ถอดสายสวนหลอดเลือดแดงขาหนีบและกดหยุดเลือดอย่างปลอดภัย',
  },
  {
    id: 'case_cvc',
    title: 'หัตถการสายสวนดำใหญ่ (CVC)',
    icon: '🩸',
    unit: 'ดาว',
    tiers: [1, 2, 3],
    getValue: (c) => c.progress[2]?.stars || 0,
    desc: 'เตียง 02: เตรียมผู้ป่วยและจัดถาดปลอดเชื้อช่วยแพทย์ใส่สาย CVC',
  },
  {
    id: 'case_ett',
    title: 'กู้ทางเดินหายใจฉุกเฉิน (ETT)',
    icon: '🫁',
    unit: 'ดาว',
    tiers: [1, 2, 3],
    getValue: (c) => c.progress[3]?.stars || 0,
    desc: 'เตียง 03: เตรียมอุปกรณ์ท่อช่วยหายใจและดูดเสมหะเคส Acute Pulmonary Edema',
  },
  {
    id: 'case_tpm',
    title: 'กระตุ้นหัวใจชั่วคราว (TPM)',
    icon: '⚡',
    unit: 'ดาว',
    tiers: [1, 2, 3],
    getValue: (c) => c.progress[4]?.stars || 0,
    desc: 'เตียง 04: ปรับ Rate/Output เครื่อง TPM ช่วยชีวิต Complete Heart Block',
  },
  {
    id: 'case_levo',
    title: 'บริหารยาวาสโซเพรสเซอร์ (Levophed)',
    icon: '🧪',
    unit: 'ดาว',
    tiers: [1, 2, 3],
    getValue: (c) => c.progress[5]?.stars || 0,
    desc: 'เตียง 05: ไตเตรทยากู้ความดัน Titration ยาหลอดเลือดดำส่วนกลาง',
  },
  {
    id: 'case_drain',
    title: 'ระบายน้ำหุ้มหัวใจ (Pericardial)',
    icon: '🫀',
    unit: 'ดาว',
    tiers: [1, 2, 3],
    getValue: (c) => c.progress[6]?.stars || 0,
    desc: 'เตียง 06: ตรวจสอบ Three-way stopcock และปริมาณสิ่งคัดหลั่งป้องกัน Tamponade',
  },
  {
    id: 'case_cardioversion',
    title: 'ช็อกไฟฟ้ากู้ชีพ (Cardioversion)',
    icon: '💓',
    unit: 'ดาว',
    tiers: [1, 2, 3],
    getValue: (c) => c.progress[7]?.stars || 0,
    desc: 'เตียง 07: เปิดโหมด Sync ชาร์จพลังงาน Defibrillator เคสหัวใจเต้นผิดจังหวะ',
  },
  {
    id: 'case_rp_bleed',
    title: 'รับมือภาวะช็อกเลือดออกหลังช่องท้อง',
    icon: '🚨',
    unit: 'ดาว',
    tiers: [1, 2, 3],
    getValue: (c) => c.progress[8]?.stars || 0,
    desc: 'เตียง 08: วินิจฉัย RP Bleed และเปิดเส้นเลือดให้สารน้ำกู้ภาวะ Hypovolemic Shock',
  },
  {
    id: 'tray_master',
    title: 'ปรมาจารย์จัดถาดเครื่องมือ',
    icon: '🧰',
    unit: 'ชิ้น',
    tiers: [15, 45, 90],
    getValue: (c) => c.playerStats.trayItemsSorted,
    desc: 'หยิบจัดอุปกรณ์ปลอดเชื้อลงถาดหัตถการถูกต้องแม่นยำ',
  },
  {
    id: 'zero_mistakes',
    title: 'ก้าวไร้ที่ติ (Flawless Steps)',
    icon: '🛡️',
    unit: 'ขั้นตอน',
    tiers: [10, 30, 60],
    getValue: (c) => c.playerStats.stepsWithoutMistake,
    desc: 'ผ่านขั้นตอนหัตถการโดยไม่เกิดข้อผิดพลาดในการเลือกคำตอบ',
  },
  {
    id: 'emergency_hero',
    title: 'ผู้พิชิตเคสวิกฤตฉุกเฉิน',
    icon: '🚑',
    unit: 'ครั้ง',
    tiers: [3, 8, 15],
    getValue: (c) => c.playerStats.emergencyCasesDone,
    desc: 'ผ่านเคสที่มีสถานะวิกฤตสัญญาณชีพออดเตือน (Alarm & Critical cases)',
  },
  {
    id: 'continuous_learning',
    title: 'นักทบทวนฝึกฝนซ้ำ',
    icon: '🔁',
    unit: 'ครั้ง',
    tiers: [2, 6, 12],
    getValue: (c) => c.playerStats.replayedCases,
    desc: 'เข้าเล่นซ้ำเพื่อทบทวนทักษะและยกระดับความแม่นยำ',
  },
  {
    id: 'star_collector',
    title: 'นักสะสมดวงดาว CCU',
    icon: '⭐',
    unit: 'ดาว',
    tiers: [8, 16, 24],
    getValue: (c) => c.totalStars,
    desc: 'สะสมดาวความสำเร็จจากการดูแลผู้ป่วยทั่วทั้งวอร์ด',
  },
  {
    id: 'safety_champion',
    title: 'แชมป์ความปลอดภัยผู้ป่วย (Patient Safety)',
    icon: '🏥',
    unit: 'เคส',
    tiers: [4, 8, 12],
    getValue: (c) =>
      Math.min(c.playerStats.totalCompletedCases, Math.floor(c.playerStats.stepsWithoutMistake / 4)),
    desc: 'ปฏิบัติตามมาตรฐานความปลอดภัยสากล 2 Identify & Sterile Technique',
  },
  {
    id: 'ccu_legend',
    title: 'ตำนานพยาบาลผู้พิทักษ์หัวใจ',
    icon: '👑',
    unit: 'เป้าหมาย',
    tiers: [5, 10, 18],
    getValue: (c) =>
      MILESTONE_GOALS.filter((g) => g.id !== 'ccu_legend' && getMilestoneStars(g, c) >= 1).length,
    desc: 'พิชิตเป้าหมาย Milestones อื่นๆ ในหอผู้ป่วยวิกฤตหัวใจ',
  },
];

