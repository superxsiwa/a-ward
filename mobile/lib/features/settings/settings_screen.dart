import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/case_files.dart';
import '../../data/progress_store.dart';
import '../../data/providers.dart';
import '../../game/case_import.dart';
import '../../l10n/generated/app_localizations.dart';

/// Sound, vibration, the cases (his JSON export and import, back to the standard cases) and
/// "reset progress", after his SettingsPage and CaseManagerPage.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).value ?? const GameSettings();
    final notifier = ref.read(settingsProvider.notifier);
    final caseSet = ref.watch(caseSetProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: Colors.white,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l.soundTitle),
                  subtitle: Text(l.soundSub),
                  value: settings.sound,
                  onChanged: (v) => notifier.set(settings.copyWith(sound: v)),
                ),
                SwitchListTile(
                  title: Text(l.hapticsTitle),
                  subtitle: Text(l.hapticsSub),
                  value: settings.haptics,
                  onChanged: (v) => notifier.set(settings.copyWith(haptics: v)),
                ),
              ],
            ),
          ),
          Card(
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    l.casesTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.sky700),
                  ),
                  subtitle: caseSet == null
                      ? null
                      : Text(
                          caseSet.imported
                              ? l.casesImported(caseSet.cases.length)
                              : l.casesShipped(caseSet.cases.length),
                        ),
                ),
                ListTile(
                  leading: const Icon(Icons.save_alt_rounded),
                  title: Text(l.exportCases),
                  onTap: () => _export(context, ref, l),
                ),
                ListTile(
                  leading: const Icon(Icons.file_open_outlined),
                  title: Text(l.importCases),
                  onTap: () => _import(context, ref, l),
                ),
                if (caseSet?.imported ?? false)
                  ListTile(
                    leading: const Icon(Icons.restore_rounded),
                    title: Text(l.resetCases),
                    onTap: () => _useBundled(context, ref, l),
                  ),
              ],
            ),
          ),
          Card(
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(l.about),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/about'),
                ),
                ListTile(
                  leading: const Icon(Icons.restart_alt_rounded, color: AppColors.danger),
                  title: Text(l.resetTitle, style: const TextStyle(color: AppColors.danger)),
                  onTap: () => _confirmReset(context, ref, l),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(
    BuildContext context,
    AppLocalizations l, {
    required String title,
    required String body,
    required String yes,
    bool danger = false,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
            FilledButton(
              style: danger ? FilledButton.styleFrom(backgroundColor: AppColors.danger) : null,
              onPressed: () => Navigator.pop(context, true),
              child: Text(yes),
            ),
          ],
        ),
      ) ==
      true;

  void _toast(BuildContext context, String text) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final ok = await _confirm(
      context,
      l,
      title: l.resetConfirmTitle,
      body: l.resetConfirmBody,
      yes: l.resetConfirm,
      danger: true,
    );
    if (!ok) return;
    await ref.read(progressProvider.notifier).reset();
    await ref.read(rosterProvider.notifier).reset();
    if (context.mounted) _toast(context, l.resetDone);
  }

  /// His export: every case in the ward, saved where the player chooses.
  Future<void> _export(BuildContext context, WidgetRef ref, AppLocalizations l) async {
    try {
      final text = await ref.read(caseSetProvider.notifier).exportText();
      final saved = await ref.read(caseFilesProvider).save(caseFileName(clock.now()), text);
      if (saved && context.mounted) _toast(context, l.exported);
    } on Exception {
      if (context.mounted) _toast(context, l.exportFailed);
    }
  }

  /// His import: a file of cases replaces the ward's, after the same checks as the shipped ones
  /// and the player's yes.
  Future<void> _import(BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final String? text;
    try {
      text = await ref.read(caseFilesProvider).pick();
    } on Exception {
      if (context.mounted) _toast(context, l.importReadError);
      return;
    }
    if (text == null || !context.mounted) return;
    final cases = ref.read(caseSetProvider.notifier);
    final result = await cases.read(text);
    if (!context.mounted) return;
    switch (result) {
      case CasesRejected(:final problems):
        const shown = 8;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l.importBadTitle),
            content: SingleChildScrollView(
              child: Text(
                [
                  ...problems.take(shown),
                  if (problems.length > shown) l.moreProblems(problems.length - shown),
                ].join('\n'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.close))],
          ),
        );
      case CasesRead():
        final ok = await _confirm(
          context,
          l,
          title: l.importConfirmTitle,
          body: l.importConfirmBody(result.cases.length),
          yes: l.importConfirm,
        );
        if (!ok) return;
        await cases.use(result);
        if (context.mounted) _toast(context, l.imported(result.cases.length));
    }
  }

  Future<void> _useBundled(BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final ok = await _confirm(
      context,
      l,
      title: l.resetCasesTitle,
      body: l.resetCasesBody,
      yes: l.resetCasesConfirm,
    );
    if (!ok) return;
    await ref.read(caseSetProvider.notifier).useBundled();
    if (context.mounted) _toast(context, l.resetCasesDone);
  }
}
