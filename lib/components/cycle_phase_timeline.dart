import 'package:flutter/material.dart';
import 'package:pp_tracker/components/app_card.dart';
import 'package:pp_tracker/models/cycle_phase.dart';
import 'package:pp_tracker/models/menstrual_cycle.dart';
import 'package:pp_tracker/theme/app_theme.dart';

/// A horizontal bar split into the four phases, with an animated marker
/// showing where today sits within the current cycle.
class CyclePhaseTimeline extends StatelessWidget {
  final MenstrualCycle cycle;
  const CyclePhaseTimeline({super.key, required this.cycle});

  @override
  Widget build(BuildContext context) {
    final ov = cycle.ovulationDayOfCycle;
    final total = cycle.cycleLength;
    final fertileStart = ov - MenstrualCycle.fertileWindowBefore;

    // Phase widths as flex weights (in days).
    final menstrual = cycle.periodLength;
    final follicular = (fertileStart - 1 - cycle.periodLength).clamp(1, total);
    final ovulation = (ov + 1 - (fertileStart - 1)).clamp(1, total);
    final luteal = (total - (ov + 1)).clamp(1, total);

    final phases = [
      (CyclePhase.menstrual, menstrual),
      (CyclePhase.follicular, follicular),
      (CyclePhase.ovulation, ovulation),
      (CyclePhase.luteal, luteal),
    ];

    final progress = cycle.cycleProgress.clamp(0.0, 1.0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Day ${cycle.currentCycleDay}', style: AppText.h3),
              const SizedBox(width: AppSpacing.xs),
              Text('of ${cycle.cycleLength}', style: AppText.label),
              const Spacer(),
              Text(cycle.currentPhase.label,
                  style: AppText.label
                      .copyWith(color: cycle.currentPhase.color)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return SizedBox(
                height: 36,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Phase bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Row(
                        children: phases.map((p) {
                          return Expanded(
                            flex: p.$2,
                            child: Container(
                              height: 12,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              color: AppColors.alpha(p.$1.color, 0.85),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Animated marker
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: AppDuration.slow,
                        curve: Curves.easeOutCubic,
                        builder: (context, v, child) => Transform.translate(
                          offset: Offset((width - 18) * v, 0),
                          child: child,
                        ),
                        child: Center(
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.primaryDeep, width: 3),
                              boxShadow: AppShadows.soft,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: CyclePhase.values
                .map((p) => Text(p.label, style: AppText.caption))
                .toList(),
          ),
        ],
      ),
    );
  }
}
