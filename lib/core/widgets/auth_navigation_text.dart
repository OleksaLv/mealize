import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AuthNavigationText extends StatelessWidget {
  const AuthNavigationText({
    super.key,
    required this.text,
    required this.buttonText,
    this.onTap,
  });

  /// Звичайний текст
  final String text;

  /// Текст для кнопки
  final String buttonText;

  /// Функція, що спрацює при натисканні на кнопку
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Text.rich для поєднання різних стилів тексту в одному рядку
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 14,
        ),
        children: [
          // Звичайний текст
          TextSpan(
            text: text,
            style: const TextStyle(color: Colors.black54),
          ),
          // Пробіл між текстами
          const WidgetSpan(child: SizedBox(width: 4)),
          // Клікабельний текст
          TextSpan(
            text: buttonText,
            style: TextStyle(
              // Колір з теми
              color: Theme.of(context).colorScheme.primary, 
              fontWeight: FontWeight.bold,
            ),
            // Обробник натискання
            recognizer: TapGestureRecognizer()..onTap = onTap,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}