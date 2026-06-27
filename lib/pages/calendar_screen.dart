import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pp_tracker/components/app_card.dart';
import 'package:pp_tracker/components/cycle_phase_timeline.dart';
import 'package:pp_tracker/components/day_detail_sheet.dart';
import 'package:pp_tracker/models/menstrual_cycle.dart';
import 'package:pp_tracker/models/user_model.dart';
import 'package:pp_tracker/theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Consumer<UserModel>(
      builder: (context, model, _) {
        final cycle = model.cycle;
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _Header()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _CalendarCard(
                    cycle: cycle,
                    model: model,
                    focusedDay: _focusedDay,
                    selectedDay: _selectedDay,
                    onSelect: (day, focused) {
                      setState(() {
                        _selectedDay = day;
                        _focusedDay = focused;
                      });
                      showDayDetailSheet(context, day);
                    },
                    onPageChanged: (d) => setState(() => _focusedDay = d),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _Legend(),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'Where you are now'),
                  CyclePhaseTimeline(cycle: cycle),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'Predictions'),
                  _PredictionsList(cycle: cycle, model: model),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your cycle', style: AppText.label),
              const SizedBox(height: 2),
              Text('Calendar', style: AppText.h1),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Calendar
// ---------------------------------------------------------------------------

class _CalendarCard extends StatelessWidget {
  final MenstrualCycle cycle;
  final UserModel model;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final void Function(DateTime, DateTime) onSelect;
  final ValueChanged<DateTime> onPageChanged;

  const _CalendarCard({
    required this.cycle,
    required this.model,
    required this.focusedDay,
    required this.selectedDay,
    required this.onSelect,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: TableCalendar(
        firstDay: DateTime.utc(2022, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: focusedDay,
        currentDay: DateTime.now(),
        selectedDayPredicate: (d) => isSameDay(d, selectedDay),
        onDaySelected: onSelect,
        onPageChanged: onPageChanged,
        availableGestures: AvailableGestures.horizontalSwipe,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: AppText.h3,
          leftChevronIcon: const Icon(Icons.chevron_left_rounded,
              color: AppColors.textSecondary),
          rightChevronIcon: const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
          headerPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: AppText.caption,
          weekendStyle: AppText.caption,
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, _) =>
              _DayCell(day: day, cycle: cycle, model: model),
          todayBuilder: (context, day, _) =>
              _DayCell(day: day, cycle: cycle, model: model, isToday: true),
          selectedBuilder: (context, day, _) => _DayCell(
              day: day, cycle: cycle, model: model, isSelected: true),
          outsideBuilder: (context, day, _) => Center(
            child: Text('${day.day}',
                style: AppText.caption
                    .copyWith(color: AppColors.alpha(AppColors.textTertiary, 0.5))),
          ),
        ),
      ),
    );
  }
}

/// Paints a single day according to its cycle [DayMarker], today/selected
/// state and whether the user has logged anything.
class _DayCell extends StatelessWidget {
  final DateTime day;
  final MenstrualCycle cycle;
  final UserModel model;
  final bool isToday;
  final bool isSelected;

  const _DayCell({
    required this.day,
    required this.cycle,
    required this.model,
    this.isToday = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final marker = cycle.markerFor(day);
    final hasLog = model.hasLog(day);

    Color bg = Colors.transparent;
    Color fg = AppColors.textPrimary;
    Border? border;

    switch (marker) {
      case DayMarker.period:
        bg = AppColors.menstrual;
        fg = Colors.white;
        break;
      case DayMarker.predictedPeriod:
        border = Border.all(color: AppColors.menstrual, width: 1.5);
        fg = AppColors.menstrual;
        break;
      case DayMarker.ovulation:
        bg = AppColors.ovulation;
        fg = Colors.white;
        break;
      case DayMarker.fertileWindow:
        bg = AppColors.alpha(AppColors.fertile, 0.18);
        fg = AppColors.primaryDeep;
        break;
      case DayMarker.pms:
        bg = AppColors.alpha(AppColors.luteal, 0.18);
        fg = AppColors.primaryDeep;
        break;
      case DayMarker.normal:
        break;
    }

    return AnimatedContainer(
      duration: AppDuration.fast,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: isSelected
            ? Border.all(color: AppColors.primaryDeep, width: 2)
            : isToday && bg == Colors.transparent
                ? Border.all(color: AppColors.primary, width: 1.5)
                : border,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${day.day}',
                style: AppText.caption.copyWith(
                  color: isToday && bg == Colors.transparent
                      ? AppColors.primary
                      : fg,
                  fontWeight: FontWeight.w600,
                )),
            if (hasLog)
              Container(
                margin: const EdgeInsets.only(top: 1),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: fg == Colors.white ? Colors.white : AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Legend
// ---------------------------------------------------------------------------

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: const [
          _LegendItem(color: AppColors.menstrual, label: 'Period', filled: true),
          _LegendItem(
              color: AppColors.menstrual, label: 'Predicted', filled: false),
          _LegendItem(color: AppColors.fertile, label: 'Fertile', filled: true),
          _LegendItem(
              color: AppColors.ovulation, label: 'Ovulation', filled: true),
          _LegendItem(color: AppColors.luteal, label: 'PMS', filled: true),
          _LegendItem(color: AppColors.primary, label: 'Logged', dot: true),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool filled;
  final bool dot;
  const _LegendItem(
      {required this.color,
      required this.label,
      this.filled = true,
      this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: dot
                ? Colors.transparent
                : filled
                    ? AppColors.alpha(color, 0.22)
                    : Colors.transparent,
            shape: BoxShape.circle,
            border: filled && !dot
                ? null
                : Border.all(color: color, width: 1.5),
          ),
          alignment: Alignment.center,
          child: dot
              ? Container(
                  width: 5,
                  height: 5,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                )
              : filled
                  ? Container(
                      width: 7,
                      height: 7,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    )
                  : null,
        ),
        const SizedBox(width: 6),
        Text(label, style: AppText.caption),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Predictions
// ---------------------------------------------------------------------------

class _PredictionsList extends StatelessWidget {
  final MenstrualCycle cycle;
  final UserModel model;
  const _PredictionsList({required this.cycle, required this.model});

  @override
  Widget build(BuildContext context) {
    final upcoming = cycle.upcomingPeriods(count: 3);
    return AppCard(
      child: Column(
        children: [
          _PredRow(
            icon: Icons.spa_rounded,
            color: AppColors.ovulation,
            label: 'Ovulation',
            value: DateFormat.MMMMd().format(model.ovulationDate),
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          _PredRow(
            icon: Icons.favorite_rounded,
            color: AppColors.fertile,
            label: 'Fertile window',
            value:
                '${DateFormat.MMMd().format(cycle.fertileWindowStart)} – ${DateFormat.MMMd().format(cycle.fertileWindowEnd)}',
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          _PredRow(
            icon: Icons.water_drop_rounded,
            color: AppColors.menstrual,
            label: 'Next 3 periods',
            value: upcoming.map((d) => DateFormat.MMMd().format(d)).join(' · '),
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          _PredRow(
            icon: Icons.verified_rounded,
            color: AppColors.follicular,
            label: 'Cycle confidence',
            value: '${model.regularityScore}% regular',
          ),
        ],
      ),
    );
  }
}

class _PredRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _PredRow(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.alpha(color, 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.caption),
              const SizedBox(height: 2),
              Text(value, style: AppText.bodyStrong),
            ],
          ),
        ),
      ],
    );
  }
}
