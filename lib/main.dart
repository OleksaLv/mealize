import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'features/pantry/data/pantry_repository.dart';
import 'features/pantry/bloc/pantry_cubit.dart';
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

    return MultiBlocProvider(
      providers: [
        BlocProvider<PantryCubit>(
          create: (context) => PantryCubit(pantryRepository),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appTitle,
        theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7F32B5),
          primary: const Color(0xFF7F32B5),
          onPrimary: Colors.white,
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