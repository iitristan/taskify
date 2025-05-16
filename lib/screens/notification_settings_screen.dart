import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reminder_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedSound = 'default';
  int _reminderLeadTime = 15; // minutes

  final List<String> _soundOptions = [
    'default',
    'alert',
    'bell',
    'chime',
    'none',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('notification_sound_enabled') ?? true;
      _vibrationEnabled =
          prefs.getBool('notification_vibration_enabled') ?? true;
      _selectedSound = prefs.getString('notification_sound') ?? 'default';
      _reminderLeadTime = prefs.getInt('reminder_lead_time') ?? 15;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('notification_sound_enabled', _soundEnabled);
    await prefs.setBool('notification_vibration_enabled', _vibrationEnabled);
    await prefs.setString('notification_sound', _selectedSound);
    await prefs.setInt('reminder_lead_time', _reminderLeadTime);

    // Update notification settings in the ReminderProvider
    if (mounted) {
      final reminderProvider = Provider.of<ReminderProvider>(
        context,
        listen: false,
      );
      await reminderProvider.updateNotificationSettings(
        enabled: _notificationsEnabled,
        soundEnabled: _soundEnabled,
        vibrationEnabled: _vibrationEnabled,
        sound: _selectedSound,
        leadTime: _reminderLeadTime,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Enable Notifications',
                    style: textTheme.titleMedium,
                  ),
                  subtitle: const Text('Receive reminders for your tasks'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    _saveSettings();
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: Text('Sound', style: textTheme.titleMedium),
                  subtitle: const Text('Play sound with notifications'),
                  value: _soundEnabled,
                  onChanged:
                      _notificationsEnabled
                          ? (value) {
                            setState(() {
                              _soundEnabled = value;
                            });
                            _saveSettings();
                          }
                          : null,
                ),
                if (_soundEnabled && _notificationsEnabled) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<String>(
                      value: _selectedSound,
                      decoration: const InputDecoration(
                        labelText: 'Notification Sound',
                      ),
                      items:
                          _soundOptions
                              .map(
                                (sound) => DropdownMenuItem(
                                  value: sound,
                                  child: Text(
                                    sound.substring(0, 1).toUpperCase() +
                                        sound.substring(1),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedSound = value;
                          });
                          _saveSettings();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Divider(),
                SwitchListTile(
                  title: Text('Vibration', style: textTheme.titleMedium),
                  subtitle: const Text('Vibrate with notifications'),
                  value: _vibrationEnabled,
                  onChanged:
                      _notificationsEnabled
                          ? (value) {
                            setState(() {
                              _vibrationEnabled = value;
                            });
                            _saveSettings();
                          }
                          : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reminder Lead Time', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'How many minutes before a task should you be notified?',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _reminderLeadTime.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label: '${_reminderLeadTime.round()} minutes',
                    onChanged:
                        _notificationsEnabled
                            ? (value) {
                              setState(() {
                                _reminderLeadTime = value.round();
                              });
                              _saveSettings();
                            }
                            : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('About Notifications', style: textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notifications help you stay on top of your tasks by sending reminders at the specified times. Make sure to grant the necessary permissions in your device settings for the best experience.',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
