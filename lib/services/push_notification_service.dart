import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';

/// Handles background messages (must be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 Background message: ${message.messageId}');
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize FCM: request permissions, get token, set up listeners
  static Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request notification permissions (required for iOS, Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('🔔 FCM permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get FCM token
      final token = await _messaging.getToken();
      debugPrint('🔑 FCM Token: $token');

      // Save token to user's profile if logged in
      if (token != null) {
        await _saveFcmToken(token);
      }

      // Listen for token refreshes
      _messaging.onTokenRefresh.listen(_saveFcmToken);

      // Configure foreground notification display
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app was in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was launched from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    }
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📬 Foreground: ${message.notification?.title}');
    // System notification is shown automatically via setForegroundNotificationPresentationOptions
    // In-app UI is updated via Supabase Realtime
  }

  /// Handle notification tap — user tapped on a system notification
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.data}');
    // The app opens and the NotificationBell shows unread count
  }

  /// Save FCM token to Supabase profiles for future server-side push
  static Future<void> _saveFcmToken(String token) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId != null) {
        // Store FCM token in user's profile metadata
        // This allows server-side push notifications in the future
        await SupabaseConfig.client
            .from('profiles')
            .update({'fcm_token': token})
            .eq('id', userId);
        debugPrint('💾 FCM token saved');
      }
    } catch (e) {
      // Non-critical — the column may not exist yet, that's fine
      debugPrint('FCM token save: $e');
    }
  }

  /// Subscribe to class-specific topic for push notifications
  static Future<void> subscribeToClass(String classId) async {
    await _messaging.subscribeToTopic('class_$classId');
    debugPrint('📋 Subscribed to class topic: class_$classId');
  }

  /// Unsubscribe from a class topic
  static Future<void> unsubscribeFromClass(String classId) async {
    await _messaging.unsubscribeFromTopic('class_$classId');
  }

  /// Get current FCM token
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
