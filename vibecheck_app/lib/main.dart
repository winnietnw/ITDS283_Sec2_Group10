// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/task_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/emotion_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/timer_running_screen.dart';
import 'screens/forgot_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,); // เชื่อม Firebase
  runApp(const VibeCheckApp());
}

class VibeCheckApp extends StatelessWidget {
  const VibeCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeCheck',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B5EA7), // สีม่วงจาก Figma
        ),
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      home: const SplashScreen(), // หน้าแรกที่เปิดขึ้นมา
      // กำหนด route ทั้งหมด
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/task': (context) => const TaskScreen(),
        '/timer': (context) => const TimerScreen(),
        '/emotion': (context) => const EmotionScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/timer-running': (context) => const TimerRunningScreen(totalSeconds: 1800, focusLabel: 'Study', mode: 'Normal',),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}