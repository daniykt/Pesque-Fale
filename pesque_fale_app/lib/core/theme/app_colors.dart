import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.primaryAccent,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.danger,
    required this.warning,
    required this.action,
    required this.navInactive,
    required this.badge,
  });

  final Color primary;

  final Color primaryAccent;

  final Color background;
  final Color surface;

  /// Superfície secundária (cards de comentário, inputs, hover states).
  final Color surfaceVariant;

  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  final Color success;
  final Color danger;
  final Color warning;

  final Color action;

  final Color navInactive;

  final Color badge;

  static const light = AppColors(
    primary: Color(0xFF062A6C),
    primaryAccent: Color(0xFF062A6C),
    background: Color(0xFFF5F5F5),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1F5F9),
    border: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    success: Color(0xFF4CAF50),
    danger: Color(0xFFF44336),
    warning: Color(0xFFF5B342),
    action: Color(0xFF062A6C),
    navInactive: Color(0xFFB0B0B0),
    badge: Color(0xFFE3001B),
  );

  static const dark = AppColors(
    primary: Color(0xFF062A6C),
    primaryAccent: Color(0xFF90CAF9),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceVariant: Color(0xFF2A2A2A),
    border: Color(0xFF333333),
    textPrimary: Color(0xFFF1F1F1),
    textSecondary: Color(0xFFB0B0B0),
    success: Color(0xFF66BB6A),
    danger: Color(0xFFF08080),
    warning: Color(0xFFF5B342),
    action: Color(0xFF2563EB),
    navInactive: Color(0xFF4A4A4A),
    badge: Color(0xFFE3001B),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? primaryAccent,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? danger,
    Color? warning,
    Color? action,
    Color? navInactive,
    Color? badge,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      primaryAccent: primaryAccent ?? this.primaryAccent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      action: action ?? this.action,
      navInactive: navInactive ?? this.navInactive,
      badge: badge ?? this.badge,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      action: Color.lerp(action, other.action, t)!,
      navInactive: Color.lerp(navInactive, other.navInactive, t)!,
      badge: Color.lerp(badge, other.badge, t)!,
    );
  }
}
