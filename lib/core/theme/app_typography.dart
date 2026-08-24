import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static const String fontFamily = 'PlusJakartaSans';

  static TextStyle _style({
    required double size,
    required FontWeight weight,
    required double height,
    required Color color,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle get displayLarge => _style(
    size: 30,
    weight: FontWeight.w800,
    height: 1.25,
    color: AppColors.primary,
    letterSpacing: -0.6,
  );

  static TextStyle get displayMedium => _style(
    size: 24,
    weight: FontWeight.w800,
    height: 1.3,
    color: AppColors.primary,
    letterSpacing: -0.4,
  );

  static TextStyle get displaySmall => _style(
    size: 20,
    weight: FontWeight.w700,
    height: 1.3,
    color: AppColors.primary,
    letterSpacing: -0.2,
  );

  static TextStyle get titleLarge => _style(
    size: 18,
    weight: FontWeight.w700,
    height: 1.6,
    color: AppColors.black,
  );

  static TextStyle get titleMedium => _style(
    size: 16,
    weight: FontWeight.w700,
    height: 1.4,
    color: AppColors.ink,
  );

  static TextStyle get titleSmall => _style(
    size: 14,
    weight: FontWeight.w600,
    height: 1.4,
    color: AppColors.ink,
  );

  static TextStyle get bodyLarge => _style(
    size: 15,
    weight: FontWeight.w400,
    height: 1.6,
    color: AppColors.ink,
  );

  static TextStyle get bodyMedium => _style(
    size: 14,
    weight: FontWeight.w400,
    height: 1.6,
    color: AppColors.ink,
  );

  static TextStyle get bodySmall => _style(
    size: 13,
    weight: FontWeight.w400,
    height: 1.55,
    color: AppColors.inkMuted,
  );

  static TextStyle get bodyHighlight => _style(
    size: 15,
    weight: FontWeight.w700,
    height: 1.6,
    color: AppColors.primary,
  );

  // ── Label — UI chrome kecil ──
  static TextStyle get labelLarge => _style(
    size: 15,
    weight: FontWeight.w600,
    height: 1.2,
    color: AppColors.white,
    letterSpacing: 0.1,
  );

  static TextStyle get labelMedium => _style(
    size: 13,
    weight: FontWeight.w500,
    height: 1.2,
    color: AppColors.ink,
  );

  /// BARU — untuk caption kecil ("5 Materi", "80%") dan label nav bar,
  /// yang di desain jelas lebih kecil dari labelMedium.
  static TextStyle get labelSmall => _style(
    size: 11,
    weight: FontWeight.w500,
    height: 1.3,
    color: AppColors.inkMuted,
  );
}
