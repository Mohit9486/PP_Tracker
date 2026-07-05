import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pp_tracker/components/app_nav_bar.dart';
import 'package:pp_tracker/components/guided_tour.dart';
import 'package:pp_tracker/pages/calendar_screen.dart';
import 'package:pp_tracker/pages/home_screen.dart';
import 'package:pp_tracker/pages/profile_screen.dart';
import 'package:pp_tracker/pages/blog/blog_hub_screen.dart';
import 'package:pp_tracker/state/onboarding_controller.dart';
import 'package:pp_tracker/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  bool _showTour = false;

  final GlobalKey _todayKey = GlobalKey();
  final GlobalKey _calendarKey = GlobalKey();
  final GlobalKey _learnKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // In a real app, check SharedPreferences if tour was already shown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final onboarding = context.read<OnboardingController>();
      if (onboarding.shouldShowTour) {
        setState(() => _showTour = true);
      }
    });
  }

  static const _pages = [
    HomeScreen(),
    CalendarScreen(),
    BlogHubScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          extendBody: true,
          body: AnimatedSwitcher(
            duration: AppDuration.normal,
            switchInCurve: Curves.easeOut,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(_index),
              child: _pages[_index],
            ),
          ),
          bottomNavigationBar: AppNavBar(
            activeIndex: _index,
            onTap: (i) => setState(() => _index = i),
            keys: [_todayKey, _calendarKey, _learnKey, _profileKey],
          ),
        ),
        if (_showTour)
          GuidedTourOverlay(
            steps: [
              GuidedTourStep(
                targetKey: _todayKey,
                title: 'Daily Dashboard',
                description: 'Check your current cycle phase, wellness scores, and daily tips here.',
              ),
              GuidedTourStep(
                targetKey: _calendarKey,
                title: 'Cycle Calendar',
                description: 'Log your symptoms and track your future periods and ovulation days.',
              ),
              GuidedTourStep(
                targetKey: _learnKey,
                title: 'Health Library',
                description: 'Explore verified articles on nutrition, hormones, and wellness.',
              ),
              GuidedTourStep(
                targetKey: _profileKey,
                title: 'Your Profile',
                description: 'Manage your data, goals, and app settings.',
              ),
            ],
            onComplete: () => setState(() => _showTour = false),
          ),
      ],
    );
  }
}
