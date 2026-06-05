import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:flutter_app_badger/flutter_app_badger.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseInAppMessaging _inAppMessaging = FirebaseInAppMessaging.instance;
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    debugPrint('--- [FIAM] In-App Messaging is active ---');

    // 1. Request Permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('--- [PUSH] User granted permission ---');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('--- [PUSH] User granted provisional permission ---');
    } else {
      debugPrint('--- [PUSH] User declined or has not accepted permission ---');
    }

    // 2. Local Notifications Setup
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('--- [PUSH] Notification Clicked: ${details.payload} ---');
        // Handle navigation if needed
      },
    );

    // 3. Create Android Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Get FCM Token
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('--- [PUSH] FCM Token: $token ---');
        await SupabaseService.saveDeviceToken(token);
      }

      // Listen to token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        SupabaseService.saveDeviceToken(newToken);
      });
    } catch (e) {
      debugPrint('--- [PUSH] Error getting token: $e ---');
    }

    // 5. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // 6. Handle Background/Terminated Click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('--- [PUSH] App opened from notification: ${message.messageId} ---');
      // Handle navigation
    });

    // Check if app was opened from terminated state via notification
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('--- [PUSH] App launched from terminated state via notification ---');
    }
  }

  /// Syncs the user's KYC status with Firebase so we can target them in campaigns
  static Future<void> updateKycStatus(String status) async {
    try {
      await _analytics.setUserProperty(name: 'kyc_status', value: status);
      debugPrint('--- [Firebase] User property kyc_status set to: $status ---');
    } catch (e) {
      debugPrint('Error updating KYC user property: $e');
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('--- [PUSH] Foreground Message: ${message.notification?.title} ---');

    final currentUserId = supabase.Supabase.instance.client.auth.currentUser?.id;
    final senderId = message.data['sender_id'];

    if (senderId != null && senderId == currentUserId) {
      debugPrint('--- [PUSH] Ignoring self-sent message ---');
      return;
    }

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    final bool isChatMessage = message.data['table'] == 'messages' || message.data['type'] == 'chat';

    if (notification != null) {
      if (isChatMessage) {
        messageBadgeCount.value += 1;
      } else {
        notificationBadgeCount.value += 1;
      }

      int total = messageBadgeCount.value + notificationBadgeCount.value;
      _showLocalNotification(notification.title ?? '', notification.body ?? '', total);
    }
  }

  static void _showLocalNotification(String title, String body, int badgeCount) async {
    FlutterAppBadger.updateBadgeCount(badgeCount);

    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      number: badgeCount,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Khozna Alert',
      ),
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      notificationId,
      title,
      body,
      details,
    );
  }
}
