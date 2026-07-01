import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.textInputAction,
    this.validator,
    this.serverErrorText,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final String? serverErrorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscure = true;
  bool _hasFocus = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() => _hasFocus = _focusNode.hasFocus);
  void _onTextChange() => setState(() {});

  String? _validate(String? value) {
    if (widget.serverErrorText != null) return widget.serverErrorText;
    return widget.validator?.call(value);
  }

  bool get _showEye => _hasFocus || widget.controller.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: _validate,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: GestureDetector(
          onTap: _showEye ? () => setState(() => _obscure = !_obscure) : null,
          child: Icon(
            _showEye
                ? (_obscure ? Icons.visibility_off : Icons.visibility)
                : Icons.lock_outline,
            color: colors.primary,
            size: 20,
          ),
        ),
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
