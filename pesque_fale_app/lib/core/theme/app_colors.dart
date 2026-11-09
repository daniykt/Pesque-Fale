import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.primaryAccent,
    required this.onPrimaryAccent,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.onSuccess,
    required this.danger,
    required this.onDanger,
    required this.warning,
    required this.onWarning,
    required this.action,
    required this.navInactive,
    required this.badge,
    required this.rating,
  });

  /// Cor de marca para FUNDOS (AppBar, botões, chips ativos). Conteúdo por
  /// cima sempre branco. Não usar como cor de texto/ícone sobre
  /// background/surface.
  final Color primary;

  /// Cor de destaque para TEXTO, ÍCONE, BORDA e INDICADOR sobre
  /// background/surface. Mesmo valor do primary no claro; azul claro no
  /// escuro.
  final Color primaryAccent;

  /// Conteúdo (texto/ícone) sobre um preenchimento [primaryAccent].
  final Color onPrimaryAccent;

  final Color background;
  final Color surface;

  /// Superfície secundária (cards de comentário, inputs, hover states).
  final Color surfaceVariant;

  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  final Color success;

  /// Conteúdo sobre um preenchimento [success].
  final Color onSuccess;

  final Color danger;

  /// Conteúdo sobre um preenchimento [danger].
  final Color onDanger;

  final Color warning;

  /// Conteúdo sobre um preenchimento [warning].
  final Color onWarning;

  final Color action;

  final Color navInactive;

  final Color badge;

  /// Estrela de avaliação preenchida.
  final Color rating;

  static const light = AppColors(
    primary: Color(0xFF062A6C),
    primaryAccent: Color(0xFF062A6C),
    onPrimaryAccent: Color(0xFFFFFFFF),
    background: Color(0xFFF5F5F5),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1F5F9),
    border: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    success: Color(0xFF1B5E20),
    onSuccess: Color(0xFFFFFFFF),
    danger: Color(0xFFB91C1C),
    onDanger: Color(0xFFFFFFFF),
    warning: Color(0xFFF5B342),
    onWarning: Color(0xFF121212),
    action: Color(0xFF062A6C),
    navInactive: Color(0xFF6B7280),
    badge: Color(0xFFE3001B),
    rating: Color(0xFFB45309),
  );

  static const dark = AppColors(
    primary: Color(0xFF062A6C),
    primaryAccent: Color(0xFF90CAF9),
    onPrimaryAccent: Color(0xFF062A6C),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceVariant: Color(0xFF2A2A2A),
    border: Color(0xFF333333),
    textPrimary: Color(0xFFF1F1F1),
    textSecondary: Color(0xFFB0B0B0),
    success: Color(0xFF66BB6A),
    onSuccess: Color(0xFF121212),
    danger: Color(0xFFF08080),
    onDanger: Color(0xFF121212),
    warning: Color(0xFFF5B342),
    onWarning: Color(0xFF121212),
    action: Color(0xFF2563EB),
    navInactive: Color(0xFF8A8A8A),
    badge: Color(0xFFE3001B),
    rating: Color(0xFFFFB300),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? primaryAccent,
    Color? onPrimaryAccent,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? onSuccess,
    Color? danger,
    Color? onDanger,
    Color? warning,
    Color? onWarning,
    Color? action,
    Color? navInactive,
    Color? badge,
    Color? rating,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      primaryAccent: primaryAccent ?? this.primaryAccent,
      onPrimaryAccent: onPrimaryAccent ?? this.onPrimaryAccent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      action: action ?? this.action,
      navInactive: navInactive ?? this.navInactive,
      badge: badge ?? this.badge,
      rating: rating ?? this.rating,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
      onPrimaryAccent: Color.lerp(onPrimaryAccent, other.onPrimaryAccent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      action: Color.lerp(action, other.action, t)!,
      navInactive: Color.lerp(navInactive, other.navInactive, t)!,
      badge: Color.lerp(badge, other.badge, t)!,
      rating: Color.lerp(rating, other.rating, t)!,
    );
  }
}
