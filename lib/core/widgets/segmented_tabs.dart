import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.activeIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (index) {
        final isActive = index == activeIndex;

        return Expanded(
          child: Semantics(
            button: true,
            selected: isActive,
            child: InkWell(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: AppDuration.fast,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? AppColors.primary : AppColors.border,
                      width: isActive ? 2.5 : 1,
                    ),
                  ),
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: isActive
                      ? AppTypography.titleMedium.copyWith(
                          color: AppColors.primary,
                        )
                      : AppTypography.bodyMedium.copyWith(
                          color: AppColors.inkMuted,
                        ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
