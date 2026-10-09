import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Large input decoration; colors, fill, borders and radii come from the
/// theme's InputDecorationTheme.
InputDecoration bigInputDecoration(
  BuildContext context, {
  required String label,
  String? hint,
  bool required = false,
}) {
  return InputDecoration(
    labelText: required ? '$label *' : label,
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
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
  const FormSectionTitle(this.title, {super.key, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: scheme.primary, size: 26),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ],
      ),
    );
  }
}
