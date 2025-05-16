import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/reminder.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import 'dart:async';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../main.dart';

class ReminderProvider with ChangeNotifier {
  List<Reminder> _reminders = [];
  Database? _database;
  bool _isInitialized = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Notification settings
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedSound = 'default';
  int _reminderLeadTime = 15;

  List<Reminder> get reminders => _reminders;

  Future<void> initPlugin() async {
    // Initialize timezone
    tz_data.initializeTimeZones();

    // Load notification settings
    await _loadNotificationSettings();

    // Configure notification settings
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          notificationCategories: [
            DarwinNotificationCategory(
              'taskify_reminders',
              actions: [
                DarwinNotificationAction.plain(
                  'MARK_AS_DONE',
                  'Mark as Done',
                  options: {DarwinNotificationActionOption.foreground},
                ),
                DarwinNotificationAction.plain(
                  'SNOOZE',
                  'Snooze',
                  options: {DarwinNotificationActionOption.foreground},
                ),
              ],
            ),
          ],
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    // Request permissions on iOS
    if (!kIsWeb) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  void _handleNotificationResponse(NotificationResponse response) async {
    final String? payload = response.payload;
    if (payload == null) return;

    final Map<String, dynamic> data = json.decode(payload);
    final int reminderId = data['reminderId'];
    final int todoId = data['todoId'];

    switch (response.actionId) {
      case 'MARK_AS_DONE':
        // Mark the todo as completed
        final todoProvider = Provider.of<TodoProvider>(
          navigatorKey.currentContext!,
          listen: false,
        );
        final todo = todoProvider.todos.firstWhere(
          (todo) => todo.id == todoId,
          orElse:
              () => Todo(title: '', description: '', dueDate: DateTime.now()),
        );
        if (todo.id != null) {
          await todoProvider.updateTodo(todo.copyWith(isCompleted: true));
        }
        break;
      case 'SNOOZE':
        // Snooze the reminder for 15 minutes
        final reminder = _reminders.firstWhere(
          (r) => r.id == reminderId,
          orElse: () => Reminder(todoId: todoId, reminderTime: DateTime.now()),
        );
        if (reminder.id != null) {
          final newReminderTime = DateTime.now().add(
            const Duration(minutes: 15),
          );
          await updateReminder(
            reminder.copyWith(reminderTime: newReminderTime),
          );
        }
        break;
      default:
        // Handle notification tap
        break;
    }
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _soundEnabled = prefs.getBool('notification_sound_enabled') ?? true;
    _vibrationEnabled = prefs.getBool('notification_vibration_enabled') ?? true;
    _selectedSound = prefs.getString('notification_sound') ?? 'default';
    _reminderLeadTime = prefs.getInt('reminder_lead_time') ?? 15;
  }

  Future<void> updateNotificationSettings({
    required bool enabled,
    required bool soundEnabled,
    required bool vibrationEnabled,
    required String sound,
    required int leadTime,
  }) async {
    _notificationsEnabled = enabled;
    _soundEnabled = soundEnabled;
    _vibrationEnabled = vibrationEnabled;
    _selectedSound = sound;
    _reminderLeadTime = leadTime;

    // Reschedule all notifications with new settings
    await _rescheduleAllNotifications();

    notifyListeners();
  }

  Future<void> _rescheduleAllNotifications() async {
    // Cancel all existing notifications
    await flutterLocalNotificationsPlugin.cancelAll();

    // Reschedule notifications if enabled
    if (_notificationsEnabled) {
      for (var reminder in _reminders) {
        if (reminder.reminderTime.isAfter(DateTime.now())) {
          await scheduleNotification(reminder);
        }
      }
    }
  }

  Future<void> initDatabase() async {
    if (_isInitialized) return;

    try {
      await initPlugin();
      _database = await openDatabase(
        join(await getDatabasesPath(), 'reminder_database.db'),
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE reminders(id INTEGER PRIMARY KEY AUTOINCREMENT, todoId INTEGER, reminderTime TEXT, isRepeating INTEGER, repeatType TEXT)',
          );
        },
        version: 1,
      );
      await loadReminders();
      _isInitialized = true;
    } catch (e) {
      print('Reminder database initialization error: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> loadReminders() async {
    if (_database == null) return;

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        'reminders',
      );
      _reminders = List.generate(maps.length, (i) => Reminder.fromMap(maps[i]));

      // Schedule all reminders
      for (var reminder in _reminders) {
        if (reminder.reminderTime.isAfter(DateTime.now())) {
          await scheduleNotification(reminder);
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error loading reminders: $e');
    }
  }

  Future<void> addReminder(Reminder reminder) async {
    try {
      if (_database != null) {
        final id = await _database!.insert(
          'reminders',
          reminder.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        final newReminder = Reminder(
          id: id,
          todoId: reminder.todoId,
          reminderTime: reminder.reminderTime,
          isRepeating: reminder.isRepeating,
          repeatType: reminder.repeatType,
        );

        _reminders.add(newReminder);

        // Schedule notification
        await scheduleNotification(newReminder);
      } else {
        // For web platform, use in-memory data
        final id = _reminders.isEmpty ? 1 : _reminders.last.id! + 1;
        final newReminder = Reminder(
          id: id,
          todoId: reminder.todoId,
          reminderTime: reminder.reminderTime,
          isRepeating: reminder.isRepeating,
          repeatType: reminder.repeatType,
        );

        _reminders.add(newReminder);
      }
      notifyListeners();
    } catch (e) {
      print('Error adding reminder: $e');
    }
  }

  Future<void> updateReminder(Reminder reminder) async {
    try {
      if (_database != null) {
        await _database!.update(
          'reminders',
          reminder.toMap(),
          where: 'id = ?',
          whereArgs: [reminder.id],
        );
      }

      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        // Cancel old notification
        await cancelNotification(reminder.id!);

        _reminders[index] = reminder;

        // Schedule new notification
        await scheduleNotification(reminder);

        notifyListeners();
      }
    } catch (e) {
      print('Error updating reminder: $e');
    }
  }

  Future<void> deleteReminder(int id) async {
    try {
      if (_database != null) {
        await _database!.delete('reminders', where: 'id = ?', whereArgs: [id]);
      }

      // Cancel notification
      await cancelNotification(id);

      _reminders.removeWhere((reminder) => reminder.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting reminder: $e');
    }
  }

  Future<void> scheduleNotification(Reminder reminder) async {
    if (reminder.id == null || !_notificationsEnabled) return;

    try {
      final androidDetails = AndroidNotificationDetails(
        'taskify_reminders',
        'Task Reminders',
        channelDescription: 'Notifications for task reminders',
        importance: Importance.max,
        priority: Priority.high,
        sound:
            _soundEnabled
                ? RawResourceAndroidNotificationSound(_selectedSound)
                : null,
        enableVibration: _vibrationEnabled,
        styleInformation: BigTextStyleInformation(''),
        category: AndroidNotificationCategory.reminder,
        actions: [
          const AndroidNotificationAction('MARK_AS_DONE', 'Mark as Done'),
          const AndroidNotificationAction('SNOOZE', 'Snooze'),
        ],
      );

      final iosDetails = DarwinNotificationDetails(
        sound: _soundEnabled ? _selectedSound : null,
        presentAlert: true,
        presentBadge: true,
        presentSound: _soundEnabled,
        categoryIdentifier: 'taskify_reminders',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Prepare notification payload
      final payload = json.encode({
        'reminderId': reminder.id,
        'todoId': reminder.todoId,
      });

      // Calculate notification time with lead time
      final scheduledDate = tz.TZDateTime.from(
        reminder.reminderTime.subtract(Duration(minutes: _reminderLeadTime)),
        tz.local,
      );

      if (reminder.isRepeating) {
        // Handle repeating notifications based on repeatType
        RepeatInterval interval;
        switch (reminder.repeatType) {
          case 'daily':
            interval = RepeatInterval.daily;
            break;
          case 'weekly':
            interval = RepeatInterval.weekly;
            break;
          case 'monthly':
            // There's no monthly option, so we'll use daily as a fallback
            interval = RepeatInterval.daily;
            break;
          default:
            interval = RepeatInterval.daily;
        }

        await flutterLocalNotificationsPlugin.periodicallyShow(
          reminder.id!,
          'Task Reminder',
          'You have a task to complete',
          interval,
          notificationDetails,
          payload: payload,
        );
      } else {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          reminder.id!,
          'Task Reminder',
          'You have a task to complete',
          scheduledDate,
          notificationDetails,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  List<Reminder> getRemindersForTodo(int todoId) {
    return _reminders.where((reminder) => reminder.todoId == todoId).toList();
  }
}
