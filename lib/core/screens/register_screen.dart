import 'package:flutter/material.dart';

// Імпорт кастомних віджети
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/social_auth_button.dart';
import '../widgets/divider_with_text.dart';
import '../widgets/auth_navigation_text.dart';
import '../widgets/custom_app_bar.dart';

// Імпорту екрану для навігації
import 'main_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // На відміну від LoginScreen, Scaffold з AppBar
    return Scaffold(
      backgroundColor: Colors.white,
      
      // Кнопка "назад" з'явиться автоматично, бо перейшли сюди через Navigator.push
      appBar: const CustomAppBar(),
      
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Відступ зверху вже не потрібен, є AppBar

                // Заголовок "Sign up"
                const Text(
                  'Sign up',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Create an account to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 40),

                // Поле електронної пошти
                const AppTextField(
                  labelText: 'Email',
                  hintText: 'emailaddress@gmail.com',
                ),
                const SizedBox(height: 20),

                // Поле пароля
                const AppTextField(
                  labelText: 'Password',
                  hintText: '********',
                  obscureText: true,
                ),
                const SizedBox(height: 20),

                // Поле повтору пароля
                const AppTextField(
                  labelText: 'Repeat password',
                  hintText: '********',
                  obscureText: true,
                ),
                const SizedBox(height: 40),

                // Кнопка "Register"
                PrimaryButton(
                  text: 'Register',
                  onPressed: () {
                    // Після реєстрації перехід на головний екран
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),

                // Розділювач "Or"
                const DividerWithText(text: 'Or'),
                const SizedBox(height: 30),

                // Кнопка Google
                SocialAuthButton(
                  text: 'Continue with Google',
                  iconPath: 'assets/icons/google_logo.png',
                  onPressed: () {
                    // Логіка реєстрації через Google
                  },
                ),
                const SizedBox(height: 40),

                // Текст-навігація "Log In"
                Align(
                  alignment: Alignment.center,
                  child: AuthNavigationText(
                    text: "Already have an account?",
                    buttonText: 'Log In',
                    onTap: () {
                      // Просто повертаємось на попередній екран (LoginScreen)
                      Navigator.of(context).pop();
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
