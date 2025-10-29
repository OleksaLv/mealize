import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.hintText,
    this.obscureText = false, // За замовчуванням текст не приховано
    this.controller,
  });

  /// Підказка, яка відображається у полі
  final String hintText;

  /// Чи потрібно приховувати текст
  final bool obscureText;

  /// Контролер для керування текстом
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    // TextFormField для майбутньої валідації,
    // поки він працює як звичайний TextField.
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        // Стиль для тексту-підказки
        hintStyle: TextStyle(color: Colors.grey.shade500),

        // Задаємо колір фону поля вводу
        filled: true,
        fillColor: Colors.grey.shade100,

        // Стиль рамки
        border: OutlineInputBorder(
          // Таке ж заокруглення, як у кнопки
          borderRadius: BorderRadius.circular(30.0),
          // Рамка невидима
          borderSide: BorderSide.none, 
        ),

        // Внутрішні відступи для тексту
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 18,
        ),
      ),
    );
  }
}