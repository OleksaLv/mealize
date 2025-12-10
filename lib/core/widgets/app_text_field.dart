import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.labelText,
    this.hintText,
    this.obscureText = false,
    this.controller,
    this.validator,
    this.enabled = true,
  });

  /// Підпис, який відображається над полем
  final String labelText;

  /// Підказка, яка відображається у полі
  final String? hintText;
  final bool obscureText;
  final TextEditingController? controller;

  final String? Function(String?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Віджет для підпису над полем
        Text(
          labelText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        // Відступ між підписом та полем вводу
        const SizedBox(height: 8),

        // Текстове поле
        TextFormField(
          enabled: enabled,
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onTertiary),
            filled: true,
            fillColor: enabled ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.tertiary,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 18,
            ),
          ),
        ),
      ],
    );
  }
}