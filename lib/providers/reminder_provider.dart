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
import '../providers/auth_provider.dart';
import 'package:flutter/services.dart';

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
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz_data.initializeTimeZones();

      // Request notification permissions for Android 13+
      if (foundation.defaultTargetPlatform == foundation.TargetPlatform.android) {
        try {
          const platform = MethodChannel('com.example.todolist/notifications');
          final bool? result = await platform.invokeMethod('requestNotificationPermission');
          if (result == false) {
            _notificationsEnabled = false;
            await _saveNotificationSettings();
          }

          // Listen for boot completed event
          platform.setMethodCallHandler((call) async {
            if (call.method == 'onBootCompleted') {
              await _rescheduleAllNotifications();
            }
            return null;
          });
        } catch (e) {
          print('Error requesting notification permission: $e');
        }
      }

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

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing notifications: $e');
      _isInitialized = true;
      notifyListeners();
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
              () => Todo(
                userId:
                    Provider.of<AuthProvider>(
                      navigatorKey.currentContext!,
                      listen: false,
                    ).user!.id,
                title: '',
                description: '',
                dueDate: DateTime.now(),
              ),
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

  Future<void> _saveNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
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
    if (reminder.id == null || !_notificationsEnabled || !reminder.notificationsEnabled) return;

    try {
      print('Scheduling notification for reminder: ${reminder.id}');
      print('Reminder time: ${reminder.reminderTime}');
      print('Lead time: $_reminderLeadTime minutes');

      final androidDetails = AndroidNotificationDetails(
        'taskify_reminders',
        'Task Reminders',
        channelDescription: 'Notifications for task reminders',
        importance: Importance.max,
        priority: Priority.high,
        sound: _soundEnabled ? RawResourceAndroidNotificationSound(_selectedSound) : null,
        enableVibration: _vibrationEnabled,
        styleInformation: BigTextStyleInformation(''),
        category: AndroidNotificationCategory.reminder,
        actions: [
          const AndroidNotificationAction('MARK_AS_DONE', 'Mark as Done'),
          const AndroidNotificationAction('SNOOZE', 'Snooze'),
        ],
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
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
      print('Notification ID: $notificationId');

      if (reminder.isRepeating) {
        print('Scheduling repeating notification');
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
            interval = RepeatInterval.daily; // Fallback to daily
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
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        print('Repeating notification scheduled successfully');
      } else {
        print('Scheduling one-time notification');
        
        // For immediate reminders (less than 1 minute away), use show instead of zonedSchedule
        if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1)))) {
          print('Reminder is less than 1 minute away, showing immediately');
          await flutterLocalNotificationsPlugin.show(
            notificationId,
            'Task Reminder',
            'You have a task to complete',
            notificationDetails,
            payload: payload,
          );
        } else {
          print('Scheduling future notification for: $scheduledDate');
          await flutterLocalNotificationsPlugin.zonedSchedule(
            notificationId,
            'Task Reminder',
            'You have a task to complete',
            scheduledDate,
            notificationDetails,
            payload: payload,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
        print('Notification scheduled successfully');
      }
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  Future<void> toggleReminderNotification(Reminder reminder, bool enabled) async {
    final updated = reminder.copyWith(notificationsEnabled: enabled);
    await updateReminder(updated);
    if (enabled) {
      await scheduleNotification(updated);
    } else {
      await cancelNotification(updated.id!);
    }
    notifyListeners();
  }

  List<Reminder> getRemindersForTodo(String todoId) {
    return _reminders.where((reminder) => reminder.todoId == todoId).toList();
  }
}
