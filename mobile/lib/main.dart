import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    for (final (font, file) in [('Prompt', 'OFL-Prompt.txt'), ('Mitr', 'OFL-Mitr.txt')]) {
      yield LicenseEntryWithLineBreaks([font], await rootBundle.loadString('assets/fonts/$file'));
    }
  });
  runApp(const ProviderScope(child: CriticalCareApp()));
}
