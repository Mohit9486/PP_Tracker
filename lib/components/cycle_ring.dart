import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pp_tracker/models/cycle_phase.dart';
import 'package:pp_tracker/models/menstrual_cycle.dart';
import 'package:pp_tracker/theme/app_theme.dart';

/// A circular visualization of the entire cycle.
///
/// The ring is divided into phase-coloured arcs; a marker sits on the arc at
/// today's position and animates into place. The [center] widget renders the
/// headline numbers inside the ring.
class CycleRing extends StatelessWidget {
  final MenstrualCycle cycle;
  final double size;
  final Widget center;

  const CycleRing({
    super.key,
    required this.cycle,
    required this.center,
    this.size = 240,
  });

  @override
  Widget build(BuildContext context) {
    final progress = cycle.cycleProgress.clamp(0.0, 1.0);
    final segments = _buildSegments(cycle);

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: AppDuration.slow,
        curve: Curves.easeOutCubic,
        builder: (context, animatedProgress, _) {
          return CustomPaint(
            painter: _CycleRingPainter(
              segments: segments,
              markerProgress: animatedProgress,
            ),
            child: Center(child: center),
          );
        },
      ),
    );
  }

  static List<_PhaseSegment> _buildSegments(MenstrualCycle c) {
    final total = c.cycleLength.toDouble();
    final ov = c.ovulationDayOfCycle;
    final fertileStart = ov - MenstrualCycle.fertileWindowBefore;

    // Boundaries expressed in cycle days (0-based fractions of the ring).
    double f(num day) => (day / total).clamp(0.0, 1.0);

    return [
      _PhaseSegment(f(0), f(c.periodLength), CyclePhase.menstrual.color),
      _PhaseSegment(
          f(c.periodLength), f(fertileStart - 1), CyclePhase.follicular.color),
      _PhaseSegment(
          f(fertileStart - 1), f(ov + 1), CyclePhase.ovulation.color),
      _PhaseSegment(f(ov + 1), f(total), CyclePhase.luteal.color),
    ];
  }
}

class _PhaseSegment {
  final double start; // 0–1
  final double end; // 0–1
  final Color color;
  const _PhaseSegment(this.start, this.end, this.color);
}

class _CycleRingPainter extends CustomPainter {
  final List<_PhaseSegment> segments;
  final double markerProgress;

  _CycleRingPainter({required this.segments, required this.markerProgress});

  static const double _stroke = 16;
  static const double _gap = 0.012; // gap between segments (fraction)

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - _stroke) / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;
    const fullSweep = 2 * math.pi;

    // Faint full background track.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.alpha(AppColors.primaryDeep, 0.05);
    canvas.drawCircle(center, radius, track);

    // Phase segments.
    for (final seg in segments) {
      final segStart = startAngle + seg.start * fullSweep + _gap * fullSweep / 2;
      final segSweep =
          (seg.end - seg.start) * fullSweep - _gap * fullSweep;
      if (segSweep <= 0) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: segStart,
          endAngle: segStart + segSweep,
          colors: [AppColors.alpha(seg.color, 0.55), seg.color],
        ).createShader(rect);
      canvas.drawArc(rect, segStart, segSweep, false, paint);
    }

    // Today marker — a white knob ringed in the brand colour.
    final markerAngle = startAngle + markerProgress * fullSweep;
    final markerOffset = Offset(
      center.dx + radius * math.cos(markerAngle),
      center.dy + radius * math.sin(markerAngle),
    );
    canvas.drawCircle(
      markerOffset,
      _stroke / 2 + 5,
      Paint()..color = AppColors.surface,
    );
    canvas.drawCircle(
      markerOffset,
      _stroke / 2 + 5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..color = AppColors.primary,
    );
    canvas.drawCircle(
      markerOffset,
      4,
      Paint()..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(_CycleRingPainter old) =>
      old.markerProgress != markerProgress || old.segments != segments;
}
