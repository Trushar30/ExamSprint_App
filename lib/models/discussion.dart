import 'profile.dart';

class Discussion {
  final String id;
  final String classId;
  final String? userId;
  final String message;
  final DateTime createdAt;
  final Profile? profile;

  Discussion({
    required this.id,
    required this.classId,
    this.userId,
    required this.message,
    required this.createdAt,
    this.profile,
  });

  factory Discussion.fromMap(Map<String, dynamic> map) {
    return Discussion(
      id: map['id'] as String,
      classId: map['class_id'] as String,
      userId: map['user_id'] as String?,
      message: map['message'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      profile: map['profiles'] != null
          ? Profile.fromMap(map['profiles'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'class_id': classId,
      'user_id': userId,
      'message': message,
    };
  }
}

class Announcement {
  final String id;
  final String classId;
  final String? userId;
  final String title;
  final String content;
  final DateTime createdAt;
  final Profile? profile;

  Announcement({
    required this.id,
    required this.classId,
    this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.profile,
  });

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] as String,
      classId: map['class_id'] as String,
      userId: map['user_id'] as String?,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      profile: map['profiles'] != null
          ? Profile.fromMap(map['profiles'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'class_id': classId,
      'user_id': userId,
      'title': title,
      'content': content,
    };
  }
}
