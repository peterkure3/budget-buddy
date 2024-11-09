import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class SettingsState extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language_code';
  static const String _currencyKey = 'currency_symbol';
  static const String _themeIconKey = 'theme_icon';
  static const String _themeColorKey = 'theme_color';
  static const String _dailyReminderKey = 'daily_reminder';
  static const String _budgetAlertsKey = 'budget_alerts';

  ThemeMode _themeMode = ThemeMode.system;
  String _languageCode = 'en';
  String _currencySymbol = '\$';
  String _themeIcon = 'light_mode';
  Color _themeColor = Colors.green;
  bool _dailyReminder = false;
  bool _budgetAlerts = false;

  String? _dailyReminderTime;
  String? _dailyReminderMessage;
  double? _budgetAlertThreshold;
  String? _budgetAlertMessage;

  final NotificationService _notificationService = NotificationService();

  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;
  String get currencySymbol => _currencySymbol;
  String get themeIcon => _themeIcon;
  Color get themeColor => _themeColor;
  bool get dailyReminder => _dailyReminder;
  bool get budgetAlerts => _budgetAlerts;

  String? get dailyReminderTime => _dailyReminderTime;
  String? get dailyReminderMessage => _dailyReminderMessage;
  double? get budgetAlertThreshold => _budgetAlertThreshold;
  String? get budgetAlertMessage => _budgetAlertMessage;

  SettingsState() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[prefs.getInt(_themeKey) ?? 0];
    _languageCode = prefs.getString(_languageKey) ?? 'en';
    _currencySymbol = prefs.getString(_currencyKey) ?? '\$';
    _themeIcon = prefs.getString(_themeIconKey) ?? 'light_mode';
    _themeColor = Color(prefs.getInt(_themeColorKey) ?? Colors.green.value);
    _dailyReminder = prefs.getBool(_dailyReminderKey) ?? false;
    _budgetAlerts = prefs.getBool(_budgetAlertsKey) ?? false;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return; // Prevent unnecessary updates
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    _themeMode = mode;
    
    // Update theme icon based on mode
    String newIcon;
    switch (mode) {
      case ThemeMode.light:
        newIcon = 'light_mode';
        break;
      case ThemeMode.dark:
        newIcon = 'dark_mode';
        break;
      case ThemeMode.system:
        newIcon = 'auto_awesome';
        break;
    }
    
    if (_themeIcon != newIcon) {
      await prefs.setString(_themeIconKey, newIcon);
      _themeIcon = newIcon;
    }
    
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    _languageCode = languageCode;
    notifyListeners();
  }

  Future<void> setCurrency(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, symbol);
    _currencySymbol = symbol;
    notifyListeners();
  }

  Future<void> setThemeIcon(String icon) async {
    if (_themeIcon == icon) return; // Prevent unnecessary updates
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeIconKey, icon);
    _themeIcon = icon;
    
    // Update theme mode based on icon
    switch (icon) {
      case 'light_mode':
        await setThemeMode(ThemeMode.light);
        break;
      case 'dark_mode':
        await setThemeMode(ThemeMode.dark);
        break;
      case 'auto_awesome':
        await setThemeMode(ThemeMode.system);
        break;
    }
    
    notifyListeners();
  }

  Future<void> setThemeColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeColorKey, color.value);
    _themeColor = color;
    notifyListeners();
  }

  Future<void> setDailyReminder(bool value, {int? hour, int? minute}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyReminderKey, value);
    _dailyReminder = value;
    
    if (hour != null && minute != null) {
      final timeString = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      await prefs.setString('daily_reminder_time', timeString);
      _dailyReminderTime = timeString;
    }
    
    await _notificationService.scheduleDailyReminder(
      value,
      hour: hour ?? 20,
      minute: minute ?? 0,
      title: 'Daily Reminder',
      body: _dailyReminderMessage ?? 'Don\'t forget to track your expenses for today!',
    );
    notifyListeners();
  }

  Future<void> setDailyReminderMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('daily_reminder_message', message);
    _dailyReminderMessage = message;
    if (_dailyReminder) {
      await setDailyReminder(true); // Reschedule with new message
    }
    notifyListeners();
  }

  Future<void> setBudgetAlerts(bool value, {double? threshold}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_budgetAlertsKey, value);
    _budgetAlerts = value;
    
    if (threshold != null) {
      await prefs.setDouble('budget_alert_threshold', threshold);
      _budgetAlertThreshold = threshold;
    }
    
    await _notificationService.setBudgetAlert(
    enabled: value,
    threshold: threshold ?? 20,
    title: 'Budget Alert',
    body: _budgetAlertMessage ?? 'Your balance is getting low!',
  );

    notifyListeners();
  }

  Future<void> setBudgetAlertMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('budget_alert_message', message);
    _budgetAlertMessage = message;
    if (_budgetAlerts) {
      await setBudgetAlerts(true); // Reschedule with new message
    }
    notifyListeners();
  }
} 