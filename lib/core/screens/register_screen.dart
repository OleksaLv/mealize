import 'package:flutter/material.dart';

import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/social_auth_button.dart';
import '../widgets/divider_with_text.dart';
import '../widgets/auth_navigation_text.dart';
import '../widgets/custom_app_bar.dart';

import 'schedule_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,      
      appBar: const CustomAppBar(),
      
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 20),
                const AppTextField(
                  labelText: 'Repeat password',
                  hintText: '********',
                  obscureText: true,
                ),
                const SizedBox(height: 40),
                PrimaryButton(
                  text: 'Register',
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
                  onPressed: () {
                  },
                ),
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.center,
                  child: AuthNavigationText(
                    text: "Already have an account?",
                    buttonText: 'Log In',
                    onTap: () {
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
