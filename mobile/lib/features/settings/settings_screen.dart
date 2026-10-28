import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/progress_store.dart';
import '../../l10n/generated/app_localizations.dart';

/// Sound, vibration and "reset progress", after his SettingsPage.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).value ?? const GameSettings();
    final notifier = ref.read(settingsProvider.notifier);
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

  Future<void> _confirmReset(BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.resetConfirmTitle),
        content: Text(l.resetConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.resetConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(progressProvider.notifier).reset();
    await ref.read(rosterProvider.notifier).reset();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.resetDone)));
    }
  }
}
