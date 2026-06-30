import 'package:flutter/material.dart';

class SenhaField extends StatefulWidget {
  const SenhaField({
    super.key,
    required this.controller,
    required this.labelText,
    this.textInputAction,
    this.validator,
    this.serverErrorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String labelText;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final String? serverErrorText;
  final ValueChanged<String>? onChanged;

  @override
  State<SenhaField> createState() => _SenhaFieldState();
}

class _SenhaFieldState extends State<SenhaField> {
  bool _obscure = true;

  String? _validate(String? value) {
    if (widget.serverErrorText != null) return widget.serverErrorText;
    return widget.validator?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: _validate,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.labelText,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
