import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.user, this.radius = 32});
  final UserProfile? user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = user?.avatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.navy,
      foregroundImage: url != null ? CachedNetworkImageProvider(url) : null,
      child: Text(
        user?.initials ?? '?',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: radius * 0.6),
      ),
    );
  }
}
