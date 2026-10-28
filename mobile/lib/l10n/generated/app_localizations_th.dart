// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'Critical Care';

  @override
  String get casesLoadError => 'โหลดเคสไม่สำเร็จ';

  @override
  String stepOf(int step, int total) {
    return 'ขั้นที่ $step/$total';
  }

  @override
  String stepDot(int step) {
    return 'ขั้นที่ $step';
  }

  @override
  String liveStars(int stars) {
    return 'ดาวที่ได้ตอนนี้ $stars ดวง';
  }

  @override
  String secondsShort(int seconds) {
    return '${seconds}s';
  }

  @override
  String get reading => '📖 สาระความรู้';

  @override
  String get check => 'ตรวจคำตอบ';

  @override
  String get goOn => 'ไปต่อ';

  @override
  String get previous => 'ย้อนกลับ';

  @override
  String get showAnswerGoOn => '💡 ดูเฉลย & ไปต่อ';

  @override
  String get resetStep => 'จัดใหม่';

  @override
  String get allStepsDone => '✓ ทำหัตถการครบทุกขั้นตอนแล้ว';

  @override
  String get leaveCase => 'ออกจากเคส';

  @override
  String get hintSequence =>
      'แตะการ์ดเพื่อเติมช่องถัดไป · ลากเพื่อสลับตำแหน่ง · แตะการ์ดที่วางแล้วเพื่อเอาออก';

  @override
  String get hintTrays =>
      'แตะการ์ดแล้วแตะถาดที่ต้องการ · หรือกดค้างแล้วลากไปวาง · แตะการ์ดในถาดเพื่อเอาออก';

  @override
  String get hintDropBox => 'แตะหรือลากการ์ดที่ถูกต้องใส่กล่อง · แตะการ์ดในกล่องเพื่อเอาออก';

  @override
  String get poolEmpty => 'วางครบทุกใบแล้ว 🎉';

  @override
  String get slotPlaceholder => 'ลากการ์ดมาวางที่นี่';

  @override
  String get trayPlaceholder => 'วางอุปกรณ์ในถาดนี้';

  @override
  String get dropBoxTitle => 'กล่องปฏิบัติการพยาบาล';

  @override
  String get dropBoxPlaceholder => 'วางการ์ดที่ถูกต้องที่นี่';

  @override
  String notReady(String reason) {
    return 'ยังไม่ครบ: $reason';
  }

  @override
  String get notReadyOption => 'เลือกตัวเลือกอย่างน้อย 1 ข้อ';

  @override
  String get notReadySlots => 'วางการ์ดให้ครบทุกช่อง';

  @override
  String get notReadyPool => 'หยิบอุปกรณ์ลงถาดให้ครบทุกชิ้น';

  @override
  String notReadyDropBox(int count) {
    return 'เลือกให้ครบ $count ข้อ';
  }

  @override
  String get errorWrongOption => 'มีข้อที่ไม่ควรเลือกอยู่ (ข้อสีแดง)';

  @override
  String get errorMissingOptions => 'ยังเลือกไม่ครบทุกข้อที่ต้องตรวจสอบ';

  @override
  String get errorSequence => 'ลำดับบางข้อยังไม่ถูกต้อง (การ์ดสีแดงอยู่ผิดตำแหน่ง)';

  @override
  String errorTrayOrder(String tray) {
    return 'ลำดับใน “$tray” ยังไม่ถูกต้อง';
  }

  @override
  String errorTrayWrong(String tray) {
    return 'ใน “$tray” มีอุปกรณ์อยู่ผิดถาด';
  }

  @override
  String get errorUnsafe => 'มีการพยาบาลที่ไม่ปลอดภัยปนอยู่ (การ์ดสีแดง) ลองเอาออกแล้วเลือกใหม่';

  @override
  String get errorTimeout => 'จัดเตรียมอุปกรณ์ไม่ทันในเวลา 20 วินาที';

  @override
  String get praise1 => 'ยอดเยี่ยม!';

  @override
  String get praise2 => 'เก่งมาก!';

  @override
  String get praise3 => 'เป๊ะเลย!';

  @override
  String get praise4 => 'สุดยอด!';

  @override
  String get passedSub => 'ผ่านขั้นตอนนี้แล้ว ถูกต้องตามหลักความปลอดภัย';

  @override
  String failedTitle(int strike) {
    return 'ยังไม่ถูกน้า (ครั้งที่ $strike/3)';
  }

  @override
  String get failedSub => 'ลองดูจุดที่ขึ้นสีแดงอีกครั้ง';

  @override
  String get mercyTitle => 'พยายามได้ดีมากแล้วจ้า!';

  @override
  String get mercySub => 'ผิดครบ 3 ครั้งแล้ว สามารถดูเฉลยแล้วไปต่อได้เลยนะ';

  @override
  String timeoutTitle(int strike) {
    return 'หมดเวลา 20 วินาที! (ครั้งที่ $strike/3)';
  }

  @override
  String get timeoutSub => 'การจัดเตรียมอุปกรณ์ในภาวะฉุกเฉินต้องรวดเร็วและแม่นยำ ลองใหม่อีกครั้งนะ';

  @override
  String get timeoutMercyTitle => 'หมดเวลา 20 วินาที!';

  @override
  String get timeoutMercySub => 'ผิด/หมดเวลาครบ 3 ครั้งแล้ว สามารถดูเฉลยแล้วไปต่อได้เลยนะ';

  @override
  String get answerTitle => '💡 เฉลยคำตอบที่ถูกต้อง';

  @override
  String get answerSub => 'ระบบได้จัดเรียงคำตอบที่ถูกต้องให้แล้ว ศึกษาแล้วกดไปต่อได้เลยจ้า';

  @override
  String get tryAgain => 'ลองอีกครั้ง';

  @override
  String get tryAgainTimed => 'ลองอีกครั้ง (จับเวลา 20 วิ)';

  @override
  String get tryAgainShort => 'ลองอีกที';

  @override
  String get caseDone => 'เสร็จสิ้นเคส!';

  @override
  String get caseDonePerfect => 'สุดยอด! ตอบเป๊ะทุกข้อ ได้ครบ 3 ดาวเลย';

  @override
  String get caseDoneReplay => 'ผ่านเคสสำเร็จ! ลองเล่นซ้ำเพื่อเก็บให้ครบ 3 ดาวนะ';

  @override
  String get nextBed => 'เตียงถัดไป ▶';

  @override
  String get backToWard => 'กลับวอร์ด';

  @override
  String get replayForStars => 'เล่นซ้ำเก็บ 3 ดาว';

  @override
  String get leaveTitle => 'ออกจากเคสนี้?';

  @override
  String get leaveBody => 'ความคืบหน้าในเคสนี้จะหายไป ต้องเริ่มใหม่ตั้งแต่ขั้นแรก';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String wardTitle(int count) {
    return 'วอร์ดหัวใจ $count เตียง';
  }

  @override
  String get wardHint => 'แตะที่เตียงเพื่อเริ่มทำการพยาบาลและหัตถการ';

  @override
  String get startNow => 'เริ่มเลย';

  @override
  String get continuePlay => 'เล่นต่อ';

  @override
  String get bedPassed => 'ผ่านแล้ว';

  @override
  String get nurseStation => 'เคาน์เตอร์พยาบาล';

  @override
  String passedOf(int passed, int total) {
    return 'ผ่านแล้ว $passed/$total เตียง';
  }

  @override
  String get caseSheets => '📖 ชีทเฉลยเคส';

  @override
  String totalStars(int stars, int max) {
    return 'ดาวทั้งหมด $stars/$max';
  }

  @override
  String levelRank(int level, String rank) {
    return 'Lv.$level · $rank';
  }

  @override
  String caseDoneGained(int gained) {
    return 'ผ่านเคสสำเร็จ! ลองเล่นซ้ำเพื่อเก็บให้ครบ 3 ดาวนะ (ได้ดาวเพิ่ม +$gained)';
  }

  @override
  String levelUp(int level, String rank) {
    return '⬆️ เลื่อนระดับ! Lv.$level · $rank';
  }

  @override
  String get about => 'เกี่ยวกับ';

  @override
  String get sheetsTitle => 'ชีทเฉลยเคส';

  @override
  String get sheetsIntro =>
      'ทุกขั้นตอนพร้อมคำตอบที่ถูกต้อง สำหรับผู้ตรวจเนื้อหาทางคลินิกและอาจารย์';

  @override
  String sheetTitle(String bedCode) {
    return 'ชีทเฉลย $bedCode';
  }

  @override
  String get sheetCorrect => 'ถูก';

  @override
  String get sheetWrong => 'ไม่ควรเลือก';

  @override
  String get sheetOrder => 'ลำดับที่ถูกต้อง';

  @override
  String get sheetSafe => 'ควรทำ';

  @override
  String get sheetUnsafe => 'ไม่ควรทำ';

  @override
  String get sheetInOrder => 'เรียงตามลำดับ';

  @override
  String get sheetAnyOrder => 'ไม่ต้องเรียงลำดับ';

  @override
  String get sheetDoctor => 'แพทย์';

  @override
  String get sheetNote => 'บันทึกทางคลินิก';

  @override
  String get noticeTitle => 'สำหรับการฝึกเท่านั้น';

  @override
  String get noticeBody =>
      'เกมนี้ใช้ฝึกทักษะการพยาบาลผู้ป่วยวิกฤตเท่านั้น ไม่ใช่แนวทางเวชปฏิบัติ และห้ามใช้ประกอบการตัดสินใจดูแลผู้ป่วยจริง เนื้อหาทางคลินิกอยู่ระหว่างการตรวจทาน';

  @override
  String get noticeOk => 'เข้าใจแล้ว';

  @override
  String aboutVersion(String version, String build) {
    return 'เวอร์ชัน $version · build $build';
  }

  @override
  String get aboutCases => 'เคสและการออกแบบเกม: superxsiwa (A-WARD CCU)';

  @override
  String get aboutClinical => 'ตรวจทานเนื้อหาทางคลินิก: พยาบาลวิชาชีพ (อยู่ระหว่างตรวจทาน)';

  @override
  String get aboutBuiltBy => 'พัฒนาแอป: ColabsCraft';

  @override
  String get aboutOffline =>
      'ทำงานออฟไลน์ ไม่ส่งข้อมูลใดๆ ออกจากเครื่อง ความก้าวหน้าเก็บไว้ในเครื่องนี้เท่านั้น';

  @override
  String get aboutLicenses => 'สัญญาอนุญาตโอเพนซอร์ส';
}
