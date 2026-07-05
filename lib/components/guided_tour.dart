import 'package:flutter/material.dart';
import 'package:pp_tracker/theme/app_theme.dart';

class GuidedTourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final Alignment contentAlignment;

  const GuidedTourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.contentAlignment = Alignment.bottomCenter,
  });
}

class GuidedTourOverlay extends StatefulWidget {
  final List<GuidedTourStep> steps;
  final VoidCallback onComplete;

  const GuidedTourOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
  });

  @override
  State<GuidedTourOverlay> createState() => _GuidedTourOverlayState();
}

class _GuidedTourOverlayState extends State<GuidedTourOverlay> {
  int _currentStepIndex = 0;

  void _next() {
    setState(() {
      if (_currentStepIndex < widget.steps.length - 1) {
        _currentStepIndex++;
      } else {
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStepIndex];
    final RenderBox? renderBox = step.targetKey.currentContext?.findRenderObject() as RenderBox?;
    
    if (renderBox == null) {
      // Fallback if key not found
      return const SizedBox.shrink();
    }

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: _next,
        child: Stack(
          children: [
            // Darkened background with a hole
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.7),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: offset.dx - 8,
                    top: offset.dy - 8,
                    child: Container(
                      width: size.width + 16,
                      height: size.height + 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Positioned(
              left: 20,
              right: 20,
              top: offset.dy > MediaQuery.of(context).size.height / 2 
                  ? offset.dy - 180 
                  : offset.dy + size.height + 20,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: AppShadows.lifted,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step.title, style: AppText.h2),
                          const SizedBox(height: AppSpacing.sm),
                          Text(step.description, style: AppText.body),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_currentStepIndex + 1} / ${widget.steps.length}',
                                style: AppText.caption,
                              ),
                              TextButton(
                                onPressed: _next,
                                child: Text(
                                  _currentStepIndex == widget.steps.length - 1 ? 'Finish' : 'Got it',
                                  style: AppText.bodyStrong.copyWith(color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
