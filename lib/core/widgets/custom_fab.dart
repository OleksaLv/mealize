import 'package:flutter/material.dart';

class CustomFAB extends StatelessWidget {
  const CustomFAB({
    super.key,
    this.onPressed,
  });

  /// Функція, що викликається при натисканні
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Стандартний віджет FloatingActionButton
    return FloatingActionButton(
      onPressed: onPressed,
      
      // Колір фону кнопки з теми
      backgroundColor: Theme.of(context).colorScheme.primary,
      
      // Колір іконки з теми
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      
      // Стандартна кругла форма для FAB
      shape: const CircleBorder(),
      
      // Іконка "плюс"
      child: const Icon(
        Icons.add,
        size: 32,
      ),
    );
  }
}