import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('th')];

  /// No description provided for @appTitle.
  ///
  /// In th, this message translates to:
  /// **'Critical Care'**
  String get appTitle;

  /// Ours: temporary phase-0 bed list; the ward screen replaces it in phase 1.
  ///
  /// In th, this message translates to:
  /// **'เลือกเตียง'**
  String get bedListTitle;

  /// Ours.
  ///
  /// In th, this message translates to:
  /// **'โหลดเคสไม่สำเร็จ'**
  String get casesLoadError;

  /// No description provided for @stepOf.
  ///
  /// In th, this message translates to:
  /// **'ขั้นที่ {step}/{total}'**
  String stepOf(int step, int total);

  /// No description provided for @stepDot.
  ///
  /// In th, this message translates to:
  /// **'ขั้นที่ {step}'**
  String stepDot(int step);

  /// No description provided for @liveStars.
  ///
  /// In th, this message translates to:
  /// **'ดาวที่ได้ตอนนี้ {stars} ดวง'**
  String liveStars(int stars);

  /// No description provided for @secondsShort.
  ///
  /// In th, this message translates to:
  /// **'{seconds}s'**
  String secondsShort(int seconds);

  /// No description provided for @reading.
  ///
  /// In th, this message translates to:
  /// **'📖 สาระความรู้'**
  String get reading;

  /// No description provided for @check.
  ///
  /// In th, this message translates to:
  /// **'ตรวจคำตอบ'**
  String get check;

  /// No description provided for @goOn.
  ///
  /// In th, this message translates to:
  /// **'ไปต่อ'**
  String get goOn;

  /// No description provided for @previous.
  ///
  /// In th, this message translates to:
  /// **'ย้อนกลับ'**
  String get previous;

  /// No description provided for @showAnswerGoOn.
  ///
  /// In th, this message translates to:
  /// **'💡 ดูเฉลย & ไปต่อ'**
  String get showAnswerGoOn;

  /// No description provided for @resetStep.
  ///
  /// In th, this message translates to:
  /// **'จัดใหม่'**
  String get resetStep;

  /// No description provided for @allStepsDone.
  ///
  /// In th, this message translates to:
  /// **'✓ ทำหัตถการครบทุกขั้นตอนแล้ว'**
  String get allStepsDone;

  /// No description provided for @leaveCase.
  ///
  /// In th, this message translates to:
  /// **'ออกจากเคส'**
  String get leaveCase;

  /// No description provided for @hintSequence.
  ///
  /// In th, this message translates to:
  /// **'แตะการ์ดเพื่อเติมช่องถัดไป · ลากเพื่อสลับตำแหน่ง · แตะการ์ดที่วางแล้วเพื่อเอาออก'**
  String get hintSequence;

  /// No description provided for @hintTrays.
  ///
  /// In th, this message translates to:
  /// **'แตะการ์ดแล้วแตะถาดที่ต้องการ · หรือกดค้างแล้วลากไปวาง · แตะการ์ดในถาดเพื่อเอาออก'**
  String get hintTrays;

  /// No description provided for @hintDropBox.
  ///
  /// In th, this message translates to:
  /// **'แตะหรือลากการ์ดที่ถูกต้องใส่กล่อง · แตะการ์ดในกล่องเพื่อเอาออก'**
  String get hintDropBox;

  /// No description provided for @poolEmpty.
  ///
  /// In th, this message translates to:
  /// **'วางครบทุกใบแล้ว 🎉'**
  String get poolEmpty;

  /// No description provided for @slotPlaceholder.
  ///
  /// In th, this message translates to:
  /// **'ลากการ์ดมาวางที่นี่'**
  String get slotPlaceholder;

  /// No description provided for @trayPlaceholder.
  ///
  /// In th, this message translates to:
  /// **'วางอุปกรณ์ในถาดนี้'**
  String get trayPlaceholder;

  /// No description provided for @dropBoxTitle.
  ///
  /// In th, this message translates to:
  /// **'กล่องปฏิบัติการพยาบาล'**
  String get dropBoxTitle;

  /// No description provided for @dropBoxPlaceholder.
  ///
  /// In th, this message translates to:
  /// **'วางการ์ดที่ถูกต้องที่นี่'**
  String get dropBoxPlaceholder;

  /// No description provided for @notReady.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่ครบ: {reason}'**
  String notReady(String reason);

  /// No description provided for @notReadyOption.
  ///
  /// In th, this message translates to:
  /// **'เลือกตัวเลือกอย่างน้อย 1 ข้อ'**
  String get notReadyOption;

  /// No description provided for @notReadySlots.
  ///
  /// In th, this message translates to:
  /// **'วางการ์ดให้ครบทุกช่อง'**
  String get notReadySlots;

  /// No description provided for @notReadyPool.
  ///
  /// In th, this message translates to:
  /// **'หยิบอุปกรณ์ลงถาดให้ครบทุกชิ้น'**
  String get notReadyPool;

  /// No description provided for @notReadyDropBox.
  ///
  /// In th, this message translates to:
  /// **'เลือกให้ครบ {count} ข้อ'**
  String notReadyDropBox(int count);

  /// No description provided for @errorWrongOption.
  ///
  /// In th, this message translates to:
  /// **'มีข้อที่ไม่ควรเลือกอยู่ (ข้อสีแดง)'**
  String get errorWrongOption;

  /// No description provided for @errorMissingOptions.
  ///
  /// In th, this message translates to:
  /// **'ยังเลือกไม่ครบทุกข้อที่ต้องตรวจสอบ'**
  String get errorMissingOptions;

  /// No description provided for @errorSequence.
  ///
  /// In th, this message translates to:
  /// **'ลำดับบางข้อยังไม่ถูกต้อง (การ์ดสีแดงอยู่ผิดตำแหน่ง)'**
  String get errorSequence;

  /// No description provided for @errorTrayOrder.
  ///
  /// In th, this message translates to:
  /// **'ลำดับใน “{tray}” ยังไม่ถูกต้อง'**
  String errorTrayOrder(String tray);

  /// No description provided for @errorTrayWrong.
  ///
  /// In th, this message translates to:
  /// **'ใน “{tray}” มีอุปกรณ์อยู่ผิดถาด'**
  String errorTrayWrong(String tray);

  /// No description provided for @errorUnsafe.
  ///
  /// In th, this message translates to:
  /// **'มีการพยาบาลที่ไม่ปลอดภัยปนอยู่ (การ์ดสีแดง) ลองเอาออกแล้วเลือกใหม่'**
  String get errorUnsafe;

  /// No description provided for @errorTimeout.
  ///
  /// In th, this message translates to:
  /// **'จัดเตรียมอุปกรณ์ไม่ทันในเวลา 20 วินาที'**
  String get errorTimeout;

  /// No description provided for @praise1.
  ///
  /// In th, this message translates to:
  /// **'ยอดเยี่ยม!'**
  String get praise1;

  /// No description provided for @praise2.
  ///
  /// In th, this message translates to:
  /// **'เก่งมาก!'**
  String get praise2;

  /// No description provided for @praise3.
  ///
  /// In th, this message translates to:
  /// **'เป๊ะเลย!'**
  String get praise3;

  /// No description provided for @praise4.
  ///
  /// In th, this message translates to:
  /// **'สุดยอด!'**
  String get praise4;

  /// No description provided for @passedSub.
  ///
  /// In th, this message translates to:
  /// **'ผ่านขั้นตอนนี้แล้ว ถูกต้องตามหลักความปลอดภัย'**
  String get passedSub;

  /// No description provided for @failedTitle.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่ถูกน้า (ครั้งที่ {strike}/3)'**
  String failedTitle(int strike);

  /// No description provided for @failedSub.
  ///
  /// In th, this message translates to:
  /// **'ลองดูจุดที่ขึ้นสีแดงอีกครั้ง'**
  String get failedSub;

  /// No description provided for @mercyTitle.
  ///
  /// In th, this message translates to:
  /// **'พยายามได้ดีมากแล้วจ้า!'**
  String get mercyTitle;

  /// No description provided for @mercySub.
  ///
  /// In th, this message translates to:
  /// **'ผิดครบ 3 ครั้งแล้ว สามารถดูเฉลยแล้วไปต่อได้เลยนะ'**
  String get mercySub;

  /// No description provided for @timeoutTitle.
  ///
  /// In th, this message translates to:
  /// **'หมดเวลา 20 วินาที! (ครั้งที่ {strike}/3)'**
  String timeoutTitle(int strike);

  /// No description provided for @timeoutSub.
  ///
  /// In th, this message translates to:
  /// **'การจัดเตรียมอุปกรณ์ในภาวะฉุกเฉินต้องรวดเร็วและแม่นยำ ลองใหม่อีกครั้งนะ'**
  String get timeoutSub;

  /// No description provided for @timeoutMercyTitle.
  ///
  /// In th, this message translates to:
  /// **'หมดเวลา 20 วินาที!'**
  String get timeoutMercyTitle;

  /// No description provided for @timeoutMercySub.
  ///
  /// In th, this message translates to:
  /// **'ผิด/หมดเวลาครบ 3 ครั้งแล้ว สามารถดูเฉลยแล้วไปต่อได้เลยนะ'**
  String get timeoutMercySub;

  /// No description provided for @answerTitle.
  ///
  /// In th, this message translates to:
  /// **'💡 เฉลยคำตอบที่ถูกต้อง'**
  String get answerTitle;

  /// No description provided for @answerSub.
  ///
  /// In th, this message translates to:
  /// **'ระบบได้จัดเรียงคำตอบที่ถูกต้องให้แล้ว ศึกษาแล้วกดไปต่อได้เลยจ้า'**
  String get answerSub;

  /// No description provided for @tryAgain.
  ///
  /// In th, this message translates to:
  /// **'ลองอีกครั้ง'**
  String get tryAgain;

  /// No description provided for @tryAgainTimed.
  ///
  /// In th, this message translates to:
  /// **'ลองอีกครั้ง (จับเวลา 20 วิ)'**
  String get tryAgainTimed;

  /// No description provided for @tryAgainShort.
  ///
  /// In th, this message translates to:
  /// **'ลองอีกที'**
  String get tryAgainShort;

  /// No description provided for @caseDone.
  ///
  /// In th, this message translates to:
  /// **'เสร็จสิ้นเคส!'**
  String get caseDone;

  /// No description provided for @caseDonePerfect.
  ///
  /// In th, this message translates to:
  /// **'สุดยอด! ตอบเป๊ะทุกข้อ ได้ครบ 3 ดาวเลย'**
  String get caseDonePerfect;

  /// No description provided for @caseDoneReplay.
  ///
  /// In th, this message translates to:
  /// **'ผ่านเคสสำเร็จ! ลองเล่นซ้ำเพื่อเก็บให้ครบ 3 ดาวนะ'**
  String get caseDoneReplay;

  /// No description provided for @nextBed.
  ///
  /// In th, this message translates to:
  /// **'เตียงถัดไป ▶'**
  String get nextBed;

  /// No description provided for @backToWard.
  ///
  /// In th, this message translates to:
  /// **'กลับวอร์ด'**
  String get backToWard;

  /// No description provided for @replayForStars.
  ///
  /// In th, this message translates to:
  /// **'เล่นซ้ำเก็บ 3 ดาว'**
  String get replayForStars;

  /// No description provided for @leaveTitle.
  ///
  /// In th, this message translates to:
  /// **'ออกจากเคสนี้?'**
  String get leaveTitle;

  /// No description provided for @leaveBody.
  ///
  /// In th, this message translates to:
  /// **'ความคืบหน้าในเคสนี้จะหายไป ต้องเริ่มใหม่ตั้งแต่ขั้นแรก'**
  String get leaveBody;

  /// No description provided for @cancel.
  ///
  /// In th, this message translates to:
  /// **'ยกเลิก'**
  String get cancel;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
