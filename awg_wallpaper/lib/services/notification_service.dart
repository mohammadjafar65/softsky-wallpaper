import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  // You can process the message here if needed
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Notification channel details
  static const String _channelId = 'softsky_wallpaper_notifications';
  static const String _channelName = 'SoftSky Wallpaper';
  static const String _channelDescription =
      'Notifications for wallpaper updates and announcements';

  /// Initialize notification service
  Future<void> initialize() async {
    // Request notification permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Configure Firebase Messaging
    await _configureFCM();

    // Get and save FCM token
    await _saveToken();

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app was terminated
    _checkInitialMessage();
  }

  /// Request notification permissions (Android 13+)
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Request notification permission for Android 13+
      final status = await Permission.notification.request();

      if (status.isGranted) {
        debugPrint('Notification permission granted');
      } else if (status.isDenied) {
        debugPrint('Notification permission denied');
      } else if (status.isPermanentlyDenied) {
        debugPrint('Notification permission permanently denied');
      }
    }

    // Request FCM permission (iOS style for Android as well)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('FCM permission status: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Configure Firebase Cloud Messaging
  Future<void> _configureFCM() async {
    // Set foreground notification presentation options
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Get and save FCM token to Hive
  Future<void> _saveToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        final box = Hive.box('cache');
        await box.put('fcm_token', token);
        debugPrint('FCM Token saved: $token');

        debugPrint('FCM Token saved: $token');
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Send FCM token to backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final idToken = await user.getIdToken();
        if (idToken != null) {
          final apiService = ApiService();
          apiService.setAuthToken(idToken);
          await apiService.updateFCMToken(token);
        }
      }
    } catch (e) {
      debugPrint('Error sending FCM token to backend: $e');
    }
  }

  /// Handle token refresh
  void _onTokenRefresh(String token) async {
    final box = Hive.box('cache');
    await box.put('fcm_token', token);
    debugPrint('FCM Token refreshed: $token');

    debugPrint('FCM Token refreshed: $token');
    await _sendTokenToBackend(token);
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message received: ${message.notification?.title}');

    // Display local notification when app is in foreground
    if (message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
          ),
        ),
        payload: message.data.isNotEmpty ? message.data.toString() : null,
      );
    }
  }

  /// Handle notification tap from local notifications
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Navigate to specific screen based on payload
    // You can parse response.payload and navigate accordingly
  }

  /// Handle notification tap when app is in background
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped (background): ${message.data}');
    // TODO: Navigate to specific screen based on message data
    // Example: if (message.data['route'] == 'wallpaper_details') { ... }
  }

  /// Check if app was opened from a notification (terminated state)
  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('App opened from notification: ${initialMessage.data}');
      // TODO: Navigate to specific screen based on message data
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    try {
      // Try to get from cache first
      final box = Hive.box('cache');
      String? cachedToken = box.get('fcm_token');

      if (cachedToken != null) {
        return cachedToken;
      }

      // If not in cache, get from FCM
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await box.put('fcm_token', token);
      }
      return token;
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  /// Delete FCM token (useful for logout)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      final box = Hive.box('cache');
      await box.delete('fcm_token');
      debugPrint('FCM token deleted');
    } catch (e) {
      debugPrint('Error deleting token: $e');
    }
  }
}
