import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/providers.dart';
import '../../game/case_model.dart';
import '../../l10n/generated/app_localizations.dart';

/// Phase 0 entry point: the 8 bundled beds in a list. Phase 1 replaces it with the ward and the
/// shift roster.
class BedListScreen extends ConsumerWidget {
  const BedListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cases = ref.watch(bundledCasesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.bedListTitle)),
      body: switch (cases) {
        AsyncData(:final value) => ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: value.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) =>
              _BedTile(bedCase: value[i], onTap: () => context.push('/bed/${value[i].bedNum}')),
        ),
        AsyncError() => Center(child: Text(l.casesLoadError)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _BedTile extends StatelessWidget {
  const _BedTile({required this.bedCase, required this.onTap});

  final BedCase bedCase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (bedCase.status) {
      CaseStatus.stable => AppColors.success,
      CaseStatus.alert => AppColors.gold,
      CaseStatus.critical => AppColors.danger,
    };
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.cardBorder, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.sky100,
                child: Text(
                  bedCase.bedNum.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontFamily: displayFont,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: AppColors.sky700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bedCase.caseTitle,
                      style: const TextStyle(
                        fontFamily: displayFont,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${bedCase.dxBadge} · ${bedCase.patientName}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.ink2),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          bedCase.statusText,
                          style: TextStyle(fontSize: 12, color: statusColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.ink3),
            ],
          ),
        ),
      ),
    );
  }
}
