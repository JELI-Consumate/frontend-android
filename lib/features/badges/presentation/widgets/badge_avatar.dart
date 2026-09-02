import 'package:flutter/material.dart' hide Badge;

import '../../../../core/theme/app_colors.dart';
import '../../data/models/badge.dart';

class BadgeAvatar extends StatelessWidget {
  const BadgeAvatar({super.key, required this.badge, this.size = 56});

  final Badge badge;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconUrl = badge.iconUrl;
    final fallback = Icon(
      Icons.workspace_premium,
      size: size * 0.5,
      color: badge.earned ? AppColors.primary : AppColors.inkMuted,
    );

    return Opacity(
      opacity: badge.earned ? 1 : 0.5,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: badge.earned ? AppColors.primarySoft : AppColors.border,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: iconUrl == null || iconUrl.isEmpty
              ? fallback
              : Image.network(
                  iconUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}
