import 'dart:math';
import '../config/supabase_config.dart';
import '../models/class_model.dart';
import '../models/class_member.dart';
import 'notification_service.dart';

class ClassService {
  final _client = SupabaseConfig.client;

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<ClassModel> createClass({
    required String name,
    required String userId,
    String? description,
    String? semester,
    String? department,
    String? university,
  }) async {
    String code = _generateCode();

    // Ensure unique code
    bool exists = true;
    while (exists) {
      final check = await _client
          .from('classes')
          .select('id')
          .eq('code', code)
          .maybeSingle();
      if (check == null) {
        exists = false;
      } else {
        code = _generateCode();
      }
    }

    final classData = await _client
        .from('classes')
        .insert({
          'name': name,
          'description': description ?? '',
          'code': code,
          'semester': semester,
          'department': department,
          'university': university,
          'created_by': userId,
        })
        .select()
        .single();

    // Add creator as admin
    await _client.from('class_members').insert({
      'class_id': classData['id'],
      'user_id': userId,
      'role': 'admin',
    });

    return ClassModel.fromMap(classData);
  }

  Future<ClassModel?> getClassByCode(String code) async {
    final data = await _client
        .from('classes')
        .select()
        .eq('code', code.toUpperCase())
        .maybeSingle();
    if (data == null) return null;
    return ClassModel.fromMap(data);
  }

  Future<void> joinClass({
    required String classId,
    required String userId,
  }) async {
    await _client.from('class_members').insert({
      'class_id': classId,
      'user_id': userId,
      'role': 'member',
    });

    // Notify existing class members about the new join
    try {
      // Get the user's name for the notification
      final profile = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      final name = profile?['full_name'] ?? 'Someone';

      // Get the class name
      final classData = await _client
          .from('classes')
          .select('name')
          .eq('id', classId)
          .maybeSingle();
      final className = classData?['name'] ?? 'the class';

      await NotificationService.notifyClassMembers(
        classId: classId,
        senderUserId: userId,
        type: 'member_joined',
        title: '👤 $name joined $className',
        body: 'Say hello to the new member!',
        data: {'class_id': classId},
      );
    } catch (_) {
      // Non-critical
    }
  }

  Future<bool> isMember({
    required String classId,
    required String userId,
  }) async {
    final data = await _client
        .from('class_members')
        .select('id')
        .eq('class_id', classId)
        .eq('user_id', userId)
        .maybeSingle();
    return data != null;
  }

  Future<List<ClassModel>> getUserClasses(String userId) async {
    final data = await _client
        .from('class_members')
        .select('role, classes(*)')
        .eq('user_id', userId)
        .order('joined_at', ascending: false);

    return (data as List).map((item) {
      final classMap = Map<String, dynamic>.from(item['classes']);
      classMap['user_role'] = item['role'];
      return ClassModel.fromMap(classMap);
    }).toList();
  }

  Future<ClassModel> getClassDetails(String classId, String userId) async {
    final classData = await _client
        .from('classes')
        .select()
        .eq('id', classId)
        .single();

    final memberData = await _client
        .from('class_members')
        .select('role')
        .eq('class_id', classId)
        .eq('user_id', userId)
        .single();

    final memberCount = await _client
        .from('class_members')
        .select('id')
        .eq('class_id', classId);

    final subjectCount = await _client
        .from('subjects')
        .select('id')
        .eq('class_id', classId);

    classData['user_role'] = memberData['role'];
    classData['member_count'] = (memberCount as List).length;
    classData['subject_count'] = (subjectCount as List).length;

    return ClassModel.fromMap(classData);
  }

  Future<List<ClassMember>> getClassMembers(String classId) async {
    final data = await _client
        .from('class_members')
        .select('*, profiles(*)')
        .eq('class_id', classId)
        .order('role')
        .order('joined_at');

    return (data as List)
        .map((item) => ClassMember.fromMap(item))
        .toList();
  }

  Future<void> updateMemberRole({
    required String memberId,
    required String newRole,
  }) async {
    await _client
        .from('class_members')
        .update({'role': newRole})
        .eq('id', memberId);
  }

  Future<void> removeMember(String memberId) async {
    await _client.from('class_members').delete().eq('id', memberId);
  }

  Future<void> leaveClass({
    required String classId,
    required String userId,
  }) async {
    await _client
        .from('class_members')
        .delete()
        .eq('class_id', classId)
        .eq('user_id', userId);
  }

  Future<void> deleteClass(String classId) async {
    await _client.from('classes').delete().eq('id', classId);
  }

  Future<void> updateClass({
    required String classId,
    String? name,
    String? description,
    String? semester,
    String? department,
    String? university,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (semester != null) updates['semester'] = semester;
    if (department != null) updates['department'] = department;
    if (university != null) updates['university'] = university;

    await _client.from('classes').update(updates).eq('id', classId);
  }
}
