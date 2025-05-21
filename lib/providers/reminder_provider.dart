import 'package:flutter/foundation.dart' as foundation;
import 'package:cloud_firestore/cloud_firestore.dart';
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

class ReminderProvider with foundation.ChangeNotifier {
  List<Reminder> _reminders = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
  bool get isInitialized => _isInitialized;

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
    if (!foundation.kIsWeb) {
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
    final String reminderId = data['reminderId'];
    final String todoId = data['todoId'];

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
      await loadReminders();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> loadReminders() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('reminders').get();
      _reminders =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Reminder.fromMap(data, doc.id);
          }).toList();

      // Schedule all reminders
      for (var reminder in _reminders) {
        if (reminder.reminderTime.isAfter(DateTime.now())) {
          await scheduleNotification(reminder);
        }
      }

      notifyListeners();
    } catch (e) {
      notifyListeners();
    }
  }

  Future<void> addReminder(Reminder reminder) async {
    try {
      final docRef = await _firestore
          .collection('reminders')
          .add(reminder.toMap());
      final newReminder = reminder.copyWith(id: docRef.id);
      _reminders.add(newReminder);
      await scheduleNotification(newReminder);
      notifyListeners();
    } catch (e) {
      notifyListeners();
    }
  }

  Future<void> updateReminder(Reminder reminder) async {
    try {
      await _firestore
          .collection('reminders')
          .doc(reminder.id)
          .update(reminder.toMap());
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
      notifyListeners();
    }
  }

  Future<void> deleteReminder(String id) async {
    try {
      // Cancel notification first
      await cancelNotification(id);

      // Then delete from Firestore
      await _firestore.collection('reminders').doc(id).delete();

      // Finally remove from local list
      _reminders.removeWhere((reminder) => reminder.id == id);
      notifyListeners();
    } catch (e) {
      notifyListeners();
    }
  }

  Future<void> cancelNotification(String id) async {
    try {
      final notificationId = id.hashCode.abs();
      await flutterLocalNotificationsPlugin.cancel(notificationId);
    } catch (e) {
      notifyListeners();
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

      // Generate a unique integer ID from the string ID
      final notificationId = reminder.id!.hashCode.abs();

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
          notificationId,
          'Task Reminder',
          'You have a task to complete',
          interval,
          notificationDetails,
          payload: payload,
        );
      } else {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
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
      notifyListeners();
    }
  }

  List<Reminder> getRemindersForTodo(String todoId) {
    return _reminders.where((reminder) => reminder.todoId == todoId).toList();
  }
}
