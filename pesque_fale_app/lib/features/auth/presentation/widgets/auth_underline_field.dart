import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AuthUnderlineField extends StatelessWidget {
  const AuthUnderlineField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.serverErrorText,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final String? serverErrorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  String? _validate(String? value) {
    if (serverErrorText != null) return serverErrorText;
    return validator?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: _validate,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Icon(icon, color: colors.primary, size: 20),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.danger, width: 1.5),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.danger, width: 2),
        ),
        labelStyle: TextStyle(color: colors.textSecondary),
        floatingLabelStyle: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
