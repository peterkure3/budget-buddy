import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../state/settings_state.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/notification_service.dart';
import 'package:flutter/cupertino.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  String _searchQuery = '';

  Future<void> _resetOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showOnboarding', true);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset onboarding'),
        ),
      );
    }
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'transactions': prefs.getStringList('transactions') ?? [],
        'budget': prefs.getString('budget'),
        'settings': {
          'theme': prefs.getInt('theme_mode'),
          'language': prefs.getString('language_code'),
          'currency': prefs.getString('currency_symbol'),
        }
      };

      final jsonString = jsonEncode(data);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/budget_buddy_export.json');
      await file.writeAsString(jsonString);

      if (context.mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Budget Buddy Data Export',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export data')),
        );
      }
    }
  }

  List<Widget> _buildSettingsList(
      BuildContext context, SettingsState settings) {
    final allSettings = [
      // Appearance Section
      const _SectionHeader(title: 'Appearance'),
      ListTile(
        leading: const Icon(Icons.palette),
        title: Text('Theme'),
        subtitle: const Text('Change app appearance'),
        trailing: DropdownButton<ThemeMode>(
          value: settings.themeMode,
          onChanged: (ThemeMode? newMode) {
            if (newMode != null) {
              settings.setThemeMode(newMode);
            }
          },
          items: [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text('System'),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text('Light'),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text('Dark'),
            ),
          ],
        ),
      ),
      // Theme Icons
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Wrap(
          spacing: 12,
          children: [
            _IconChoice(
              icon: Icons.light_mode,
              isSelected: settings.themeIcon == 'light_mode',
              onTap: () => settings.setThemeIcon('light_mode'),
            ),
            _IconChoice(
              icon: Icons.dark_mode,
              isSelected: settings.themeIcon == 'dark_mode',
              onTap: () => settings.setThemeIcon('dark_mode'),
            ),
            _IconChoice(
              icon: Icons.auto_awesome,
              isSelected: settings.themeIcon == 'auto_awesome',
              onTap: () => settings.setThemeIcon('auto_awesome'),
            ),
          ],
        ),
      ),
      // Color Choices
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ColorChoice(
              color: Colors.green,
              isSelected: settings.themeColor == Colors.green,
              onTap: () => settings.setThemeColor(Colors.green),
            ),
            _ColorChoice(
              color: Colors.blue,
              isSelected: settings.themeColor == Colors.blue,
              onTap: () => settings.setThemeColor(Colors.blue),
            ),
            _ColorChoice(
              color: Colors.purple,
              isSelected: settings.themeColor == Colors.purple,
              onTap: () => settings.setThemeColor(Colors.purple),
            ),
            _ColorChoice(
              color: Colors.orange,
              isSelected: settings.themeColor == Colors.orange,
              onTap: () => settings.setThemeColor(Colors.orange),
            ),
          ],
        ),
      ),
      const Divider(),

      // Notifications Section
      const _SectionHeader(title: 'Notifications'),
      ListTile(
        leading: const Icon(Icons.access_time),
        title: const Text('Daily Reminder Time'),
        subtitle: Text(settings.dailyReminderTime ?? '8:00 PM'),
        onTap: () async {
          TimeOfDay? pickedTime = await showModalBottomSheet<TimeOfDay>(
            context: context,
            builder: (context) {
              TimeOfDay tempTime = settings.dailyReminderTime != null
                  ? _parseTimeOfDay(settings.dailyReminderTime!)
                  : const TimeOfDay(hour: 20, minute: 0);
              return SizedBox(
                height: 250,
                child: Column(
                  children: [
                    Expanded(
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: DateTime(
                          2020, 1, 1, tempTime.hour, tempTime.minute),
                        use24hFormat: false,
                        onDateTimeChanged: (DateTime newDateTime) {
                          tempTime = TimeOfDay(
                            hour: newDateTime.hour,
                            minute: newDateTime.minute,
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, tempTime),
                          child: const Text('Set'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
          if (pickedTime != null && context.mounted) {
            await settings.setDailyReminderTime(pickedTime.hour, pickedTime.minute);
            setState(() {}); // Update the subtitle immediately
          }
        },
      ),
      SwitchListTile(
        secondary: const Icon(Icons.warning),
        title: const Text('Budget Alerts'),
        subtitle: Text(
            'Get notified when balance falls below ${settings.budgetAlertThreshold ?? "20"}%'),
        value: settings.budgetAlerts,
        onChanged: (value) async {
          if (value) {
            final controller = TextEditingController(
              text: settings.budgetAlertThreshold?.toString() ?? '20',
            );
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Set Alert Threshold'),
                content: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter percentage (e.g., 20)',
                    suffixText: '%',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      final threshold = double.tryParse(controller.text);
                      if (threshold != null &&
                          threshold > 0 &&
                          threshold <= 100) {
                        settings.setBudgetAlerts(true, threshold: threshold);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          } else {
            settings.setBudgetAlerts(false);
          }
        },
      ),
      if (settings.budgetAlerts)
        ListTile(
          leading: const Icon(Icons.message),
          title: const Text('Alert Message'),
          subtitle:
              Text(settings.budgetAlertMessage ?? 'Default alert message'),
          onTap: () async {
            final controller = TextEditingController(
              text: settings.budgetAlertMessage,
            );
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Set Alert Message'),
                content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Enter alert message',
                  ),
                  maxLines: 2,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      settings.setBudgetAlertMessage(controller.text);
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        ),
      ListTile(
        leading: const Icon(Icons.notification_important),
        title: const Text('Test Notifications'),
        subtitle: Text('Send a test notification${settings.lastTestNotificationTime != null ? '\nLast test: ' + settings.lastTestNotificationTime! : ''}'),
        onTap: () {
          NotificationService().showTestNotification();
          settings.setLastTestNotificationTime(DateTime.now().toString());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test notification sent')),
          );
        },
      ),

      // Language & Region Section
      const _SectionHeader(title: 'Language & Region'),
      ListTile(
        leading: const Icon(Icons.language),
        title: Text('Language'),
        subtitle: const Text('Change app language'),
        trailing: DropdownButton<String>(
          value: settings.languageCode,
          onChanged: (String? newLanguage) {
            if (newLanguage != null) {
              settings.setLanguage(newLanguage);
            }
          },
          items: const [
            DropdownMenuItem(
              value: 'en',
              child: Text('English'),
            ),
            DropdownMenuItem(
              value: 'es',
              child: Text('Español'),
            ),
          ],
        ),
      ),
      ListTile(
        leading: const Icon(Icons.attach_money),
        title: Text('Currency'),
        subtitle: const Text('Change currency symbol'),
        trailing: DropdownButton<String>(
          value: settings.currencySymbol,
          onChanged: (String? newCurrency) async {
            if (newCurrency == 'other') {
              final controller = TextEditingController();
              final result = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Enter Custom Currency Symbol'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: 'e.g. ₹, ¥, ₩'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, controller.text),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
              if (result != null && result.isNotEmpty) {
                settings.setCurrency(result);
              }
            } else if (newCurrency != null) {
              settings.setCurrency(newCurrency);
            }
          },
          items: const [
            DropdownMenuItem(
              value: '\$',
              child: Text('USD (\$)'),
            ),
            DropdownMenuItem(
              value: '€',
              child: Text('EUR (€)'),
            ),
            DropdownMenuItem(
              value: '£',
              child: Text('GBP (£)'),
            ),
            DropdownMenuItem(
              value: 'UGX',
              child: Text('UGX'),
            ),
            DropdownMenuItem(
              value: 'other',
              child: Text('Other...'),
            ),
          ],
        ),
      ),

      // Data & Privacy Section
      const _SectionHeader(title: 'Data & Privacy'),
      ListTile(
        leading: const Icon(Icons.file_download),
        title: const Text('Export Data'),
        subtitle: const Text('Download your data as JSON'),
        onTap: () => _exportData(context),
      ),
      ListTile(
        leading: const Icon(Icons.refresh),
        title: Text('Reset Onboarding'),
        subtitle: const Text('Reset app introduction'),
        onTap: () => _resetOnboarding(context),
      ),

      // About Section
      const _SectionHeader(title: 'About'),
      ListTile(
        leading: const Icon(Icons.info),
        title: Text('About'),
        subtitle: const Text('App information'),
        onTap: () {
          showAboutDialog(
            context: context,
            applicationName: 'Budget Buddy',
            applicationVersion: '1.0.0',
            applicationLegalese: '© 2024 Budget Buddy',
          );
        },
      ),
    ];

    if (_searchQuery.isEmpty) {
      return allSettings;
    }

    return allSettings.where((widget) {
      if (widget is ListTile) {
        final title =
            widget.title is Text ? (widget.title as Text).data ?? '' : '';
        final subtitle =
            widget.subtitle is Text ? (widget.subtitle as Text).data ?? '' : '';
        return title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search settings...',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                        _showSearch = false;
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                autofocus: true,
              )
            : Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (!_showSearch)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _showSearch = true;
                });
              },
            ),
        ],
      ),
      body: Consumer<SettingsState>(
        builder: (context, settings, child) {
          final settingsList = _buildSettingsList(context, settings);

          return settingsList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No settings found for "$_searchQuery"',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: settingsList,
                );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorChoice({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _IconChoice({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).iconTheme.color,
        ),
      ),
    );
  }
}

// Helper function for parsing time string to TimeOfDay
TimeOfDay _parseTimeOfDay(String timeString) {
  final format = RegExp(r'^(\d{1,2}):(\d{2}) ?([AP]M)?', caseSensitive: false);
  final match = format.firstMatch(timeString);
  if (match != null) {
    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2)!);
    final period = match.group(3)?.toUpperCase();
    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }
  return const TimeOfDay(hour: 20, minute: 0);
}
