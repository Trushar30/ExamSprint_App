class ClassModel {
  final String id;
  final String name;
  final String description;
  final String code;
  final String? semester;
  final String? department;
  final String? university;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? memberCount;
  final int? subjectCount;
  final String? userRole;

  ClassModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.code,
    this.semester,
    this.department,
    this.university,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.memberCount,
    this.subjectCount,
    this.userRole,
  });

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      code: map['code'] as String,
      semester: map['semester'] as String?,
      department: map['department'] as String?,
      university: map['university'] as String?,
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      memberCount: map['member_count'] as int?,
      subjectCount: map['subject_count'] as int?,
      userRole: map['user_role'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'code': code,
      'semester': semester,
      'department': department,
      'university': university,
      'created_by': createdBy,
    };
  }

  bool get isAdmin => userRole == 'admin';
  bool get isCoAdmin => userRole == 'co_admin';
  bool get isMember => userRole == 'member';
  bool get canManage => isAdmin || isCoAdmin;
}
