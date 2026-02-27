class ResourceText {
  final String id;
  final String resourceId;
  final String extractedText;
  final int textLength;
  final String extractionStatus;
  final DateTime? extractedAt;
  final DateTime createdAt;

  ResourceText({
    required this.id,
    required this.resourceId,
    this.extractedText = '',
    this.textLength = 0,
    this.extractionStatus = 'pending',
    this.extractedAt,
    required this.createdAt,
  });

  factory ResourceText.fromMap(Map<String, dynamic> map) {
    return ResourceText(
      id: map['id'] as String,
      resourceId: map['resource_id'] as String,
      extractedText: map['extracted_text'] as String? ?? '',
      textLength: map['text_length'] as int? ?? 0,
      extractionStatus: map['extraction_status'] as String? ?? 'pending',
      extractedAt: map['extracted_at'] != null
          ? DateTime.parse(map['extracted_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'resource_id': resourceId,
      'extracted_text': extractedText,
      'text_length': textLength,
      'extraction_status': extractionStatus,
      'extracted_at': extractedAt?.toIso8601String(),
    };
  }

  bool get isCompleted => extractionStatus == 'completed';
  bool get isFailed => extractionStatus == 'failed';
  bool get isPending => extractionStatus == 'pending';
  bool get hasText => extractedText.isNotEmpty;
}
