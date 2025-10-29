import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
  });

  /// Текст, що відображатиметься на кнопці
  final String text;

  /// Функція, яка буде викликана при натисканні.
  /// Якщо null, кнопка буде неактивною (disabled).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Кнопку на всю ширину
      width: double.infinity,
      // Задаємо фіксовану висоту, як у дизайні
      height: 56, 
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          // Основний колір з теми
          backgroundColor: Theme.of(context).colorScheme.primary,
          // Колір тексту з теми
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            // Робимо кути заокругленими, як у дизайні
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}