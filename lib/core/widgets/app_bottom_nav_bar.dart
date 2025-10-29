import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// Індекс поточної вибраної вкладки
  final int currentIndex;

  /// Функція, що викликається при натисканні на вкладку
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    // Стандартний віджет BottomNavigationBar
    return BottomNavigationBar(
      // Поточний індекс, щоб віджет знав, яку іконку підсвітити
      currentIndex: currentIndex,
      onTap: onTap,
      
      // Колір вибраної іконки з теми
      selectedItemColor: Theme.of(context).colorScheme.primary,
      // Колір невибраних іконок
      unselectedItemColor: Colors.grey.shade600,

      showSelectedLabels: true,
      showUnselectedLabels: true,

      selectedFontSize: 12.0,
      unselectedFontSize: 12.0,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),

      // Тип фіксований, щоб іконки не "стрибали"
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      backgroundColor: Colors.white,

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          activeIcon: Icon(Icons.calendar_month),
          label: 'schedule',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2),
          label: 'pantry',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined),
          activeIcon: Icon(Icons.menu_book),
          label: 'recipes',
        ),
      ],
    );
  }
}