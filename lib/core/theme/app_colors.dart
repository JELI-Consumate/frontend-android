import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF0037B0);
  static const Color ink = Color(0xFF434655);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color muted = Color(0xFFC4C5D7);
  static const Color background = Color(0xFFF8F9FF);
  static const Color primaryPressed = Color(0xFF002B8C);
  static const Color danger = Color(0xFFD1344B);
  static const Color success = Color(0xFF1E9E5A);
  static const Color warning = Color(0xFFE9A23B);
  static Color get primarySoft => primary.withValues(alpha: 0.08);
  static Color get dangerSoft => danger.withValues(alpha: 0.12);
  static Color get successSoft => success.withValues(alpha: 0.12);
  static Color get warningSoft => warning.withValues(alpha: 0.12);
  static Color get inkMuted => ink.withValues(alpha: 0.75);
  static Color get border => muted.withValues(alpha: 0.5);
}
