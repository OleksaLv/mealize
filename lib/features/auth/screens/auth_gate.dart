import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_screen.dart';
import 'package:mealize/features/schedule/screens/schedule_screen.dart';
import 'package:mealize/features/schedule/bloc/schedule_cubit.dart';
import 'package:mealize/features/pantry/bloc/pantry_cubit.dart';
import 'package:mealize/features/recipes/bloc/recipes_cubit.dart';
import 'package:mealize/features/settings/bloc/settings_cubit.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _previouslyLoggedOut = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
           return Scaffold(
            body: Center(
              child: Text('Something went wrong: ${snapshot.error}'),
            ),
          );
        }

        if (snapshot.data != null) {
          if (_previouslyLoggedOut) {
            _previouslyLoggedOut = false;
            // Preload all cubits after login transition
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.read<ScheduleCubit>().loadSchedule();
                context.read<PantryCubit>().loadPantryItems();
                context.read<RecipesCubit>().loadRecipes();
                context.read<SettingsCubit>().loadSettings();
              }
            });
          }
          return const ScheduleScreen();
        } 
        else {
          _previouslyLoggedOut = true;
          return const LoginScreen();
        }
      },
    );
  }
}