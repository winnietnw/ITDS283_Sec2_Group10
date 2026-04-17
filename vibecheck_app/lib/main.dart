import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

// screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/task_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/emotion_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/analytics_emotion_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/timer_running_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reminders_sounds_screen.dart';
import 'screens/goals_categories_screen.dart';
import 'screens/new_target_screen.dart';
import 'screens/multi_device_support_screen.dart';
import 'screens/about_us_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/privacy_screen.dart';

// widgets
import 'widgets/bottom_nav_bar.dart';
import 'widgets/theme.dart';

// providers
import 'provider/task_provider.dart';
import 'provider/mood_provider.dart';
import 'provider/timer_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const VibeCheckApp());
}

class VibeCheckApp extends StatelessWidget {
  const VibeCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
      ],
      child: MaterialApp(
        title: 'VibeCheck',
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return ScrollConfiguration(
            behavior: const MaterialScrollBehavior().copyWith(
              physics: const BouncingScrollPhysics(),
            ),
            child: child!,
          );
        },
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Poppins',
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
        ),
        home: const SplashScreen(),

        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => MainNavigation(key: MainNavigation.navKey),
          '/task': (context) => const TaskScreen(),
          '/timer': (context) => const TimerScreen(),
          '/emotion': (context) => const EmotionScreen(),
          '/analytics': (context) => const AnalyticsScreen(),
          '/analytics_emotion': (context) => const AnalyticsEmotionScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/timer-running': (context) => const TimerRunningScreen(
                totalSeconds: 1800,
                focusLabel: 'Study',
                mode: 'Normal',
              ),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/reminders-sounds': (context) => const RemindersSoundsScreen(),
          '/goals-categories' : (context) => const GoalsCategoriesScreen(),
          '/new-target': (context) => const NewTargetScreen(),
          '/multi-device-support': (context) => const MultiDeviceSupportScreen(),
          '/about-us': (context) => const AboutUsScreen(),
          '/feedback': (context) => const FeedbackScreen(),
          '/privacy': (context) => const PrivacyScreen(),
        },
      ),
    );
  }
}