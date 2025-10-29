import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
  });

  // Необов'язковий віджет для заголовка, щоб передати і логотип чи кнопки в разі потреби
  final Widget? title;

  /// Віджет, що відображається зліва (кнопка "назад" або "меню").
  final Widget? leading;

  /// Список віджетів, що відображаються справа (напр., іконки профілю).
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Забираємо тінь
      elevation: 0,
      scrolledUnderElevation: 0,
      
      // Фон прозорий, щоб він брав колір Scaffold
      backgroundColor: Colors.transparent,
      
      // Колір іконок та тексту за замовчуванням (для кнопки "назад")
      foregroundColor: Colors.black,

      // Автоматично додавати кнопку "назад", якщо можна
      automaticallyImplyLeading: true, 

      // Віджет зліва
      leading: leading,

      // Віджет-заголовок
      title: title,

      // Список віджетів справа
      actions: actions,
      
      centerTitle: true,
    );
  }

  /// AppBar повинен знати свою бажану висоту.
  /// kToolbarHeight - стандартна висота AppBar у Flutter.
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}