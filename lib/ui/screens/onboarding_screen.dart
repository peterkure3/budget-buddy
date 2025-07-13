import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';
import 'dart:io';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 3;

  List<Map<String, dynamic>> onboardingData = [
    {
      "title": "Welcome to Budget Buddy!",
      "text": "Track your expenses with ease",
      "icon": Icons.account_balance_wallet,
    },
    {
      "title": "Set Budgets",
      "text": "Create custom budgets for different categories",
      "icon": Icons.pie_chart,
    },
    {
      "title": "Visualize Your Spending",
      "text": "See where your money goes with intuitive charts",
      "icon": Icons.bar_chart,
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showOnboarding', false);
    Process.run('pieces-cli', ['add', '--text', 'User completed onboarding']);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _numPages,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return OnboardingPage(
                    title: onboardingData[index]["title"]!,
                    text: onboardingData[index]["text"]!,
                    icon: onboardingData[index]["icon"]!,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(_currentPage == _numPages - 1 ? "" : "Skip"),
                  ),
                  Row(
                    children: List.generate(
                      _numPages,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 10,
                        width: _currentPage == index ? 30 : 10,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: _currentPage == index
                              ? colorScheme.primary
                              : colorScheme.secondary.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _numPages - 1) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                        _currentPage == _numPages - 1 ? "Get Started" : "Next"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String text;
  final IconData icon;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 180,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
