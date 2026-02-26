import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/discussion.dart';

class DiscussionService {
  final _client = SupabaseConfig.client;
  RealtimeChannel? _channel;

  Future<List<Discussion>> getMessages(String classId, {int limit = 50}) async {
    final data = await _client
        .from('discussions')
        .select('*, profiles(*)')
        .eq('class_id', classId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((item) => Discussion.fromMap(item))
        .toList()
        .reversed
        .toList();
  }

  Future<Discussion> sendMessage({
    required String classId,
    required String userId,
    required String message,
  }) async {
    final data = await _client
        .from('discussions')
        .insert({
          'class_id': classId,
          'user_id': userId,
          'message': message,
        })
        .select('*, profiles(*)')
        .single();

    return Discussion.fromMap(data);
  }

  StreamSubscription<List<Map<String, dynamic>>> subscribeToMessages(
    String classId,
    void Function(Discussion) onMessage,
  ) {
    return _client
        .from('discussions')
        .stream(primaryKey: ['id'])
        .eq('class_id', classId)
        .order('created_at')
        .listen((data) async {
      if (data.isNotEmpty) {
        final latest = data.last;
        // Fetch with profile data
        final full = await _client
            .from('discussions')
            .select('*, profiles(*)')
            .eq('id', latest['id'])
            .single();
        onMessage(Discussion.fromMap(full));
      }
    });
  }

  void dispose() {
    _channel?.unsubscribe();
  }

  // Announcements
  Future<List<Announcement>> getAnnouncements(String classId) async {
    final data = await _client
        .from('announcements')
        .select('*, profiles(*)')
        .eq('class_id', classId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((item) => Announcement.fromMap(item))
        .toList();
  }

  Future<Announcement> createAnnouncement({
    required String classId,
    required String userId,
    required String title,
    required String content,
  }) async {
    final data = await _client
        .from('announcements')
        .insert({
          'class_id': classId,
          'user_id': userId,
          'title': title,
          'content': content,
        })
        .select('*, profiles(*)')
        .single();

    return Announcement.fromMap(data);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _client.from('announcements').delete().eq('id', id);
  }
}
