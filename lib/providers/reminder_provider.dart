import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/reminder.dart';
import 'dart:async';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class ReminderProvider with ChangeNotifier {
  List<Reminder> _reminders = [];
  Database? _database;
  bool _isInitialized = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<Reminder> get reminders => _reminders;

  Future<void> initPlugin() async {
    // Initialize timezone
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (
        NotificationResponse notificationResponse,
      ) {
        // Handle notification taps
      },
    );
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
    if (reminder.id == null) return;

    try {
      AndroidNotificationDetails androidDetails =
          const AndroidNotificationDetails(
            'taskify_reminders',
            'Task Reminders',
            channelDescription: 'Notifications for task reminders',
            importance: Importance.max,
            priority: Priority.high,
          );

      DarwinNotificationDetails iosDetails = const DarwinNotificationDetails();

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Convert DateTime to TZDateTime
      final scheduledDate = tz.TZDateTime.from(reminder.reminderTime, tz.local);

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
        );
      }
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  List<Reminder> getRemindersForTodo(int todoId) {
    return _reminders.where((reminder) => reminder.todoId == todoId).toList();
  }
}
