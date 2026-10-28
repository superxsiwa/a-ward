import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/theme.dart';
import '../../l10n/generated/app_localizations.dart';

/// The commit a build came from, passed with `--dart-define=BUILD_ID=<sha>`; testers quote it.
const buildId = String.fromEnvironment('BUILD_ID', defaultValue: 'dev');

final _packageInfoProvider = FutureProvider((ref) => PackageInfo.fromPlatform());

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final version = ref.watch(_packageInfoProvider).value?.version ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(l.about)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l.appTitle,
            style: const TextStyle(
              fontFamily: displayFont,
              fontWeight: FontWeight.w600,
              fontSize: 24,
            ),
          ),
          Text(l.aboutVersion(version, buildId), style: const TextStyle(color: AppColors.ink3)),
          const SizedBox(height: 16),
          const TrainingNotice(),
          const SizedBox(height: 16),
          for (final line in [l.aboutCases, l.aboutClinical, l.aboutBuiltBy, l.aboutOffline])
            Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(line)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: l.appTitle,
              applicationVersion: version,
            ),
            child: Text(l.aboutLicenses),
          ),
        ],
      ),
    );
  }
}

/// "For training only": shown once on first launch and kept on the About page.
class TrainingNotice extends StatelessWidget {
  const TrainingNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.bubbleBorder, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚠️ ${l.noticeTitle}',
            style: const TextStyle(
              fontFamily: displayFont,
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: AppColors.readingInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(l.noticeBody, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}
