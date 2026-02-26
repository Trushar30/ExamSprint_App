import 'profile.dart';

class Resource {
  final String id;
  final String subjectId;
  final String title;
  final String description;
  final String? fileUrl;
  final String? linkUrl;
  final String? fileType;
  final int? fileSize;
  final String? uploadedBy;
  final DateTime createdAt;
  final List<String> tags;
  final Profile? uploader;

  Resource({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description = '',
    this.fileUrl,
    this.linkUrl,
    this.fileType,
    this.fileSize,
    this.uploadedBy,
    required this.createdAt,
    this.tags = const [],
    this.uploader,
  });

  factory Resource.fromMap(Map<String, dynamic> map) {
    List<String> parseTags = [];
    if (map['resource_tags'] != null) {
      parseTags = (map['resource_tags'] as List)
          .map((t) => t['tag'] as String)
          .toList();
    }

    return Resource(
      id: map['id'] as String,
      subjectId: map['subject_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      fileUrl: map['file_url'] as String?,
      linkUrl: map['link_url'] as String?,
      fileType: map['file_type'] as String?,
      fileSize: map['file_size'] as int?,
      uploadedBy: map['uploaded_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      tags: parseTags,
      uploader: map['profiles'] != null
          ? Profile.fromMap(map['profiles'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject_id': subjectId,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'link_url': linkUrl,
      'file_type': fileType,
      'file_size': fileSize,
      'uploaded_by': uploadedBy,
    };
  }

  bool get isFile => fileUrl != null && fileUrl!.isNotEmpty;
  bool get isLink => linkUrl != null && linkUrl!.isNotEmpty;

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '${fileSize}B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get typeIcon {
    switch (fileType?.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'ppt':
      case 'pptx':
        return '📊';
      case 'xls':
      case 'xlsx':
        return '📈';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return '🖼️';
      case 'zip':
      case 'rar':
        return '📦';
      default:
        if (isLink) return '🔗';
        return '📎';
    }
  }
}
