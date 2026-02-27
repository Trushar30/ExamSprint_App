import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/resource.dart';
import 'notification_service.dart';

class ResourceService {
  final _client = SupabaseConfig.client;

  Future<List<Resource>> getResources(String subjectId, {String? tag}) async {
    var query = _client
        .from('resources')
        .select('*, resource_tags(*), profiles(*)')
        .eq('subject_id', subjectId)
        .order('created_at', ascending: false);

    final data = await query;

    List<Resource> resources =
        (data as List).map((item) => Resource.fromMap(item)).toList();

    if (tag != null && tag.isNotEmpty) {
      resources = resources.where((r) =>
        r.tags.any((t) => t.toLowerCase() == tag.toLowerCase())
      ).toList();
    }

    return resources;
  }

  Future<String> uploadFile({
    required String subjectId,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final ext = p.extension(fileName);
    final path = '$subjectId/${DateTime.now().millisecondsSinceEpoch}$ext';

    await _client.storage.from('resources').uploadBinary(
      path,
      fileBytes,
      fileOptions: FileOptions(contentType: _getMimeType(ext)),
    );

    final url = _client.storage.from('resources').getPublicUrl(path);
    return url;
  }

  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
      case '.docx':
        return 'application/msword';
      case '.ppt':
      case '.pptx':
        return 'application/vnd.ms-powerpoint';
      case '.xls':
      case '.xlsx':
        return 'application/vnd.ms-excel';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  Future<Resource> addResource({
    required String subjectId,
    required String title,
    required String userId,
    String? description,
    String? fileUrl,
    String? linkUrl,
    String? fileType,
    int? fileSize,
    List<String> tags = const [],
  }) async {
    final data = await _client
        .from('resources')
        .insert({
          'subject_id': subjectId,
          'title': title,
          'description': description ?? '',
          'file_url': fileUrl,
          'link_url': linkUrl,
          'file_type': fileType,
          'file_size': fileSize,
          'uploaded_by': userId,
        })
        .select()
        .single();

    // Add tags
    if (tags.isNotEmpty) {
      await _client.from('resource_tags').insert(
        tags.map((tag) => {
          'resource_id': data['id'],
          'tag': tag,
        }).toList(),
      );
    }

    final resource = Resource.fromMap({...data, 'resource_tags': tags.map((t) => {'tag': t}).toList()});

    // Notify class members about the new resource
    try {
      // Look up class_id from the subject
      final subject = await _client
          .from('subjects')
          .select('class_id, name')
          .eq('id', subjectId)
          .maybeSingle();
      if (subject != null) {
        await NotificationService.notifyClassMembers(
          classId: subject['class_id'] as String,
          senderUserId: userId,
          type: 'resource_added',
          title: '📦 New resource in ${subject['name']}',
          body: title,
          data: {
            'class_id': subject['class_id'],
            'subject_id': subjectId,
            'resource_id': resource.id,
          },
        );
      }
    } catch (_) {
      // Non-critical
    }

    return resource;
  }

  Future<List<Resource>> getUserResources(String userId) async {
    final data = await _client
        .from('resources')
        .select('*, resource_tags(*), profiles(*)')
        .eq('uploaded_by', userId)
        .order('created_at', ascending: false);

    return (data as List).map((item) => Resource.fromMap(item)).toList();
  }

  Future<void> deleteResource(String resourceId) async {
    await _client.from('resources').delete().eq('id', resourceId);
  }

  Future<List<String>> getAllTags(String subjectId) async {
    final data = await _client
        .from('resource_tags')
        .select('tag, resources!inner(subject_id)')
        .eq('resources.subject_id', subjectId);

    final tags = (data as List).map((item) => item['tag'] as String).toSet().toList();
    tags.sort();
    return tags;
  }
}
