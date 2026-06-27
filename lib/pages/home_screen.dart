import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pp_tracker/components/app_card.dart';
import 'package:pp_tracker/components/cycle_ring.dart';
import 'package:pp_tracker/components/quick_log_sheets.dart';
import 'package:pp_tracker/models/daily_log.dart';
import 'package:pp_tracker/models/user_model.dart';
import 'package:pp_tracker/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserModel>(
      builder: (context, model, _) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Greeting(model: model)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _CycleHeroCard(model: model),
                  const SizedBox(height: AppSpacing.lg),
                  _QuickLogRow(),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'Today at a glance'),
                  _TodaySnapshot(model: model),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'For your phase'),
                  _PhaseInsightCard(model: model),
                  const SizedBox(height: AppSpacing.lg),
                  _RecommendationsCard(model: model),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'Coming up'),
                  _PredictionsRow(model: model),
                  const SizedBox(height: AppSpacing.xl),
                  _AffirmationCard(),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Greeting header
// ---------------------------------------------------------------------------

class _Greeting extends StatelessWidget {
  final UserModel model;
  const _Greeting({required this.model});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${model.greeting},', style: AppText.label),
                  const SizedBox(height: 2),
                  Text(model.preferences.name == 'there'
                      ? 'Welcome back'
                      : model.preferences.name,
                      style: AppText.h1),
                ],
              ),
            ),
            _CircleIconButton(
              icon: Icons.notifications_none_rounded,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: AppShadows.soft,
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cycle hero
// ---------------------------------------------------------------------------

class _CycleHeroCard extends StatelessWidget {
  final UserModel model;
  const _CycleHeroCard({required this.model});

  @override
  Widget build(BuildContext context) {
    final phase = model.currentPhase;
    final cycle = model.cycle;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.alpha(phase.color, 0.16),
          AppColors.surface,
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Pill(label: phase.label, color: phase.color, icon: phase.icon),
              const Spacer(),
              Text(phase.emoji, style: const TextStyle(fontSize: 22)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CycleRing(
            cycle: cycle,
            size: 230,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Cycle day', style: AppText.caption),
                const SizedBox(height: 2),
                Text('${model.cycleDay}',
                    style: AppText.display
                        .copyWith(fontSize: 56, color: phase.color)),
                const SizedBox(height: 2),
                Text(phase.tagline, style: AppText.label),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  value: '${model.daysUntilPeriod}',
                  unit: 'days',
                  label: 'Until period',
                  color: AppColors.menstrual,
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: AppColors.divider),
              Expanded(
                child: _HeroStat(
                  value: DateFormat.MMMd().format(model.ovulationDate),
                  label: 'Ovulation',
                  color: AppColors.ovulation,
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: AppColors.divider),
              Expanded(
                child: _HeroStat(
                  value: '${model.regularityScore}%',
                  label: 'Regularity',
                  color: AppColors.follicular,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String? unit;
  final String label;
  final Color color;
  const _HeroStat(
      {required this.value, this.unit, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            text: value,
            style: AppText.h2.copyWith(color: color),
            children: [
              if (unit != null)
                TextSpan(
                    text: ' $unit',
                    style: AppText.caption.copyWith(color: color)),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppText.caption, textAlign: TextAlign.center),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Quick log row
// ---------------------------------------------------------------------------

class _QuickLogRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = <(IconData, String, Color, void Function(BuildContext))>[
      (Icons.water_drop_rounded, 'Period', AppColors.menstrual, showPeriodSheet),
      (Icons.mood_rounded, 'Mood', AppColors.ovulation, showMoodSheet),
      (Icons.healing_rounded, 'Symptoms', AppColors.primary, showSymptomSheet),
      (Icons.local_drink_rounded, 'Water', AppColors.water, showWaterSheet),
      (Icons.bedtime_rounded, 'Sleep', AppColors.sleep, showSleepSheet),
      (Icons.monitor_weight_rounded, 'Weight', AppColors.follicular,
          showWeightSheet),
      (Icons.edit_note_rounded, 'Note', AppColors.textSecondary, showNotesSheet),
    ];

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final (icon, label, color, action) = actions[i];
          return _QuickLogButton(
            icon: icon,
            label: label,
            color: color,
            onTap: () => action(context),
          );
        },
      ),
    );
  }
}

class _QuickLogButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickLogButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  State<_QuickLogButton> createState() => _QuickLogButtonState();
}

class _QuickLogButtonState extends State<_QuickLogButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: AppDuration.fast,
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.alpha(widget.color, 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(widget.icon, color: widget.color, size: 26),
              ),
              const SizedBox(height: 6),
              Text(widget.label,
                  style: AppText.caption, maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today snapshot
// ---------------------------------------------------------------------------

class _TodaySnapshot extends StatelessWidget {
  final UserModel model;
  const _TodaySnapshot({required this.model});

  @override
  Widget build(BuildContext context) {
    final log = model.today;
    final score = model.wellnessScore;
    final scoreColor = score >= 75
        ? AppColors.follicular
        : score >= 55
            ? AppColors.ovulation
            : AppColors.menstrual;

    return Column(
      children: [
        // Wellness score banner
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _MiniRing(progress: score / 100, color: scoreColor, label: '$score'),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wellness score', style: AppText.label),
                    const SizedBox(height: 2),
                    Text(
                      score >= 75
                          ? 'You\'re thriving today ✨'
                          : score >= 55
                              ? 'Doing well — keep it up'
                              : 'Take it gently today',
                      style: AppText.bodyStrong,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // 2x2 metric grid
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.mood_rounded,
                label: 'Mood',
                value: log.mood?.label ?? 'Tap to log',
                accent: log.mood?.color ?? AppColors.textTertiary,
                emoji: log.mood?.emoji,
                onTap: () => showMoodSheet(context),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _WaterTile(model: model),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.bedtime_rounded,
                label: 'Sleep',
                value: log.sleepHours != null
                    ? '${log.sleepHours!.toStringAsFixed(1)} h'
                    : 'Tap to log',
                accent: AppColors.sleep,
                onTap: () => showSleepSheet(context),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricTile(
                icon: Icons.healing_rounded,
                label: 'Symptoms',
                value: log.symptoms.isEmpty
                    ? 'None logged'
                    : '${log.symptoms.length} logged',
                accent: AppColors.menstrual,
                onTap: () => showSymptomSheet(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final String? emoji;
  final VoidCallback onTap;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.onTap,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.alpha(accent, 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: emoji != null
                    ? Center(
                        child: Text(emoji!, style: const TextStyle(fontSize: 18)))
                    : Icon(icon, size: 19, color: accent),
              ),
              const Spacer(),
              const Icon(Icons.add_rounded,
                  size: 18, color: AppColors.textTertiary),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(label, style: AppText.caption),
          const SizedBox(height: 2),
          Text(value, style: AppText.bodyStrong, maxLines: 1),
        ],
      ),
    );
  }
}

class _WaterTile extends StatelessWidget {
  final UserModel model;
  const _WaterTile({required this.model});

  @override
  Widget build(BuildContext context) {
    final log = model.today;
    return AppCard(
      onTap: () => showWaterSheet(context),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.alpha(AppColors.water, 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.local_drink_rounded,
                    size: 19, color: AppColors.water),
              ),
              const Spacer(),
              const Icon(Icons.add_rounded,
                  size: 18, color: AppColors.textTertiary),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Water', style: AppText.caption),
          const SizedBox(height: 4),
          Text('${(log.waterMl / 1000).toStringAsFixed(1)} / 2.0 L',
              style: AppText.bodyStrong),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: log.waterProgress,
              minHeight: 6,
              backgroundColor: AppColors.alpha(AppColors.water, 0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.water),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRing extends StatelessWidget {
  final double progress;
  final Color color;
  final String label;
  const _MiniRing(
      {required this.progress, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: AppDuration.slow,
        curve: Curves.easeOut,
        builder: (context, v, _) => Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: 5,
                backgroundColor: AppColors.alpha(color, 0.15),
                valueColor: AlwaysStoppedAnimation(color),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(label,
                style: AppText.bodyStrong.copyWith(color: color, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phase insight + recommendations
// ---------------------------------------------------------------------------

class _PhaseInsightCard extends StatelessWidget {
  final UserModel model;
  const _PhaseInsightCard({required this.model});

  @override
  Widget build(BuildContext context) {
    final phase = model.currentPhase;
    return AppCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.alpha(phase.color, 0.18),
          AppColors.alpha(phase.color, 0.05),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(phase.icon, color: phase.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${phase.label} phase', style: AppText.h3),
                const SizedBox(height: 4),
                Text(phase.description, style: AppText.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationsCard extends StatelessWidget {
  final UserModel model;
  const _RecommendationsCard({required this.model});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('Recommended for you', style: AppText.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...model.recommendations.map(
            (tip) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child: Text(tip,
                          style: AppText.body
                              .copyWith(color: AppColors.textPrimary))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Predictions
// ---------------------------------------------------------------------------

class _PredictionsRow extends StatelessWidget {
  final UserModel model;
  const _PredictionsRow({required this.model});

  @override
  Widget build(BuildContext context) {
    final cycle = model.cycle;
    return Row(
      children: [
        Expanded(
          child: _PredictionCard(
            icon: Icons.water_drop_rounded,
            color: AppColors.menstrual,
            title: 'Next period',
            date: model.nextPeriodDate,
            subtitle: 'in ${model.daysUntilPeriod} days',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _PredictionCard(
            icon: Icons.spa_rounded,
            color: AppColors.ovulation,
            title: 'Fertile window',
            date: cycle.fertileWindowStart,
            subtitle:
                'until ${DateFormat.MMMd().format(cycle.fertileWindowEnd)}',
          ),
        ),
      ],
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final DateTime date;
  final String subtitle;

  const _PredictionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.date,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.alpha(color, 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppText.caption),
          const SizedBox(height: 2),
          Text(DateFormat.MMMEd().format(date), style: AppText.h3),
          const SizedBox(height: 2),
          Text(subtitle, style: AppText.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Affirmation
// ---------------------------------------------------------------------------

class _AffirmationCard extends StatelessWidget {
  static const _affirmations = [
    'You are stronger than you think. Honour your body and celebrate your resilience.',
    'Every phase has its purpose. Trust your rhythm.',
    'Rest is productive. Be as kind to yourself as you are to others.',
  ];

  @override
  Widget build(BuildContext context) {
    final affirmation =
        _affirmations[DateTime.now().day % _affirmations.length];
    return AppCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.primaryDeep],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text('Daily affirmation',
                  style: AppText.overline.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            affirmation,
            style: AppText.h3.copyWith(color: Colors.white, height: 1.4),
          ),
        ],
      ),
    );
  }
}
