import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Initialize notification channels and permissions
  Future<void> initialize() async {
    // Request permission for iOS
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const androidInitialize = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSInitialize = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidInitialize,
      iOS: iOSInitialize,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        _handleNotificationTap(response);
      },
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Handle incoming messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Handle message open when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleBackgroundMessage(message);
    });
  }

  // Subscribe to topic (e.g., for specific service categories or user types)
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  // Get FCM token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // Save FCM token to Firestore
  Future<void> saveToken(String userId) async {
    String? token = await getToken();
    if (token != null) {
      // Save token to Firestore
      // You can implement this based on your data structure
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  // Handle background messages
  void _handleBackgroundMessage(RemoteMessage message) {
    // Handle background message tap
    // You can implement navigation or other actions here
  }

  // Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    // Handle notification tap
    // You can implement navigation or other actions here
  }

  // Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Implement sending notification using your backend service
    // This is typically done through a Cloud Function or backend API
  }

  // Send notification to topic
  Future<void> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Implement sending notification using your backend service
    // This is typically done through a Cloud Function or backend API
  }
}

// Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Initialize notification service
final notificationInitProvider = FutureProvider<void>((ref) async {
  final notificationService = ref.watch(notificationServiceProvider);
  await notificationService.initialize();
});
