import 'package:flutter/material.dart';

/// Centralized design system for the app.
///
/// Holds the colour palette, typography scale, spacing tokens, radii,
/// elevations and the assembled [ThemeData]. Everything visual should
/// reference these tokens so the app stays cohesive.
class AppColors {
  AppColors._();

  // Surfaces & background — warm, calming neutrals
  static const Color background = Color(0xFFFBF7F5); // warm cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF4EDEF); // subtle tint

  // Brand — muted berry / mauve (feminine, not candy pink)
  static const Color primary = Color(0xFFB76E84);
  static const Color primarySoft = Color(0xFFF1DDE4);
  static const Color primaryDeep = Color(0xFF8E5167);

  // Text
  static const Color textPrimary = Color(0xFF3B2E34);
  static const Color textSecondary = Color(0xFF8C7E84);
  static const Color textTertiary = Color(0xFFB7ABB0);

  // Cycle phase colours — distinct, accessible, calming
  static const Color menstrual = Color(0xFFE26D7E); // soft rose-red
  static const Color follicular = Color(0xFF5FB49C); // fresh teal-green
  static const Color fertile = Color(0xFF7FB0E0); // calm sky blue
  static const Color ovulation = Color(0xFFE0A24E); // warm amber/gold
  static const Color luteal = Color(0xFF9B8AC9); // soft lavender

  // Functional
  static const Color success = Color(0xFF5FB49C);
  static const Color warning = Color(0xFFE0A24E);
  static const Color danger = Color(0xFFE26D7E);
  static const Color water = Color(0xFF6FB7D4);
  static const Color sleep = Color(0xFF9B8AC9);
  static const Color divider = Color(0xFFEDE4E7);

  /// Colour-with-alpha helper that avoids the deprecated `withOpacity`.
  static Color alpha(Color c, double a) => c.withValues(alpha: a);
}

class AppSpacing {
  AppSpacing._();
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

class AppRadius {
  AppRadius._();
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 32;
  static const double pill = 999;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get soft => [
        BoxShadow(
          color: const Color(0xFF8E5167).withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0xFF3B2E34).withValues(alpha: 0.05),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get lifted => [
        BoxShadow(
          color: const Color(0xFF8E5167).withValues(alpha: 0.16),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ];
}

class AppDuration {
  AppDuration._();
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 550);
}

class AppText {
  AppText._();

  static const String _family = 'Roboto';

  static const TextStyle display = TextStyle(
    fontFamily: _family,
    fontSize: 34,
    height: 1.1,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: _family,
    fontSize: 26,
    height: 1.15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _family,
    fontSize: 17,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    letterSpacing: 0.3,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.textTertiary,
    letterSpacing: 1.2,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.luteal,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
        fontFamily: 'Roboto',
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      splashColor: AppColors.alpha(AppColors.primary, 0.06),
      highlightColor: AppColors.alpha(AppColors.primary, 0.04),
      dividerColor: AppColors.divider,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
    );
  }
}
