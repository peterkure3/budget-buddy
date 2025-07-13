import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/routes.dart';
import 'state/transaction_state.dart';
import 'state/settings_state.dart';
import 'state/budget_state.dart';
import 'ui/screens/onboarding_check.dart';
import 'config/theme_manager.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize NotificationService
  final notificationService = NotificationService();
  await notificationService.initializeNotifications();

  runApp(MyApp(notificationService: notificationService));
}

class MyApp extends StatefulWidget {
  final NotificationService notificationService;

  const MyApp({super.key, required this.notificationService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  late final AnimationController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = ThemeManager.createThemeController(this);
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<NotificationService>.value(value: widget.notificationService),
        ChangeNotifierProxyProvider<NotificationService, SettingsState>(
          // The create method is required but will be replaced by update immediately.
          create: (_) => SettingsState(NotificationService()), // Dummy instance, replaced by update
          update: (context, notificationService, previous) => SettingsState(notificationService),
        ),
        ChangeNotifierProxyProvider<SettingsState, BudgetState>(
          create: (context) =>
              BudgetState(Provider.of<SettingsState>(context, listen: false)),
          update: (context, settings, previous) =>
              previous ?? BudgetState(settings),
        ),
        ChangeNotifierProxyProvider2<SettingsState, BudgetState,
            TransactionState>(
          create: (context) => TransactionState(
            Provider.of<BudgetState>(context, listen: false),
            Provider.of<SettingsState>(context, listen: false),
          ),
          update: (context, settings, budget, previous) =>
              previous ?? TransactionState(budget, settings),
        ),
      ],
      child: Consumer<SettingsState>(
        builder: (context, settings, _) {
          // Trigger animation when theme changes
          _themeController.forward(from: 0);

          return AnimatedBuilder(
            animation: _themeController,
            builder: (context, child) {
              return MaterialApp(
                title: 'Budget Buddy',
                theme: ThemeManager.getTheme(false, settings.themeColor),
                darkTheme: ThemeManager.getTheme(true, settings.themeColor),
                themeMode: settings.themeMode,
                debugShowCheckedModeBanner: false,
                locale: Locale(settings.languageCode),
                home: const OnboardingCheck(),
                routes: AppRoutes.getRoutes(),
              );
            },
          );
        },
      ),
    );
  }
}
