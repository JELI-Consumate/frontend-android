import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class AgencyLogo extends StatelessWidget {
  const AgencyLogo({super.key, required this.logoUrl, this.size = 56});

  final String? logoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = logoUrl;
    final fallback = Icon(
      Icons.account_balance_outlined,
      size: size * 0.45,
      color: AppColors.primary,
    );

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: url == null || url.isEmpty
            ? fallback
            : Padding(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                child: Image.network(
                  url,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => fallback,
                ),
              ),
      ),
    );
  }
}
