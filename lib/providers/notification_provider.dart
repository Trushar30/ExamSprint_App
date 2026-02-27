import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  RealtimeChannel? _channel;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasUnread => _unreadCount > 0;

  /// Initialize: load notifications and subscribe to realtime
  Future<void> init(String userId) async {
    await loadNotifications(userId);
    _subscribeRealtime(userId);
  }

  /// Load all notifications from Supabase
  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await NotificationService.fetchNotifications(userId);
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Subscribe to Supabase Realtime for live updates
  void _subscribeRealtime(String userId) {
    _channel?.unsubscribe();
    _channel = NotificationService.subscribeToNotifications(
      userId: userId,
      onInsert: (notification) {
        _notifications.insert(0, notification);
        if (!notification.isRead) _unreadCount++;
        notifyListeners();
      },
      onUpdate: (notification) {
        final idx = _notifications.indexWhere((n) => n.id == notification.id);
        if (idx != -1) {
          final wasUnread = !_notifications[idx].isRead;
          final nowRead = notification.isRead;
          _notifications[idx] = notification;
          if (wasUnread && nowRead) _unreadCount--;
          notifyListeners();
        }
      },
      onDelete: (id) {
        final idx = _notifications.indexWhere((n) => n.id == id);
        if (idx != -1) {
          if (!_notifications[idx].isRead) _unreadCount--;
          _notifications.removeAt(idx);
          notifyListeners();
        }
      },
    );
  }

  /// Mark a single notification as read (optimistic)
  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      _unreadCount--;
      notifyListeners();
      try {
        await NotificationService.markAsRead(id);
      } catch (e) {
        // Revert on failure
        _notifications[idx] = _notifications[idx].copyWith(isRead: false);
        _unreadCount++;
        notifyListeners();
      }
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final oldNotifications = List<NotificationModel>.from(_notifications);
    final oldCount = _unreadCount;

    _notifications = _notifications
        .map((n) => n.isRead ? n : n.copyWith(isRead: true))
        .toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      await NotificationService.markAllAsRead(userId);
    } catch (e) {
      _notifications = oldNotifications;
      _unreadCount = oldCount;
      notifyListeners();
    }
  }

  /// Delete a notification (optimistic)
  Future<void> deleteNotification(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;

    final removed = _notifications[idx];
    if (!removed.isRead) _unreadCount--;
    _notifications.removeAt(idx);
    notifyListeners();

    try {
      await NotificationService.deleteNotification(id);
    } catch (e) {
      _notifications.insert(idx, removed);
      if (!removed.isRead) _unreadCount++;
      notifyListeners();
    }
  }

  /// Clear all notifications
  Future<void> clearAll(String userId) async {
    final old = List<NotificationModel>.from(_notifications);
    final oldCount = _unreadCount;

    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();

    try {
      await NotificationService.clearAll(userId);
    } catch (e) {
      _notifications = old;
      _unreadCount = oldCount;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
