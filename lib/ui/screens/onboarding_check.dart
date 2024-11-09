import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';
import 'main_screen.dart';

class OnboardingCheck extends StatefulWidget {
  const OnboardingCheck({super.key});

  @override
  State<OnboardingCheck> createState() => _OnboardingCheckState();
}

class _OnboardingCheckState extends State<OnboardingCheck> {
  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final showOnboarding = prefs.getBool('showOnboarding') ?? true;

    if (mounted) {
      if (showOnboarding) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
} 