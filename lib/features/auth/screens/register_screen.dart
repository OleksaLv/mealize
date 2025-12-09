import 'package:flutter/material.dart';
import 'package:mealize/core/constants/app_strings.dart';
import 'package:mealize/core/services/auth_repository.dart';

import 'package:mealize/core/widgets/app_text_field.dart';
import 'package:mealize/core/widgets/primary_button.dart';
import 'package:mealize/core/widgets/social_auth_button.dart';
import 'package:mealize/core/widgets/divider_with_text.dart';
import 'package:mealize/core/widgets/auth_navigation_text.dart';
import 'package:mealize/core/widgets/custom_app_bar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authRepository.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
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
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
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
      appBar: const CustomAppBar(leading: BackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.signUpTitle,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.signUpSubtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onTertiary,
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
                      if (value.length < 6) {
                        return AppStrings.passwordLengthError;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _repeatPasswordController,
                    labelText: AppStrings.repeatPassword,
                    hintText: AppStrings.passwordHint,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.passwordRepeatError;
                      }
                      if (value != _passwordController.text) {
                        return AppStrings.passwordMismatchError;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  PrimaryButton(
                    text: _isLoading ? AppStrings.registering : AppStrings.register,
                    onPressed: _isLoading ? null : _submitRegister,
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
                      text: AppStrings.haveAccount,
                      buttonText: AppStrings.logIn,
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
      ),
    );
  }
}