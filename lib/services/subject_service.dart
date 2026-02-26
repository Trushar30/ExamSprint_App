import '../config/supabase_config.dart';
import '../models/subject.dart';

class SubjectService {
  final _client = SupabaseConfig.client;

  Future<List<Subject>> getSubjects(String classId) async {
    final data = await _client
        .from('subjects')
        .select('*, resources(id)')
        .eq('class_id', classId)
        .order('name');

    return (data as List).map((item) {
      final map = Map<String, dynamic>.from(item);
      map['resource_count'] = (item['resources'] as List?)?.length ?? 0;
      return Subject.fromMap(map);
    }).toList();
  }

  Future<Subject> createSubject({
    required String classId,
    required String name,
    required String userId,
    String? code,
    String? professor,
    String? description,
  }) async {
    final data = await _client
        .from('subjects')
        .insert({
          'class_id': classId,
          'name': name,
          'code': code,
          'professor': professor,
          'description': description ?? '',
          'created_by': userId,
        })
        .select()
        .single();

    return Subject.fromMap(data);
  }

  Future<void> updateSubject({
    required String subjectId,
    String? name,
    String? code,
    String? professor,
    String? description,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (code != null) updates['code'] = code;
    if (professor != null) updates['professor'] = professor;
    if (description != null) updates['description'] = description;

    await _client.from('subjects').update(updates).eq('id', subjectId);
  }

  Future<void> deleteSubject(String subjectId) async {
    await _client.from('subjects').delete().eq('id', subjectId);
  }
}
