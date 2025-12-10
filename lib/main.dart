import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'features/pantry/data/pantry_repository.dart';
import 'features/pantry/bloc/pantry_cubit.dart';
import 'features/recipes/data/recipes_repository.dart';
import 'features/recipes/bloc/recipes_cubit.dart';
import 'features/schedule/data/schedule_repository.dart';
import 'features/schedule/bloc/schedule_cubit.dart';
import 'core/constants/app_strings.dart';
import 'features/auth/screens/splash_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await GoogleSignIn.instance.initialize(
    serverClientId: "746157274071-g3vbf97gfl5j87hv0jiqtlvberj3un0k.apps.googleusercontent.com",
  );
  
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final pantryRepository = PantryRepository();
    final recipesRepository = RecipesRepository();
    final scheduleRepository = ScheduleRepository();

    return MultiBlocProvider(
      providers: [
        BlocProvider<PantryCubit>(
          create: (context) => PantryCubit(pantryRepository),
        ),
        BlocProvider<RecipesCubit>(
          create: (context) => RecipesCubit(recipesRepository),
        ),
        BlocProvider<ScheduleCubit>(
          create: (context) => ScheduleCubit(scheduleRepository),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appTitle,
        theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7F32B5),
          primary: const Color(0xFF7F32B5),
          onPrimary: Colors.white,
          secondary: Colors.white,
          onSecondary: Colors.black,
          outline: const Color(0xFFEDF1F3),
          tertiary: const Color(0x4CD9D9D9),
          onTertiary: Color(0xFF6C7278),
          error: const Color(0xFFD20000),
          onError: Colors.white,
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            foregroundColor: Colors.black,
            backgroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade100,
          ),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      ),
    );
  }
}