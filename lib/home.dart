import 'package:flutter/material.dart';
import 'package:pp_tracker/components/app_nav_bar.dart';
import 'package:pp_tracker/pages/calendar_screen.dart';
import 'package:pp_tracker/pages/home_screen.dart';
import 'package:pp_tracker/pages/profile_screen.dart';
import 'package:pp_tracker/pages/blog/blog_hub_screen.dart';
import 'package:pp_tracker/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    CalendarScreen(),
    BlogHubScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
    );
  }
}
