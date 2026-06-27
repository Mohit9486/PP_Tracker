import 'dart:math';
import 'package:pp_tracker/models/cycle_phase.dart';

/// How a particular calendar day relates to the cycle. This is the richer,
/// UI-facing classification (distinct from the four biological [CyclePhase]s)
/// and is what the calendar paints.
enum DayMarker {
  period, // confirmed/logged or predicted bleeding day
  predictedPeriod, // future predicted bleeding
  fertileWindow, // elevated fertility
  ovulation, // peak fertility day
  pms, // late luteal, symptom-prone days before period
  normal,
}

/// A descriptor for a single day within the cycle model.
class CycleDayInfo {
  final DateTime date;
  final int cycleDay; // 1-based day within the current cycle
  final CyclePhase phase;
  final DayMarker marker;
  final int pregnancyChance; // 0–100

  const CycleDayInfo({
    required this.date,
    required this.cycleDay,
    required this.phase,
    required this.marker,
    required this.pregnancyChance,
  });
}

/// A single recorded (historical or current) cycle.
class CycleRecord {
  final DateTime startDate; // first day of bleeding
  final int cycleLength; // days until next period starts
  final int periodLength; // days of bleeding

  const CycleRecord({
    required this.startDate,
    required this.cycleLength,
    required this.periodLength,
  });

  DateTime get endDate => _atMidnight(startDate).add(Duration(days: cycleLength - 1));
  DateTime get nextStart => _atMidnight(startDate).add(Duration(days: cycleLength));

  bool contains(DateTime day) {
    final d = _atMidnight(day);
    return !d.isBefore(_atMidnight(startDate)) && !d.isAfter(endDate);
  }
}

DateTime _atMidnight(DateTime d) => DateTime(d.year, d.month, d.day);

/// The cycle engine.
///
/// Given the current cycle parameters (and, optionally, a history of past
/// cycles for averaging) it derives phases, day markers, fertility and
/// predictions. It is pure/stateless — [UserModel] owns the data and asks
/// this engine to compute.
class MenstrualCycle {
  static const int defaultCycleLength = 28;
  static const int defaultPeriodLength = 5;
  static const int lutealPhaseLength = 14; // days from ovulation to next period
  static const int fertileWindowBefore = 5; // sperm survival window
  static const int pmsWindow = 4; // days before period flagged as PMS

  final DateTime cycleStartDate;
  final int cycleLength;
  final int periodLength;
  final List<CycleRecord> history;

  MenstrualCycle({
    required DateTime cycleStartDate,
    this.cycleLength = defaultCycleLength,
    this.periodLength = defaultPeriodLength,
    this.history = const [],
  }) : cycleStartDate = _atMidnight(cycleStartDate);

  // ---- Core anchors -------------------------------------------------------

  int get ovulationDayOfCycle => cycleLength - lutealPhaseLength; // 1-based
  DateTime get currentCycleStart => _cycleStartFor(DateTime.now());
  DateTime get nextPeriodDate => currentCycleStart.add(Duration(days: cycleLength));
  DateTime get ovulationDate =>
      currentCycleStart.add(Duration(days: ovulationDayOfCycle - 1));

  DateTime get fertileWindowStart =>
      ovulationDate.subtract(const Duration(days: fertileWindowBefore));
  DateTime get fertileWindowEnd => ovulationDate.add(const Duration(days: 1));

  int get currentCycleDay => cycleDayFor(DateTime.now());
  CyclePhase get currentPhase => phaseFor(DateTime.now());

  int get daysUntilNextPeriod =>
      nextPeriodDate.difference(_atMidnight(DateTime.now())).inDays;

  // ---- Per-day computations ----------------------------------------------

  /// Start date of the cycle that [date] falls within (handles repeats both
  /// forwards and backwards from the anchor).
  DateTime _cycleStartFor(DateTime date) {
    final d = _atMidnight(date);
    final diff = d.difference(cycleStartDate).inDays;
    final offset = (diff / cycleLength).floor();
    return cycleStartDate.add(Duration(days: offset * cycleLength));
  }

  int cycleDayFor(DateTime date) {
    final start = _cycleStartFor(date);
    return _atMidnight(date).difference(start).inDays + 1;
  }

  CyclePhase phaseFor(DateTime date) {
    final day = cycleDayFor(date);
    final ov = ovulationDayOfCycle;
    if (day <= periodLength) return CyclePhase.menstrual;
    if (day < ov - fertileWindowBefore) return CyclePhase.follicular;
    if (day <= ov + 1) return CyclePhase.ovulation;
    return CyclePhase.luteal;
  }

  DayMarker markerFor(DateTime date) {
    final d = _atMidnight(date);
    final day = cycleDayFor(d);
    final today = _atMidnight(DateTime.now());
    final ov = ovulationDayOfCycle;

    // Bleeding days
    if (day <= periodLength) {
      return d.isAfter(today) ? DayMarker.predictedPeriod : DayMarker.period;
    }
    // Ovulation peak
    if (day == ov) return DayMarker.ovulation;
    // Fertile window
    if (day >= ov - fertileWindowBefore && day <= ov + 1) {
      return DayMarker.fertileWindow;
    }
    // PMS — the last few luteal days before the next period
    if (day > cycleLength - pmsWindow) return DayMarker.pms;
    return DayMarker.normal;
  }

  /// Probability of conception for [date], a smooth bell around ovulation.
  int pregnancyChanceFor(DateTime date) {
    final day = cycleDayFor(date);
    final distance = (day - ovulationDayOfCycle).abs();
    const curve = {0: 33, 1: 27, 2: 21, 3: 14, 4: 9, 5: 4};
    if (day < ovulationDayOfCycle - fertileWindowBefore ||
        day > ovulationDayOfCycle + 1) {
      return distance <= 5 ? (curve[distance] ?? 0) : 0;
    }
    return curve[distance] ?? 2;
  }

  CycleDayInfo dayInfo(DateTime date) {
    final d = _atMidnight(date);
    return CycleDayInfo(
      date: d,
      cycleDay: cycleDayFor(d),
      phase: phaseFor(d),
      marker: markerFor(d),
      pregnancyChance: pregnancyChanceFor(d),
    );
  }

  /// Fraction (0–1) of the way through the current cycle, for progress rings.
  double get cycleProgress => (currentCycleDay - 1) / cycleLength;

  // ---- Predictions & confidence ------------------------------------------

  /// Average cycle length across history (falls back to the configured value).
  double get averageCycleLength {
    if (history.isEmpty) return cycleLength.toDouble();
    final total = history.fold<int>(0, (s, c) => s + c.cycleLength);
    return total / history.length;
  }

  /// A 0–100 confidence score based on how regular past cycles have been.
  int get regularityScore {
    if (history.length < 2) return 80; // optimistic default with little data
    final mean = averageCycleLength;
    final variance = history
            .map((c) => pow(c.cycleLength - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        history.length;
    final stdDev = sqrt(variance);
    // 0 deviation => 100; ~7 days deviation => ~0
    return (100 - (stdDev / 7 * 100)).clamp(0, 100).round();
  }

  int get shortestCycle => history.isEmpty
      ? cycleLength
      : history.map((c) => c.cycleLength).reduce(min);
  int get longestCycle => history.isEmpty
      ? cycleLength
      : history.map((c) => c.cycleLength).reduce(max);

  double get averagePeriodLength {
    if (history.isEmpty) return periodLength.toDouble();
    final total = history.fold<int>(0, (s, c) => s + c.periodLength);
    return total / history.length;
  }

  /// Predicted start dates of the next [count] periods.
  List<DateTime> upcomingPeriods({int count = 3}) {
    return List.generate(
      count,
      (i) => currentCycleStart.add(Duration(days: cycleLength * (i + 1))),
    );
  }
}
