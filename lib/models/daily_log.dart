import 'package:flutter/material.dart';
import 'package:pp_tracker/theme/app_theme.dart';

/// A mood the user can record for a given day.
enum Mood {
  great('Great', '😍'),
  happy('Happy', '😊'),
  calm('Calm', '🌿'),
  tired('Tired', '😴'),
  sad('Sad', '😔'),
  anxious('Anxious', '😰'),
  irritable('Irritable', '😣');

  const Mood(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// A symptom the user can log, grouped with an icon for display.
enum Symptom {
  cramps('Cramps', '🤕'),
  headache('Headache', '🤯'),
  bloating('Bloating', '🎈'),
  fatigue('Fatigue', '😮‍💨'),
  acne('Acne', '🔴'),
  backache('Back pain', '🔥'),
  tenderBreasts('Tender breasts', '💗'),
  cravings('Cravings', '🍫'),
  nausea('Nausea', '🤢'),
  insomnia('Insomnia', '🌙');

  const Symptom(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// Flow intensity recorded on period days.
enum FlowIntensity {
  none('None'),
  light('Light'),
  medium('Medium'),
  heavy('Heavy');

  const FlowIntensity(this.label);
  final String label;
}

/// All information a user can record for a single calendar day.
///
/// Immutable; use [copyWith] to produce edited versions. This keeps the
/// [UserModel] the sole owner of mutation and makes future persistence
/// (JSON / DB rows) straightforward.
@immutable
class DailyLog {
  final DateTime date; // normalised to midnight
  final Set<Symptom> symptoms;
  final Mood? mood;
  final FlowIntensity flow;
  final int? energy; // 1–5
  final double waterMl; // millilitres consumed
  final double? sleepHours;
  final double? weightKg;
  final double? temperatureC; // basal body temperature
  final List<String> medications;
  final String notes;
  final bool intimacy;

  const DailyLog({
    required this.date,
    this.symptoms = const {},
    this.mood,
    this.flow = FlowIntensity.none,
    this.energy,
    this.waterMl = 0,
    this.sleepHours,
    this.weightKg,
    this.temperatureC,
    this.medications = const [],
    this.notes = '',
    this.intimacy = false,
  });

  /// Daily hydration goal in millilitres.
  static const double waterGoalMl = 2000;

  bool get isEmpty =>
      symptoms.isEmpty &&
      mood == null &&
      flow == FlowIntensity.none &&
      energy == null &&
      waterMl == 0 &&
      sleepHours == null &&
      weightKg == null &&
      temperatureC == null &&
      medications.isEmpty &&
      notes.trim().isEmpty &&
      !intimacy;

  bool get hasData => !isEmpty;

  double get waterProgress => (waterMl / waterGoalMl).clamp(0.0, 1.0);

  DailyLog copyWith({
    Set<Symptom>? symptoms,
    Object? mood = _sentinel,
    FlowIntensity? flow,
    Object? energy = _sentinel,
    double? waterMl,
    Object? sleepHours = _sentinel,
    Object? weightKg = _sentinel,
    Object? temperatureC = _sentinel,
    List<String>? medications,
    String? notes,
    bool? intimacy,
  }) {
    return DailyLog(
      date: date,
      symptoms: symptoms ?? this.symptoms,
      mood: mood == _sentinel ? this.mood : mood as Mood?,
      flow: flow ?? this.flow,
      energy: energy == _sentinel ? this.energy : energy as int?,
      waterMl: waterMl ?? this.waterMl,
      sleepHours:
          sleepHours == _sentinel ? this.sleepHours : sleepHours as double?,
      weightKg: weightKg == _sentinel ? this.weightKg : weightKg as double?,
      temperatureC: temperatureC == _sentinel
          ? this.temperatureC
          : temperatureC as double?,
      medications: medications ?? this.medications,
      notes: notes ?? this.notes,
      intimacy: intimacy ?? this.intimacy,
    );
  }

  static const Object _sentinel = Object();
}

extension MoodColor on Mood {
  Color get color => switch (this) {
        Mood.great => AppColors.ovulation,
        Mood.happy => AppColors.follicular,
        Mood.calm => AppColors.water,
        Mood.tired => AppColors.luteal,
        Mood.sad => AppColors.textSecondary,
        Mood.anxious => AppColors.primary,
        Mood.irritable => AppColors.menstrual,
      };
}
