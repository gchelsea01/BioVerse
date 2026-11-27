import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// From Figma: primary buttons and inputs use 14, cards use 10.
  static const radius = 14.0;
  static const cardRadius = 10.0;

  /// Design system fonts: Nunito for headings, Inter for everything else.
  static const bodyFont = 'Inter';
  static const headingFont = 'Nunito';

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      surface: AppColors.surface,
      error: AppColors.danger,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: bodyFont);
    final textTheme = base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );
    TextStyle? heading(TextStyle? s, FontWeight w, double size) =>
        s?.copyWith(fontFamily: headingFont, fontWeight: w, fontSize: size, color: AppColors.navy, letterSpacing: -0.3);
    TextStyle? body(TextStyle? s, double size, [FontWeight? w]) => s?.copyWith(fontSize: size, fontWeight: w);

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme.copyWith(
        // Figma sizes: page title 24/800, money 32/700, section 16/700,
        // card value 14/700. Figma's 8-11px captions are raised to 11-12px
        // so they stay readable on Android.
        displaySmall: heading(textTheme.displaySmall, FontWeight.w800, 32),
        headlineLarge: heading(textTheme.headlineLarge, FontWeight.w800, 30),
        headlineMedium: heading(textTheme.headlineMedium, FontWeight.w800, 28),
        headlineSmall: heading(textTheme.headlineSmall, FontWeight.w800, 24),
        titleLarge: heading(textTheme.titleLarge, FontWeight.w800, 18),
        titleMedium: body(textTheme.titleMedium, 16, FontWeight.w700),
        titleSmall: body(textTheme.titleSmall, 14, FontWeight.w700),
        bodyLarge: body(textTheme.bodyLarge, 15),
        bodyMedium: body(textTheme.bodyMedium, 14),
        bodySmall: body(textTheme.bodySmall, 12),
        labelLarge: body(textTheme.labelLarge, 14, FontWeight.w600),
        labelMedium: body(textTheme.labelMedium, 12, FontWeight.w600),
        labelSmall: body(textTheme.labelSmall, 11, FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.navy,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontFamily: headingFont,
          fontSize: 22, // Figma page titles are 24; 22 leaves room for app bar actions
          letterSpacing: -0.3,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.mintStrong,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size.fromHeight(52),
          shape: shape,
          // Figma: box-shadow 0 8px 18px rgba(44,172,175,0.18)
          elevation: 3,
          shadowColor: AppColors.accent.withValues(alpha: 0.5),
          textStyle: textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: shape,
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.navy,
        side: const BorderSide(color: AppColors.border),
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.mint,
        surfaceTintColor: Colors.transparent,
        height: 70,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? AppColors.navy : AppColors.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? AppColors.navy : AppColors.textMuted,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
    );
  }
}
