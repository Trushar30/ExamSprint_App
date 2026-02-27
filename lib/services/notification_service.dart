import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final _client = SupabaseConfig.client;

  /// Fetch notifications for a user, newest first
  static Future<List<NotificationModel>> fetchNotifications(String userId) async {
    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List)
        .map((e) => NotificationModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Get unread notification count
  static Future<int> getUnreadCount(String userId) async {
    final response = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);
    return (response as List).length;
  }

  /// Mark a single notification as read
  static Future<void> markAsRead(String id) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  /// Mark all notifications as read for a user
  static Future<void> markAllAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  /// Delete a single notification
  static Future<void> deleteNotification(String id) async {
    await _client.from('notifications').delete().eq('id', id);
  }

  /// Clear all notifications for a user
  static Future<void> clearAll(String userId) async {
    await _client.from('notifications').delete().eq('user_id', userId);
  }

  /// Create a single notification
  static Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    String body = '',
    Map<String, dynamic> data = const {},
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
    });
  }

  /// Fan-out notifications to all members of a class (except the sender)
  static Future<void> notifyClassMembers({
    required String classId,
    required String senderUserId,
    required String type,
    required String title,
    String body = '',
    Map<String, dynamic> data = const {},
  }) async {
    // Get all members of the class except the sender
    final members = await _client
        .from('class_members')
        .select('user_id')
        .eq('class_id', classId)
        .neq('user_id', senderUserId);

    final memberIds = (members as List)
        .map((m) => m['user_id'] as String)
        .toList();

    if (memberIds.isEmpty) return;

    // Batch insert notifications for all members
    final notifications = memberIds.map((uid) => {
      'user_id': uid,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
    }).toList();

    await _client.from('notifications').insert(notifications);
  }

  /// Subscribe to real-time notifications for a user
  static RealtimeChannel subscribeToNotifications({
    required String userId,
    required void Function(NotificationModel) onInsert,
    required void Function(NotificationModel) onUpdate,
    required void Function(String) onDelete,
  }) {
    return _client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final notification = NotificationModel.fromMap(
              payload.newRecord,
            );
            onInsert(notification);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final notification = NotificationModel.fromMap(
              payload.newRecord,
            );
            onUpdate(notification);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final id = payload.oldRecord['id'] as String?;
            if (id != null) onDelete(id);
          },
        )
        .subscribe();
  }
}
