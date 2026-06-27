import 'package:flutter/foundation.dart';
import 'package:pp_tracker/models/cycle_phase.dart';
import 'package:pp_tracker/models/daily_log.dart';
import 'package:pp_tracker/models/menstrual_cycle.dart';

/// What the user is currently tracking towards. Lets the UI adapt copy and
/// emphasis (e.g. fertility vs. PMS) without restructuring screens.
enum TrackingGoal {
  general('Track my cycle'),
  conceive('Trying to conceive'),
  avoid('Avoiding pregnancy'),
  perimenopause('Perimenopause');

  const TrackingGoal(this.label);
  final String label;
}

class UserPreferences {
  String name;
  TrackingGoal goal;
  bool periodReminders;
  bool fertileReminders;
  bool dailyTips;

  UserPreferences({
    this.name = 'there',
    this.goal = TrackingGoal.general,
    this.periodReminders = true,
    this.fertileReminders = true,
    this.dailyTips = true,
  });
}

class Medication {
  final String name;
  final String schedule; // e.g. "Daily, 9:00 AM"
  bool enabled;

  Medication({required this.name, required this.schedule, this.enabled = true});
}

/// The single source of truth for everything user-specific.
///
/// Screens listen to this via `Provider`/`ChangeNotifier`. All mutation goes
/// through methods here so that adding persistence (local DB or backend) later
/// only touches this class — not the UI.
class UserModel extends ChangeNotifier {
  UserModel() {
    _seedDemoData();
  }

  // ---- Backing state ------------------------------------------------------

  final UserPreferences preferences = UserPreferences();
  final List<CycleRecord> _history = [];
  final Map<DateTime, DailyLog> _logs = {};
  final List<Medication> medications = [];

  late DateTime _currentCycleStart;
  int _cycleLength = MenstrualCycle.defaultCycleLength;
  int _periodLength = MenstrualCycle.defaultPeriodLength;

  // ---- Derived cycle engine ----------------------------------------------

  MenstrualCycle get cycle => MenstrualCycle(
        cycleStartDate: _currentCycleStart,
        cycleLength: _cycleLength,
        periodLength: _periodLength,
        history: List.unmodifiable(_history),
      );

  List<CycleRecord> get history => List.unmodifiable(_history);
  int get cycleLength => _cycleLength;
  int get periodLength => _periodLength;

  // Convenience pass-throughs so widgets read one object.
  int get cycleDay => cycle.currentCycleDay;
  CyclePhase get currentPhase => cycle.currentPhase;
  int get daysUntilPeriod => cycle.daysUntilNextPeriod;
  DateTime get nextPeriodDate => cycle.nextPeriodDate;
  DateTime get ovulationDate => cycle.ovulationDate;
  int get regularityScore => cycle.regularityScore;

  // ---- Daily logs ---------------------------------------------------------

  static DateTime _key(DateTime d) => DateTime(d.year, d.month, d.day);

  DailyLog logFor(DateTime date) =>
      _logs[_key(date)] ?? DailyLog(date: _key(date));

  DailyLog get today => logFor(DateTime.now());

  bool hasLog(DateTime date) => _logs[_key(date)]?.hasData ?? false;

  void saveLog(DailyLog log) {
    final key = _key(log.date);
    if (log.isEmpty) {
      _logs.remove(key);
    } else {
      _logs[key] = log.copyWith();
    }
    notifyListeners();
  }

  /// Generic per-field updater for today's log used by quick-log sheets.
  void updateToday(DailyLog Function(DailyLog current) transform) {
    saveLog(transform(today));
  }

  void setMood(Mood? mood) => updateToday((l) => l.copyWith(mood: mood));

  void toggleSymptom(Symptom s) => updateToday((l) {
        final next = {...l.symptoms};
        next.contains(s) ? next.remove(s) : next.add(s);
        return l.copyWith(symptoms: next);
      });

  void addWater(double ml) =>
      updateToday((l) => l.copyWith(waterMl: (l.waterMl + ml).clamp(0, 5000)));

  void setSleep(double hours) =>
      updateToday((l) => l.copyWith(sleepHours: hours));

  void setWeight(double kg) => updateToday((l) => l.copyWith(weightKg: kg));

  void setEnergy(int level) =>
      updateToday((l) => l.copyWith(energy: level.clamp(1, 5)));

  void setNotes(String notes) => updateToday((l) => l.copyWith(notes: notes));

  void setFlow(FlowIntensity flow) => updateToday((l) => l.copyWith(flow: flow));

  // ---- Cycle management ---------------------------------------------------

  /// Records that a new period started on [date]: archives the cycle that just
  /// ended into history and re-anchors the current cycle.
  void logPeriodStart(DateTime date) {
    final start = _key(date);
    final length = start.difference(_currentCycleStart).inDays;
    if (length >= 15 && length <= 60) {
      _history.add(CycleRecord(
        startDate: _currentCycleStart,
        cycleLength: length,
        periodLength: _periodLength,
      ));
    }
    _currentCycleStart = start;
    notifyListeners();
  }

  void updateCycleSettings({int? cycleLength, int? periodLength}) {
    if (cycleLength != null) _cycleLength = cycleLength.clamp(21, 40);
    if (periodLength != null) _periodLength = periodLength.clamp(2, 10);
    notifyListeners();
  }

  void setGoal(TrackingGoal goal) {
    preferences.goal = goal;
    notifyListeners();
  }

  void setReminderPrefs({bool? period, bool? fertile, bool? tips}) {
    if (period != null) preferences.periodReminders = period;
    if (fertile != null) preferences.fertileReminders = fertile;
    if (tips != null) preferences.dailyTips = tips;
    notifyListeners();
  }

  void setMedicationEnabled(Medication med, bool enabled) {
    med.enabled = enabled;
    notifyListeners();
  }

  // ---- Insights -----------------------------------------------------------

  /// Wellness score (0–100) derived from today's logged signals.
  int get wellnessScore {
    final l = today;
    var score = 55.0;
    if (l.mood != null) {
      score += switch (l.mood!) {
        Mood.great || Mood.happy || Mood.calm => 12,
        Mood.tired => 2,
        _ => -4,
      };
    }
    if (l.energy != null) score += (l.energy! - 3) * 4;
    score += l.waterProgress * 12;
    if (l.sleepHours != null) {
      score += (l.sleepHours! >= 7 && l.sleepHours! <= 9) ? 12 : -4;
    }
    score -= l.symptoms.length * 3;
    return score.clamp(0, 100).round();
  }

  /// A time-of-day aware greeting.
  String get greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// A warm, phase + mood aware message for the Home hero strip.
  String get dailyMessage {
    final phase = currentPhase;
    final mood = today.mood;
    if (mood == Mood.sad || mood == Mood.anxious || mood == Mood.tired) {
      return 'Be gentle with yourself today. ${phase.tagline}. 💜';
    }
    return switch (phase) {
      CyclePhase.menstrual =>
        'Your period is here. Rest, keep warm and go easy. 🌙',
      CyclePhase.follicular =>
        'Energy is climbing — a lovely time to begin something new. 🌱',
      CyclePhase.ovulation =>
        'You\'re glowing at your peak. Make the most of it. 🌸',
      CyclePhase.luteal =>
        'Wind-down season. Nurture yourself and slow the pace. 🍂',
    };
  }

  /// Personalised recommendations: phase tips, adjusted by today's data.
  List<String> get recommendations {
    final tips = [...currentPhase.tips];
    final l = today;
    if (l.waterProgress < 0.6) {
      tips.insert(0, 'You\'re behind on water — aim for 2L today');
    }
    if ((l.sleepHours ?? 8) < 6) {
      tips.insert(0, 'Low on sleep — protect your rest tonight');
    }
    if (l.symptoms.contains(Symptom.cramps)) {
      tips.insert(0, 'A warm compress can ease those cramps');
    }
    return tips.take(3).toList();
  }

  // ---- Demo seed ----------------------------------------------------------

  void _seedDemoData() {
    final now = DateTime.now();
    _currentCycleStart = _key(now).subtract(const Duration(days: 9));

    // A few realistic past cycles for averages & regularity.
    var anchor = _currentCycleStart;
    const lengths = [29, 27, 28, 30, 28];
    for (final len in lengths) {
      anchor = anchor.subtract(Duration(days: len));
      _history.insert(
        0,
        CycleRecord(startDate: anchor, cycleLength: len, periodLength: 5),
      );
    }

    medications.addAll([
      Medication(name: 'Iron supplement', schedule: 'Daily, 9:00 AM'),
      Medication(name: 'Vitamin D', schedule: 'Daily, 9:00 AM'),
    ]);

    // Seed the last 14 days with light, believable logs.
    const sampleMoods = [
      Mood.happy,
      Mood.calm,
      Mood.tired,
      Mood.great,
      Mood.irritable,
    ];
    for (var i = 0; i < 14; i++) {
      final d = _key(now).subtract(Duration(days: i));
      _logs[d] = DailyLog(
        date: d,
        mood: sampleMoods[i % sampleMoods.length],
        energy: 2 + (i % 4),
        waterMl: 800 + (i % 5) * 350,
        sleepHours: 6.5 + (i % 3) * 0.8,
        weightKg: 61.5 + (i % 4) * 0.2,
        symptoms: i % 4 == 0 ? {Symptom.cramps, Symptom.fatigue} : {},
        flow: i < _periodLength ? FlowIntensity.medium : FlowIntensity.none,
      );
    }
  }
}
