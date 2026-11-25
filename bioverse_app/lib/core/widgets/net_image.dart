import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Network image with a soft placeholder; never shows a broken-image icon.
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.height, this.width, this.radius = 12, this.fit = BoxFit.cover, this.icon});

  final String? url;
  final double? height;
  final double? width;
  final double radius;
  final BoxFit fit;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // Fill the available width unless told otherwise; inside a Stack the
    // image would otherwise shrink to its intrinsic size.
    final width = this.width ?? double.infinity;
    final placeholder = Container(
      height: height,
      width: width,
      color: AppColors.mint,
      alignment: Alignment.center,
      child: Icon(icon ?? Icons.landscape_rounded, color: AppColors.primaryLight, size: 32),
    );
    final u = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: (u == null || u.isEmpty)
          ? placeholder
          : Builder(builder: (context) {
              // Download and decode at display size, not the multi-MB original.
              // (No LayoutBuilder: it breaks inside IntrinsicHeight.)
              final dpr = MediaQuery.devicePixelRatioOf(context);
              final w = this.width;
              final shown = (w != null && w.isFinite) ? w : MediaQuery.sizeOf(context).width;
              final px = (shown * dpr).round().clamp(64, 1600);
              return CachedNetworkImage(
                imageUrl: sizedImageUrl(u, px),
                memCacheWidth: px,
                height: height,
                width: width,
                fit: fit,
              placeholder: (_, _) => placeholder,
                errorWidget: (_, _, _) => placeholder,
              );
            }),
    );
  }
}

/// Asks image CDNs that support it (Unsplash) for a resized, compressed
/// version. Other URLs are returned unchanged.
String sizedImageUrl(String url, int widthPx) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host != 'images.unsplash.com' || uri.queryParameters.containsKey('w')) return url;
  return uri.replace(queryParameters: {
    ...uri.queryParameters,
    'w': '$widthPx',
    'q': '70',
    'auto': 'format',
    'fit': 'crop',
  }).toString();
}
