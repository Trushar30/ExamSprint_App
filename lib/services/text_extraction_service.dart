import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../config/supabase_config.dart';
import '../models/resource_text.dart';

class TextExtractionService {
  final _client = SupabaseConfig.client;

  /// Maximum characters to store per resource (to keep AI context manageable)
  static const int _maxTextLength = 50000;

  /// Extract text from a PDF file bytes
  String extractTextFromPdf(Uint8List bytes) {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      document.dispose();

      if (text.length > _maxTextLength) {
        return text.substring(0, _maxTextLength);
      }
      return text;
    } catch (e) {
      return '';
    }
  }

  /// Extract text from a text-based file
  String extractTextFromBytes(Uint8List bytes) {
    try {
      final text = String.fromCharCodes(bytes);
      if (text.length > _maxTextLength) {
        return text.substring(0, _maxTextLength);
      }
      return text;
    } catch (e) {
      return '';
    }
  }

  /// Download file bytes from a public Supabase Storage URL
  Future<Uint8List?> _downloadFileBytes(String fileUrl) async {
    try {
      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Main orchestrator: extract text and store in database
  Future<void> extractAndStore({
    required String resourceId,
    Uint8List? fileBytes,
    String? fileType,
    String? fileUrl,
    String? linkUrl,
    String? title,
    String? description,
  }) async {
    try {
      // Create a pending record first
      await _client.from('resource_text_content').upsert({
        'resource_id': resourceId,
        'extracted_text': '',
        'text_length': 0,
        'extraction_status': 'pending',
      }, onConflict: 'resource_id');

      // If we don't have file bytes but have a URL, download them
      Uint8List? bytes = fileBytes;
      if (bytes == null && fileUrl != null && fileUrl.isNotEmpty) {
        bytes = await _downloadFileBytes(fileUrl);
      }

      String extractedText = '';

      // Extract based on file type
      if (bytes != null && fileType != null) {
        final type = fileType.toLowerCase();
        if (type == 'pdf') {
          extractedText = extractTextFromPdf(bytes);
        } else if (['txt', 'md', 'csv', 'json', 'xml', 'html']
            .contains(type)) {
          extractedText = extractTextFromBytes(bytes);
        }
      }

      // For links or files without extractable text, use title + description
      if (extractedText.isEmpty) {
        final parts = <String>[];
        if (title != null && title.isNotEmpty) parts.add('Title: $title');
        if (description != null && description.isNotEmpty) {
          parts.add('Description: $description');
        }
        if (linkUrl != null && linkUrl.isNotEmpty) {
          parts.add('Link: $linkUrl');
        }
        extractedText = parts.join('\n');
      }

      // Update the record with extracted text
      await _client.from('resource_text_content').upsert({
        'resource_id': resourceId,
        'extracted_text': extractedText,
        'text_length': extractedText.length,
        'extraction_status':
            extractedText.isNotEmpty ? 'completed' : 'failed',
        'extracted_at': DateTime.now().toIso8601String(),
      }, onConflict: 'resource_id');
    } catch (e) {
      // Mark as failed
      try {
        await _client.from('resource_text_content').upsert({
          'resource_id': resourceId,
          'extracted_text': '',
          'text_length': 0,
          'extraction_status': 'failed',
          'extracted_at': DateTime.now().toIso8601String(),
        }, onConflict: 'resource_id');
      } catch (_) {}
    }
  }

  /// Process all resources that are missing text extraction or stuck
  /// in pending/failed status for a given subject.
  Future<int> extractMissingResources(String subjectId) async {
    try {
      // Get all resources for the subject
      final resources = await _client
          .from('resources')
          .select('id, title, description, file_url, link_url, file_type')
          .eq('subject_id', subjectId);

      int processed = 0;

      for (final res in (resources as List)) {
        final resourceId = res['id'] as String;

        // Check if extraction already completed
        final existing = await _client
            .from('resource_text_content')
            .select('extraction_status')
            .eq('resource_id', resourceId)
            .maybeSingle();

        // Skip if already completed
        if (existing != null &&
            existing['extraction_status'] == 'completed') {
          continue;
        }

        // Run extraction (will download file from URL)
        await extractAndStore(
          resourceId: resourceId,
          fileType: res['file_type'] as String?,
          fileUrl: res['file_url'] as String?,
          linkUrl: res['link_url'] as String?,
          title: res['title'] as String?,
          description: res['description'] as String?,
        );
        processed++;
      }

      return processed;
    } catch (e) {
      return 0;
    }
  }

  /// Get extracted text for a single resource
  Future<ResourceText?> getResourceText(String resourceId) async {
    try {
      final data = await _client
          .from('resource_text_content')
          .select()
          .eq('resource_id', resourceId)
          .maybeSingle();
      if (data == null) return null;
      return ResourceText.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  /// Get all extracted texts for a subject (for AI context building)
  Future<List<ResourceText>> getResourceTextsForSubject(
      String subjectId) async {
    try {
      final data = await _client
          .from('resource_text_content')
          .select('*, resources!inner(subject_id)')
          .eq('resources.subject_id', subjectId)
          .eq('extraction_status', 'completed');

      return (data as List).map((item) => ResourceText.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Build a combined context string from all resources in given subjects
  Future<String> buildContextForSubjects(List<String> subjectIds) async {
    final allTexts = <String>[];

    for (final subjectId in subjectIds) {
      final texts = await getResourceTextsForSubject(subjectId);
      for (final t in texts) {
        if (t.hasText) {
          allTexts.add(t.extractedText);
        }
      }
    }

    // Combine and limit total context
    final combined = allTexts.join('\n\n---\n\n');
    if (combined.length > 100000) {
      return combined.substring(0, 100000);
    }
    return combined;
  }
}
