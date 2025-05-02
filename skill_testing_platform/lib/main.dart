import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_testing_platform/screens/auth_screen.dart';
import 'package:skill_testing_platform/screens/home_screen.dart';
import 'package:skill_testing_platform/screens/create_test_screen.dart';
import 'package:skill_testing_platform/screens/take_test_screen.dart';
import 'package:skill_testing_platform/screens/test_result_screen.dart';
import 'package:skill_testing_platform/screens/edit_test_screen.dart';
import 'package:skill_testing_platform/models/test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCJT8tEwAbXCVPTQBJc_f5fEpZ_xcguLb0",
        authDomain: "feedbackai-5c0b7.firebaseapp.com",
        projectId: "feedbackai-5c0b7",
        storageBucket: "feedbackai-5c0b7.firebasestorage.app",
        messagingSenderId: "225743670427",
        appId: "1:225743670427:web:dd1dac92983b6b7696ca3e",
      ),
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skill Testing Platform',
      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.transparent,
        cardTheme: const CardTheme(
          elevation: 4,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
        textTheme: TextTheme(
          headlineLarge: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          bodyLarge: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false, // Disable the debug banner
      home: const AuthWrapper(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/create_test': (context) => const CreateTestScreen(),
        '/take_test': (context) {
          final test = ModalRoute.of(context)!.settings.arguments as Test;
          return TakeTestScreen();
        },
        '/test_results': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return TestResultScreen(
            test: args['test'] as Test,
            answers: args['answers'] as Map<int, List<int>>,
            textControllers: args['textControllers'] as Map<int, TextEditingController>,
            score: args['score'] as int,
            total: args['total'] as int,
            summarizedFeedback: args['summarizedFeedback'] as String,
          );
        },
        '/edit_test': (context) {
          final test = ModalRoute.of(context)!.settings.arguments as Test;
          return EditTestScreen(test: test);
        },
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          // User is logged in, navigate to HomeScreen
          return const HomeScreen();
        } else {
          // User is not logged in, navigate to AuthScreen
          return const AuthScreen();
        }
      },
    );
  }
}