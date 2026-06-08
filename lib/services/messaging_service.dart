import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

/// Background message handler
/// Must be a top-level function.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // We only trigger a local notification for visibility when app is in background/terminated
  final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
  final body = message.notification?.body ?? message.data['body'] ?? '';
  try {
    await NotificationService.instance.showBudgetAlert(title: title, body: body);
  } catch (_) {}
}

class MessagingService {
  MessagingService._internal();
  static final MessagingService instance = MessagingService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // iOS/macOS permissions (Android handled in NotificationService)
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages -> show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      await NotificationService.instance.showBudgetAlert(title: title, body: body);
    });

    _initialized = true;
  }

  /// Register device token for user and subscribe to per-user topics.
  Future<void> registerUserMessaging({required String uid}) async {
    try {
      final token = await _messaging.getToken();
      if (kDebugMode) {
        debugPrint('FCM token: $token');
      }
      if (token == null) return;

      // Save token on the user document with last seen time.
      final users = FirebaseFirestore.instance.collection('users');
      await users.doc(uid).set({
        'fcmTokens': {
          token: FieldValue.serverTimestamp(),
        },
        'lastFcmToken': token,
      }, SetOptions(merge: true));

      // Subscribe to goal and split topics globally for this user
      await _messaging.subscribeToTopic('goals_user_$uid');
      await _messaging.subscribeToTopic('splits_user_$uid');
    } catch (e) {
      if (kDebugMode) debugPrint('registerUserMessaging error: $e');
    }
  }

  /// Unregister on sign out
  Future<void> unregisterUserMessaging({required String uid}) async {
    try {
      await _messaging.unsubscribeFromTopic('goals_user_$uid');
      await _messaging.unsubscribeFromTopic('splits_user_$uid');
    } catch (e) {
      if (kDebugMode) debugPrint('unregisterUserMessaging error: $e');
    }
  }

  /// Subscribe to split notifications only while a group is open
  Future<void> subscribeToGroupSplits({required String uid, required String groupId}) async {
    try {
      await _messaging.subscribeToTopic('splits_group_${groupId}_$uid');
    } catch (e) {
      if (kDebugMode) debugPrint('subscribeToGroupSplits error: $e');
    }
  }

  Future<void> unsubscribeFromGroupSplits({required String uid, required String groupId}) async {
    try {
      await _messaging.unsubscribeFromTopic('splits_group_${groupId}_$uid');
    } catch (e) {
      if (kDebugMode) debugPrint('unsubscribeFromGroupSplits error: $e');
    }
  }
}


