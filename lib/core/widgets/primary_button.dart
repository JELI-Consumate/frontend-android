import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon = Icons.arrow_forward,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;

  final IconData? trailingIcon;

  final bool isLoading;

  final bool expand;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    final button = FilledButton(
      onPressed: isEnabled ? onPressed : null,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label),
                if (trailingIcon != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(trailingIcon, size: 18),
                ],
              ],
            ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: isEnabled ? AppShadows.button : null,
      ),
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}
