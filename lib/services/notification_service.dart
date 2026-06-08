import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: null,
      macOS: null,
      linux: null,
    );

    await _plugin.initialize(settings);

    // Android 13+ requires runtime permission for notifications
    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      try {
        await androidImpl?.requestNotificationsPermission();
      } catch (e) {
        if (kDebugMode) {
          print('Notification permission request failed: $e');
        }
      }
    }

    // Create a default channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'budget_thresholds',
      'Budget Threshold Alerts',
      description: 'Alerts when category budgets reach 50% or 10% remaining',
      importance: Importance.high,
    );
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<void> showBudgetAlert({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'budget_thresholds',
      'Budget Threshold Alerts',
      channelDescription: 'Alerts when category budgets reach 50% or 10% remaining',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _plugin.show(DateTime.now().millisecondsSinceEpoch % 100000, title, body, details);
  }
}


