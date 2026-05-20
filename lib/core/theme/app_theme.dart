import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds
  static const background   = Color(0xFF1F1F21);
  static const sidebar      = Color(0xFF2B2B2E);
  static const card         = Color(0xFF2B2B2E);

  // Buttons
  static const activeBtn    = Color(0xFFF58A33);
  static const inactiveBtn  = Color(0xFF3A3A3D);

  // Text
  static const text         = Color(0xFFF2F2F2);
  static const textSecondary= Color(0xFFA8A8A8);

  // Accents
  static const sliderActive = Color(0xFFF58A33);
  static const success      = Color(0xFF38C172);
  static const error        = Color(0xFFE74C3C);

  // Extras derived from palette
  static const divider      = Color(0xFF3A3A3D);
  static const cardBorder   = Color(0xFF3A3A3D);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary:   AppColors.activeBtn,
        secondary: AppColors.sliderActive,
        surface:   AppColors.card,
        error:     AppColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor:      AppColors.text,
        displayColor:   AppColors.text,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor:   AppColors.sliderActive,
        inactiveTrackColor: AppColors.inactiveBtn,
        thumbColor:         AppColors.sliderActive,
        overlayColor:       Color(0x33F58A33),
        valueIndicatorColor: AppColors.activeBtn,
        valueIndicatorTextStyle: TextStyle(color: Colors.white),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.activeBtn : AppColors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.activeBtn.withOpacity(0.4)
              : AppColors.inactiveBtn,
        ),
      ),
      dividerColor: AppColors.divider,
      useMaterial3: true,
    );
  }
}
