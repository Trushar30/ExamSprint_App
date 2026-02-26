import 'profile.dart';

class ClassMember {
  final String id;
  final String classId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  final Profile? profile;

  ClassMember({
    required this.id,
    required this.classId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.profile,
  });

  factory ClassMember.fromMap(Map<String, dynamic> map) {
    return ClassMember(
      id: map['id'] as String,
      classId: map['class_id'] as String,
      userId: map['user_id'] as String,
      role: map['role'] as String,
      joinedAt: DateTime.parse(map['joined_at'] as String),
      profile: map['profiles'] != null
          ? Profile.fromMap(map['profiles'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isCoAdmin => role == 'co_admin';
  bool get isMember => role == 'member';
  bool get canManage => isAdmin || isCoAdmin;

  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'co_admin':
        return 'Co-Admin';
      default:
        return 'Member';
    }
  }
}
