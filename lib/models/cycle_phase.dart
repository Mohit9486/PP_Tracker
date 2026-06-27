import 'package:flutter/material.dart';
import 'package:pp_tracker/theme/app_theme.dart';

/// The four biological phases of the menstrual cycle, each carrying the
/// presentation metadata (label, colour, icon, copy) used throughout the UI.
enum CyclePhase {
  menstrual,
  follicular,
  ovulation,
  luteal;

  String get label => switch (this) {
        CyclePhase.menstrual => 'Menstrual',
        CyclePhase.follicular => 'Follicular',
        CyclePhase.ovulation => 'Ovulation',
        CyclePhase.luteal => 'Luteal',
      };

  String get tagline => switch (this) {
        CyclePhase.menstrual => 'Time to rest & restore',
        CyclePhase.follicular => 'Energy is rising',
        CyclePhase.ovulation => 'You\'re at your peak',
        CyclePhase.luteal => 'Wind down & nurture',
      };

  String get emoji => switch (this) {
        CyclePhase.menstrual => '🌙',
        CyclePhase.follicular => '🌱',
        CyclePhase.ovulation => '🌸',
        CyclePhase.luteal => '🍂',
      };

  IconData get icon => switch (this) {
        CyclePhase.menstrual => Icons.water_drop_rounded,
        CyclePhase.follicular => Icons.eco_rounded,
        CyclePhase.ovulation => Icons.spa_rounded,
        CyclePhase.luteal => Icons.nightlight_round,
      };

  Color get color => switch (this) {
        CyclePhase.menstrual => AppColors.menstrual,
        CyclePhase.follicular => AppColors.follicular,
        CyclePhase.ovulation => AppColors.ovulation,
        CyclePhase.luteal => AppColors.luteal,
      };

  /// A short, supportive description shown on detail surfaces.
  String get description => switch (this) {
        CyclePhase.menstrual =>
          'Your body is shedding its lining. Energy may be low — prioritise warmth, rest and gentle movement.',
        CyclePhase.follicular =>
          'Estrogen is climbing and so is your energy. A great window for new ideas, workouts and socialising.',
        CyclePhase.ovulation =>
          'You\'re most fertile now. Confidence and libido often peak — make the most of the momentum.',
        CyclePhase.luteal =>
          'Progesterone rises then falls. You may feel more reflective. Be kind to yourself and slow down.',
      };

  /// Curated recommendations surfaced on the Home screen.
  List<String> get tips => switch (this) {
        CyclePhase.menstrual => const [
            'Keep warm and stay hydrated',
            'Iron-rich foods support your energy',
            'Gentle yoga or stretching eases cramps',
          ],
        CyclePhase.follicular => const [
            'Channel rising energy into new projects',
            'Try higher-intensity workouts',
            'Plan social activities — you\'ll feel up for it',
          ],
        CyclePhase.ovulation => const [
            'Stay well hydrated and nourished',
            'A good time for important conversations',
            'Track cervical signs if trying to conceive',
          ],
        CyclePhase.luteal => const [
            'Reduce caffeine to protect your sleep',
            'Magnesium-rich foods can ease PMS',
            'Prioritise calm, restorative routines',
          ],
      };
}
