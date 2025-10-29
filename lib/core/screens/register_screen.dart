import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(
        // AppBar матиме кнопку "назад" автоматично
      ),
      body: Center(
        child: Text('Register Screen'),
      ),
    );
  }
}