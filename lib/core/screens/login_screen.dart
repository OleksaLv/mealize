import 'package:flutter/material.dart';
import '../constants/app_strings.dart';
import '../services/auth_repository.dart';

import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/social_auth_button.dart';
import '../widgets/divider_with_text.dart';
import '../widgets/auth_navigation_text.dart';

import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authRepository.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _authRepository.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    AppStrings.signInTitle,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.signInSubtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 40),
                  AppTextField(
                    controller: _emailController,
                    labelText: AppStrings.email,
                    hintText: AppStrings.emailHint,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.emailEmptyError;
                      }
                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                        return AppStrings.emailInvalidError;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _passwordController,
                    labelText: AppStrings.password,
                    hintText: AppStrings.passwordHint,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.passwordEmptyError;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  PrimaryButton(
                    text: _isLoading ? AppStrings.loggingIn : AppStrings.logIn,
                    onPressed: _isLoading ? null : _submitLogin,
                  ),
                  const SizedBox(height: 30),
                  const DividerWithText(text: AppStrings.or),
                  const SizedBox(height: 30),
                  SocialAuthButton(
                    text: AppStrings.continueWithGoogle,
                    iconPath: 'assets/icons/google_logo.png',
                    onPressed: _isLoading ? null : _submitGoogleSignIn,
                  ),
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.center,
                    child: AuthNavigationText(
                      text: AppStrings.noAccount,
                      buttonText: AppStrings.signUp,
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
      ),
    );
  }
}