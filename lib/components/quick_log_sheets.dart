import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pp_tracker/models/daily_log.dart';
import 'package:pp_tracker/models/user_model.dart';
import 'package:pp_tracker/theme/app_theme.dart';

/// Shared scaffold for every quick-log sheet so they look identical.
Future<void> _showSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  required Widget child,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.xs,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.h1),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(subtitle, style: AppText.body),
          ],
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    ),
  );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        onPressed: onPressed,
        child: Text(label,
            style: AppText.bodyStrong.copyWith(color: Colors.white)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mood
// ---------------------------------------------------------------------------

void showMoodSheet(BuildContext context) {
  final model = context.read<UserModel>();
  _showSheet(
    context,
    title: 'How are you feeling?',
    subtitle: 'Tap the mood that fits your day',
    child: Consumer<UserModel>(
      builder: (context, m, _) => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: Mood.values.map((mood) {
          final selected = m.today.mood == mood;
          return _EmojiChoice(
            emoji: mood.emoji,
            label: mood.label,
            color: mood.color,
            selected: selected,
            onTap: () {
              model.setMood(selected ? null : mood);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Symptoms
// ---------------------------------------------------------------------------

void showSymptomSheet(BuildContext context) {
  final model = context.read<UserModel>();
  _showSheet(
    context,
    title: 'Log symptoms',
    subtitle: 'Select anything you\'re noticing today',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer<UserModel>(
          builder: (context, m, _) => Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: Symptom.values.map((s) {
              final selected = m.today.symptoms.contains(s);
              return _EmojiChoice(
                emoji: s.emoji,
                label: s.label,
                color: AppColors.menstrual,
                selected: selected,
                onTap: () => model.toggleSymptom(s),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _PrimaryButton(label: 'Done', onPressed: () => Navigator.pop(context)),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Water
// ---------------------------------------------------------------------------

void showWaterSheet(BuildContext context) {
  final model = context.read<UserModel>();
  _showSheet(
    context,
    title: 'Water intake',
    subtitle: 'Goal: 2.0 L per day',
    child: Consumer<UserModel>(
      builder: (context, m, _) {
        final log = m.today;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text('${(log.waterMl / 1000).toStringAsFixed(2)} L',
                  style: AppText.display.copyWith(color: AppColors.water)),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: log.waterProgress,
                minHeight: 10,
                backgroundColor: AppColors.alpha(AppColors.water, 0.15),
                valueColor: const AlwaysStoppedAnimation(AppColors.water),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                for (final amt in [250, 500, 750])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _SoftButton(
                        label: '+$amt ml',
                        color: AppColors.water,
                        onTap: () => model.addWater(amt.toDouble()),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _PrimaryButton(
                label: 'Done', onPressed: () => Navigator.pop(context)),
          ],
        );
      },
    ),
  );
}

// ---------------------------------------------------------------------------
// Sleep
// ---------------------------------------------------------------------------

void showSleepSheet(BuildContext context) {
  final model = context.read<UserModel>();
  double hours = model.today.sleepHours ?? 8;
  _showSheet(
    context,
    title: 'Sleep',
    subtitle: 'How long did you sleep?',
    child: StatefulBuilder(
      builder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text('${hours.toStringAsFixed(1)} h',
                style: AppText.display.copyWith(color: AppColors.sleep)),
          ),
          Slider(
            value: hours,
            min: 0,
            max: 12,
            divisions: 24,
            activeColor: AppColors.sleep,
            inactiveColor: AppColors.alpha(AppColors.sleep, 0.15),
            label: '${hours.toStringAsFixed(1)} h',
            onChanged: (v) => setState(() => hours = v),
          ),
          const SizedBox(height: AppSpacing.md),
          _PrimaryButton(
            label: 'Save',
            onPressed: () {
              model.setSleep(hours);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Weight
// ---------------------------------------------------------------------------

void showWeightSheet(BuildContext context) {
  final model = context.read<UserModel>();
  final controller = TextEditingController(
    text: model.today.weightKg?.toStringAsFixed(1) ?? '',
  );
  _showSheet(
    context,
    title: 'Weight',
    subtitle: 'Log today\'s weight',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppText.h1,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            suffixText: 'kg',
            filled: true,
            fillColor: AppColors.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _PrimaryButton(
          label: 'Save',
          onPressed: () {
            final v = double.tryParse(controller.text);
            if (v != null) model.setWeight(v);
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Notes
// ---------------------------------------------------------------------------

void showNotesSheet(BuildContext context) {
  final model = context.read<UserModel>();
  final controller = TextEditingController(text: model.today.notes);
  _showSheet(
    context,
    title: 'Daily note',
    subtitle: 'A space for anything you want to remember',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          maxLines: 4,
          style: AppText.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'How was your day?',
            filled: true,
            fillColor: AppColors.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _PrimaryButton(
          label: 'Save note',
          onPressed: () {
            model.setNotes(controller.text);
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Period start
// ---------------------------------------------------------------------------

void showPeriodSheet(BuildContext context) {
  final model = context.read<UserModel>();
  _showSheet(
    context,
    title: 'Period started today?',
    subtitle: 'We\'ll update your predictions accordingly',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PrimaryButton(
          label: 'Yes, my period started today',
          onPressed: () {
            model.logPeriodStart(DateTime.now());
            model.setFlow(FlowIntensity.medium);
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Not yet',
              style: AppText.label.copyWith(color: AppColors.textSecondary)),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Shared choice widgets
// ---------------------------------------------------------------------------

class _EmojiChoice extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _EmojiChoice({
    required this.emoji,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.alpha(color, 0.16) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppText.caption.copyWith(
                color: selected ? color : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SoftButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.alpha(color, 0.12),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Center(
            child: Text(label,
                style: AppText.bodyStrong.copyWith(color: color)),
          ),
        ),
      ),
    );
  }
}
