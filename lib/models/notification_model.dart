import 'dart:convert';

enum NotificationType {
  resourceAdded,
  announcement,
  memberJoined,
  discussionReply,
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body = '',
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: _parseType(map['type'] as String),
      title: map['title'] as String,
      body: map['body'] as String? ?? '',
      data: map['data'] != null
          ? (map['data'] is String
              ? json.decode(map['data'] as String) as Map<String, dynamic>
              : map['data'] as Map<String, dynamic>)
          : {},
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'type': typeToString,
      'title': title,
      'body': body,
      'data': data,
      'is_read': isRead,
    };
  }

  static NotificationType _parseType(String type) {
    switch (type) {
      case 'resource_added':
        return NotificationType.resourceAdded;
      case 'announcement':
        return NotificationType.announcement;
      case 'member_joined':
        return NotificationType.memberJoined;
      case 'discussion_reply':
        return NotificationType.discussionReply;
      default:
        return NotificationType.resourceAdded;
    }
  }

  String get typeToString {
    switch (type) {
      case NotificationType.resourceAdded:
        return 'resource_added';
      case NotificationType.announcement:
        return 'announcement';
      case NotificationType.memberJoined:
        return 'member_joined';
      case NotificationType.discussionReply:
        return 'discussion_reply';
    }
  }

  /// Returns a short user-friendly label for the type
  String get typeLabel {
    switch (type) {
      case NotificationType.resourceAdded:
        return 'New Resource';
      case NotificationType.announcement:
        return 'Announcement';
      case NotificationType.memberJoined:
        return 'New Member';
      case NotificationType.discussionReply:
        return 'Discussion';
    }
  }

  /// Returns an emoji for the notification type
  String get typeEmoji {
    switch (type) {
      case NotificationType.resourceAdded:
        return '📦';
      case NotificationType.announcement:
        return '📢';
      case NotificationType.memberJoined:
        return '👤';
      case NotificationType.discussionReply:
        return '💬';
    }
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
