import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Large, high-contrast input decoration used by every form field.
InputDecoration bigInputDecoration(
  BuildContext context, {
  required String label,
  String? hint,
  bool required = false,
}) {
  final text = Theme.of(context).textTheme;
  return InputDecoration(
    labelText: required ? '$label *' : label,
    hintText: hint,
    labelStyle: text.bodyLarge,
    floatingLabelStyle: text.titleLarge,
    errorStyle: text.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.error,
    ),
    filled: true,
    border: const OutlineInputBorder(),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
  );
}

class BigTextField extends StatelessWidget {
  const BigTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.required = false,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final String? Function(String value)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: Theme.of(context).textTheme.titleLarge,
      decoration: bigInputDecoration(
        context,
        label: label,
        hint: hint,
        required: required,
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      textInputAction: TextInputAction.next,
      validator: (raw) {
        final value = raw?.trim() ?? '';
        if (required && value.isEmpty) return 'Kailangan ito';
        if (value.isEmpty) return null;
        return validator?.call(value);
      },
    );
  }
}

class BigDropdownField extends StatelessWidget {
  const BigDropdownField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      style: Theme.of(context).textTheme.titleLarge,
      decoration: bigInputDecoration(context, label: label, required: required),
      items: [
        for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
      ],
      onChanged: onChanged,
      validator: (v) => required && v == null ? 'Pumili ng isa' : null,
    );
  }
}

/// Section title inside long forms.
class FormSectionTitle extends StatelessWidget {
  const FormSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}
