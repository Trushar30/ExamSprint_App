class Subject {
  final String id;
  final String classId;
  final String name;
  final String? code;
  final String? professor;
  final String description;
  final String? createdBy;
  final DateTime createdAt;
  final int? resourceCount;

  Subject({
    required this.id,
    required this.classId,
    required this.name,
    this.code,
    this.professor,
    this.description = '',
    this.createdBy,
    required this.createdAt,
    this.resourceCount,
  });

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as String,
      classId: map['class_id'] as String,
      name: map['name'] as String,
      code: map['code'] as String?,
      professor: map['professor'] as String?,
      description: map['description'] as String? ?? '',
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      resourceCount: map['resource_count'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'class_id': classId,
      'name': name,
      'code': code,
      'professor': professor,
      'description': description,
      'created_by': createdBy,
    };
  }
}
