import 'package:flutter/material.dart';

// Імпорт кастомних віджетів
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/social_auth_button.dart';
import '../widgets/divider_with_text.dart';
import '../widgets/auth_navigation_text.dart';

// Імпорт екранів для навігації
import 'register_screen.dart';
import 'main_screen.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // SafeArea, щоб контент не заходив під статус-бар
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // SingleChildScrollView, щоб екран можна було скролити, коли з'явиться клавіатура
        child: SingleChildScrollView(
          child: Padding(
            // Відступи зліва і справа
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Відступ зверху
                const SizedBox(height: 60),

                // Заголовок "Sign in..."
                const Text(
                  'Sign in to your\naccount',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter your email and password to log in',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 40),

                // Кастомний віджет поля для Email
                const AppTextField(
                  hintText: 'emailaddress@gmail.com',
                ),
                const SizedBox(height: 20),

                // Кастомний віджет поля для Пароля
                const AppTextField(
                  hintText: '********',
                  obscureText: true,
                ),
                const SizedBox(height: 40),

                // Кастомна кнопка "Log In"
                PrimaryButton(
                  text: 'Log In',
                  onPressed: () {
                    // Тимчасова навігація на головний екран
                    // pushReplacement, щоб не можна було повернутися назад на екран логіну
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),

                // Кастомний розділювач "Or"
                const DividerWithText(text: 'Or'),
                const SizedBox(height: 30),

                // Кастомна кнопка Google
                SocialAuthButton(
                  text: 'Continue with Google',
                  iconPath: 'assets/icons/google_logo.png',
                  onPressed: () {
                    // Логіка входу через Google
                  },
                ),
                const SizedBox(height: 40),

                // Кастомний текст-навігація
                Align(
                  alignment: Alignment.center,
                  child: AuthNavigationText(
                    text: "Don't have account?",
                    buttonText: 'Sign Up',
                    onTap: () {
                      // Навігація на екран реєстрації
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}