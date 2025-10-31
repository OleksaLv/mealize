import 'package:flutter/material.dart';

import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/social_auth_button.dart';
import '../widgets/divider_with_text.dart';
import '../widgets/auth_navigation_text.dart';

import 'register_screen.dart';
import 'schedule_screen.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
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
                const AppTextField(
                  labelText: 'Email',
                  hintText: 'emailaddress@gmail.com',
                ),
                const SizedBox(height: 20),
                const AppTextField(
                  labelText: 'Password',
                  hintText: '********',
                  obscureText: true,
                ),
                const SizedBox(height: 40),
                PrimaryButton(
                  text: 'Log In',
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const ScheduleScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                const DividerWithText(text: 'Or'),
                const SizedBox(height: 30),
                SocialAuthButton(
                  text: 'Continue with Google',
                  iconPath: 'assets/icons/google_logo.png',
                  onPressed: () {},
                ),
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.center,
                  child: AuthNavigationText(
                    text: "Don't have account?",
                    buttonText: 'Sign Up',
                    onTap: () {
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