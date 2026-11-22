import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand.dart';

/// Shown while the session restores. Tells first-time users what the app is
/// for (usability feedback: "opening the app, it's unclear what it does").
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const BrandMark(size: 44, light: true),
            const SizedBox(height: 12),
            Text(
              'Fund reef, mangrove & forest restoration.\nWatch it grow with real photos.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            ),
          ]),
        ),
      ),
    );
  }
}
