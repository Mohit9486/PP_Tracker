import 'package:flutter/material.dart';
import 'package:pp_tracker/theme/app_theme.dart';

class NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const NavDestination(this.icon, this.activeIcon, this.label);
}

/// A soft, floating bottom navigation bar with an animated active pill.
class AppNavBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;

  const AppNavBar({super.key, required this.activeIndex, required this.onTap});

  static const _destinations = [
    NavDestination(Icons.spa_outlined, Icons.spa_rounded, 'Today'),
    NavDestination(
        Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Calendar'),
    NavDestination(
        Icons.menu_book_outlined, Icons.menu_book_rounded, 'Learn'),
    NavDestination(Icons.person_outline_rounded, Icons.person_rounded, 'Me'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadows.lifted,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_destinations.length, (i) {
          final d = _destinations[i];
          final active = i == activeIndex;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: AppDuration.normal,
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.alpha(AppColors.primary, 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      active ? d.activeIcon : d.icon,
                      color:
                          active ? AppColors.primary : AppColors.textTertiary,
                      size: 24,
                    ),
                    AnimatedSize(
                      duration: AppDuration.fast,
                      child: active
                          ? Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                d.label,
                                style: AppText.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
