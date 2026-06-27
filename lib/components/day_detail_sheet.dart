import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pp_tracker/components/app_card.dart';
import 'package:pp_tracker/components/quick_log_sheets.dart';
import 'package:pp_tracker/models/daily_log.dart';
import 'package:pp_tracker/models/menstrual_cycle.dart';
import 'package:pp_tracker/models/user_model.dart';
import 'package:pp_tracker/theme/app_theme.dart';

/// Shows a modern bottom sheet with everything known about [day]: its cycle
/// phase/marker plus any data the user logged. For today, it offers quick
/// shortcuts to log more.
void showDayDetailSheet(BuildContext context, DateTime day) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _DayDetailContent(day: day),
  );
}

class _DayDetailContent extends StatelessWidget {
  final DateTime day;
  const _DayDetailContent({required this.day});

  bool get _isToday {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserModel>(
      builder: (context, model, _) {
        final cycle = model.cycle;
        final info = cycle.dayInfo(day);
        final log = model.logFor(day);

        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.xs,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.alpha(info.phase.color, 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Center(
                          child: Text(info.phase.emoji,
                              style: const TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isToday
                                ? 'Today'
                                : DateFormat.MMMMEEEEd().format(day),
                            style: AppText.h2,
                          ),
                          Text(
                            'Cycle day ${info.cycleDay} · ${info.phase.label}',
                            style: AppText.label,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Marker + fertility chips
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _markerPill(info.marker),
                    Pill(
                      label: '${info.pregnancyChance}% conception',
                      color: AppColors.ovulation,
                      icon: Icons.spa_rounded,
                    ),
                  ].whereType<Widget>().toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Logged data
                if (log.hasData) ...[
                  Text('Logged', style: AppText.h3),
                  const SizedBox(height: AppSpacing.sm),
                  _LoggedData(log: log),
                ] else
                  _EmptyState(isToday: _isToday),

                const SizedBox(height: AppSpacing.lg),

                if (_isToday)
                  Row(
                    children: [
                      Expanded(
                        child: _Action(
                          icon: Icons.mood_rounded,
                          label: 'Mood',
                          onTap: () {
                            Navigator.pop(context);
                            showMoodSheet(context);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _Action(
                          icon: Icons.healing_rounded,
                          label: 'Symptoms',
                          onTap: () {
                            Navigator.pop(context);
                            showSymptomSheet(context);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _Action(
                          icon: Icons.edit_note_rounded,
                          label: 'Note',
                          onTap: () {
                            Navigator.pop(context);
                            showNotesSheet(context);
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget? _markerPill(DayMarker marker) {
    return switch (marker) {
      DayMarker.period =>
        const Pill(label: 'Period', color: AppColors.menstrual, icon: Icons.water_drop_rounded),
      DayMarker.predictedPeriod => const Pill(
          label: 'Predicted period',
          color: AppColors.menstrual,
          icon: Icons.event_rounded),
      DayMarker.ovulation => const Pill(
          label: 'Ovulation day',
          color: AppColors.ovulation,
          icon: Icons.spa_rounded),
      DayMarker.fertileWindow => const Pill(
          label: 'Fertile window',
          color: AppColors.fertile,
          icon: Icons.favorite_rounded),
      DayMarker.pms =>
        const Pill(label: 'PMS likely', color: AppColors.luteal, icon: Icons.nightlight_round),
      DayMarker.normal => null,
    };
  }
}

class _LoggedData extends StatelessWidget {
  final DailyLog log;
  const _LoggedData({required this.log});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    if (log.mood != null) {
      rows.add(_row(log.mood!.emoji, 'Mood', log.mood!.label));
    }
    if (log.flow != FlowIntensity.none) {
      rows.add(_row('🩸', 'Flow', log.flow.label));
    }
    if (log.symptoms.isNotEmpty) {
      rows.add(_row('🩹', 'Symptoms',
          log.symptoms.map((s) => s.label).join(', ')));
    }
    if (log.waterMl > 0) {
      rows.add(_row('💧', 'Water',
          '${(log.waterMl / 1000).toStringAsFixed(1)} L'));
    }
    if (log.sleepHours != null) {
      rows.add(_row('😴', 'Sleep', '${log.sleepHours!.toStringAsFixed(1)} h'));
    }
    if (log.weightKg != null) {
      rows.add(_row('⚖️', 'Weight', '${log.weightKg!.toStringAsFixed(1)} kg'));
    }
    if (log.energy != null) {
      rows.add(_row('⚡', 'Energy', '${log.energy}/5'));
    }
    if (log.notes.trim().isNotEmpty) {
      rows.add(_row('📝', 'Note', log.notes));
    }

    return AppCard(
      color: AppColors.surfaceAlt,
      shadows: const [],
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(height: AppSpacing.md, color: AppColors.divider),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _row(String emoji, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
            width: 80,
            child: Text(label, style: AppText.label)),
        Expanded(
            child: Text(value,
                style: AppText.body.copyWith(color: AppColors.textPrimary))),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isToday;
  const _EmptyState({required this.isToday});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceAlt,
      shadows: const [],
      child: Row(
        children: [
          const Text('🌷', style: TextStyle(fontSize: 22)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isToday
                  ? 'Nothing logged yet today. Add how you\'re feeling below.'
                  : 'No entries for this day.',
              style: AppText.body,
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Action(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.alpha(AppColors.primary, 0.10),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: AppText.caption.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
