import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/profile.dart';

class AuthService {
  final _client = SupabaseConfig.client;

  User? get currentUser => _client.auth.currentUser;
  String? get userId => currentUser?.id;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Retries [fn] up to [maxAttempts] times with a [timeout] per attempt.
  /// Waits [retryDelay] between attempts. Re-throws the last error if all fail.
  Future<T> _withRetry<T>(
    Future<T> Function() fn, {
    int maxAttempts = 3,
    Duration timeout = const Duration(seconds: 15),
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    Object? lastError;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await fn().timeout(timeout);
      } on TimeoutException catch (e) {
        lastError = e;
      } on SocketException catch (e) {
        lastError = e;
      } catch (e) {
        // Non-network errors (e.g. wrong password) should NOT be retried
        rethrow;
      }
      if (attempt < maxAttempts) {
        await Future.delayed(retryDelay);
      }
    }
    throw lastError!;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return _withRetry(() => _client.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': fullName},
        ));
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _withRetry(() => _client.auth.signInWithPassword(
          email: email,
          password: password,
        ));
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Profile?> getProfile() async {
    if (userId == null) return null;
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId!)
        .single();
    return Profile.fromMap(data);
  }

  Future<void> updateProfile({
    String? fullName,
    String? username,
    String? avatarUrl,
    String? bio,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (fullName != null) updates['full_name'] = fullName;
    if (username != null) updates['username'] = username;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (bio != null) updates['bio'] = bio;

    await _client.from('profiles').update(updates).eq('id', userId!);
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
