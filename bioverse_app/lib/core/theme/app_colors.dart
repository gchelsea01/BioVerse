import 'package:flutter/material.dart';

/// Palette read from the Figma file (Dev Mode, "Prototype User - Phone"),
/// ordered by how often each color is used there.
///
/// One deliberate change: Figma's primary teal #2CACAF carries white text at
/// only 2.75:1 contrast (usability feedback: "buttons are too faint"), so
/// filled buttons use [primary], the same hue darkened to 5.1:1. #2CACAF is
/// kept as [accent] for icons, progress bars, and highlights.
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF1A7A7D); // filled buttons, active states
  static const accent = Color(0xFF2CACAF); // Figma primary teal
  static const primaryLight = Color(0xFF75E2DF);
  static const navy = Color(0xFF03354C); // headings, dark buttons
  static const deepTeal = Color(0xFF024D62);
  static const mint = Color(0xFFDAF4F1); // tinted cards
  static const mintStrong = Color(0xFFC5E5E1);

  // Surfaces
  static const background = Color(0xFFF3FBFB);
  static const surface = Colors.white;
  static const border = Color(0xFFCCEAE7);

  // Text
  static const text = Color(0xFF1D1D1D);
  static const textMuted = Color(0xFF555555);

  // Gamification
  static const coin = Color(0xFFF2B705);
  static const coinBg = Color(0xFFFFF6CC);
  static const streak = Color(0xFFE85D3F);
  static const streakBg = Color(0xFFFFEFEF);

  // Ecosystems (from the coral / tree mascots)
  static const coral = Color(0xFF2F97E1);
  static const mangrove = Color(0xFF2CACAF);
  static const tree = Color(0xFF56915A);

  // Pet card gradient (Figma "Ver Coral Pet")
  static const petGradient = [Color(0xFFDFF7F4), Color(0xFF9FE5DF), Color(0xFF4BB9B9)];

  // Status
  static const success = Color(0xFF1B6A3E);
  static const successBg = Color(0xFFE1F3E8);
  static const warning = Color(0xFFB7791F);
  static const warningBg = Color(0xFFFDF1DC);
  static const danger = Color(0xFFBF555B);
  static const dangerBg = Color(0xFFFFF2F2);
  static const neutralBg = Color(0xFFEFF5F4);
}
