import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../l10n/generated/app_localizations.dart';
import 'theme.dart';

/// The column width of the tab screens on wide screens (the bar lines up with it).
const contentMaxWidth = 1000.0;

/// The space on each side of the centred column at [width].
double contentInset(double width) =>
    width > contentMaxWidth + 24 ? (width - contentMaxWidth - 24) / 2 : 0.0;

/// His top bar on the tab screens: the app, the player's level and rank with his EXP bar (the
/// stars towards the next level), and the star count.
class PlayerBar extends ConsumerWidget implements PreferredSizeWidget {
  const PlayerBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  /// Room for three lines (title, level, EXP) at larger phone text sizes.
  static const _height = kToolbarHeight + 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final progress = ref.watch(wardProgressProvider);
    final beds = ref.watch(casesProvider).value?.length ?? 8;
    final inset = contentInset(MediaQuery.sizeOf(context).width);
    final max = beds * 3;
    final stars = progress.totalStars;
    // His `xp`: one level per 3 stars, full once every bed has 3.
    final exp = max > 0 && stars >= max ? 1.0 : (stars % 3) / 3;
    return AppBar(
      toolbarHeight: _height,
      // On wide screens the title and the star count line up with the centred column.
      titleSpacing: 16 + inset,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.appTitle),
          Text(
            l.levelRank(progress.level, progress.rank),
            style: const TextStyle(fontFamily: bodyFont, fontSize: 13.5, color: AppColors.ink2),
          ),
          const SizedBox(height: 3),
          Semantics(
            label: l.expBar((exp * 100).round()),
            excludeSemantics: true,
            child: SizedBox(
              width: 150,
              height: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: exp,
                  backgroundColor: AppColors.stepIdle,
                  color: AppColors.gold,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        _StarPill(stars: stars, max: max, l: l),
        SizedBox(width: 12 + inset),
      ],
    );
  }
}

class _StarPill extends StatelessWidget {
  const _StarPill({required this.stars, required this.max, required this.l});

  final int stars;
  final int max;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) => Semantics(
    label: l.totalStars(stars, max),
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.bubbleBorder, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
          const SizedBox(width: 2),
          Text('$stars', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('/$max', style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
        ],
      ),
    ),
  );
}
