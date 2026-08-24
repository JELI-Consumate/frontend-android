import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class PageDots extends StatelessWidget {
  const PageDots({
    super.key,
    required this.count,
    required this.activeIndex,
    this.onDotTap,
  });

  final int count;
  final int activeIndex;

  final void Function(int index)? onDotTap;

  static const double _size = 8;
  static const double _activeWidth = 8;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        final dot = AnimatedContainer(
          duration: AppDuration.normal,
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          height: _size,
          width: isActive ? _activeWidth : _size,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.muted,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        );

        if (onDotTap == null) return dot;

        return Semantics(
          button: true,
          selected: isActive,
          label: 'Halaman ${index + 1} dari $count',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onDotTap!(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: dot,
            ),
          ),
        );
      }),
    );
  }
}
