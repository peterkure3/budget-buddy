import 'package:flutter/material.dart';
import '../ui/screens/onboarding_screen.dart';
import '../ui/screens/main_screen.dart';

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String main = '/main';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      onboarding: (context) => const OnboardingScreen(),
      main: (context) => const MainScreen(),
    };
  }
} 