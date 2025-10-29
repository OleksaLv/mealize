import 'package:flutter/material.dart';
import 'core/screens/splash_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mealize',
      theme: ThemeData(
        // Налаштовуємо головні кольори теми
        colorScheme: ColorScheme.fromSeed(
          // Це фіолетовий, схожий на твій дизайн
          seedColor: const Color(0xFF7F32B5), 
          // Вказуємо його як основний
          primary: const Color(0xFF7F32B5), 
          // Вказуємо, що текст на ньому має бути білим
          onPrimary: Colors.white, 
        ),
        // Використовуємо дизайн Material 3
        useMaterial3: true,
      ),

      // Splashscreen як домашній екран
      home: const SplashScreen(),

      // Прибирати банер "Debug" у кутку
      debugShowCheckedModeBanner: false, 
    );
  }
}