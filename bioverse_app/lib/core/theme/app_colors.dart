import 'package:flutter/material.dart';

/// Palette taken from the Figma prototype, with the primary action color
/// darkened so white button text passes WCAG AA (usability feedback: buttons
/// were too faint).
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF1F7178); // buttons, active states (5.6:1 on white)
  static const primaryLight = Color(0xFF6AAFB2); // accents, progress tracks
  static const navy = Color(0xFF17324A); // headings, strong buttons
  static const mint = Color(0xFFE4F1EF); // tinted cards
  static const mintStrong = Color(0xFFCFE6E3);

  // Surfaces
  static const background = Color(0xFFF4F9F8);
  static const surface = Colors.white;
  static const border = Color(0xFFD5E3E1);

  // Text
  static const text = Color(0xFF142B3B);
  static const textMuted = Color(0xFF5A6B75);

  // Gamification
  static const coin = Color(0xFFF2B705);
  static const coinBg = Color(0xFFFFF6D6);
  static const streak = Color(0xFFE85D3F);
  static const streakBg = Color(0xFFFDE8E2);

  // Ecosystems
  static const coral = Color(0xFF3E83D1);
  static const mangrove = Color(0xFF23907F);
  static const tree = Color(0xFF4E9A45);

  // Status
  static const success = Color(0xFF23824F);
  static const successBg = Color(0xFFE1F3E8);
  static const warning = Color(0xFFB7791F);
  static const warningBg = Color(0xFFFDF1DC);
  static const danger = Color(0xFFC93C3C);
  static const dangerBg = Color(0xFFFBE4E4);
  static const neutralBg = Color(0xFFECEFF1);
}
