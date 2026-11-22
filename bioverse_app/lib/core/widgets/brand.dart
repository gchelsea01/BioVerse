import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const appTagline = 'Restore nature, daily.';

/// Logo mark + wordmark. Uses `assets/images/logo_mark.png` when exported
/// from Figma; falls back to an icon.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 28, this.showName = true, this.light = false});
  final double size;
  final bool showName;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : AppColors.navy;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Image.asset(
        'assets/images/logo_mark.png',
        height: size,
        errorBuilder: (_, _, _) => Icon(Icons.all_inclusive_rounded, size: size, color: light ? Colors.white : AppColors.primary),
      ),
      if (showName) ...[
        SizedBox(width: size * 0.3),
        Text('BioVerse', style: TextStyle(fontSize: size * 0.8, fontWeight: FontWeight.w800, color: color)),
      ],
    ]);
  }
}
