import 'package:flutter/material.dart';
import 'dart:async'; // Для таймера
import 'login_screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  void _navigateToLogin() {
    // Таймер на 2 секунди
    Timer(const Duration(seconds: 2), () {
      // Перевірка, чи віджет ще існує, перед навігацією
      if (mounted) {
        // pushReplacement, щоб користувач не міг повернутися назад на Splash Screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: Center(
        child: Image.asset(
          'assets/images/app_logo.png',
          width: 150,
        ),
      ),
    );
  }
}