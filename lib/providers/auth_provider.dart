import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  Profile? _profile;
  bool _isLoading = false;
  String? _error;

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _authService.isLoggedIn;
  String? get userId => _authService.userId;
  User? get currentUser => _authService.currentUser;

  /// Converts raw exceptions into friendly messages shown on the login screen.
  String _friendlyError(Object e) {
    if (e is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (e is TimeoutException) {
      return 'Server is temporarily unreachable. Retried 3 times. Please try again later.';
    }
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email before logging in.';
    }
    if (msg.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('network') || msg.contains('connection') || msg.contains('socket')) {
      return 'Network error. Please check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  AuthProvider() {
    _authService.authStateChanges.listen((state) async {
      if (state.event == AuthChangeEvent.signedIn) {
        await loadProfile();
      } else if (state.event == AuthChangeEvent.signedOut) {
        _profile = null;
        notifyListeners();
      }
    });
  }

  Future<void> loadProfile() async {
    try {
      _profile = await _authService.getProfile();
      notifyListeners();
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      await loadProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signIn(email: email, password: password);
      await loadProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _profile = null;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? fullName,
    String? username,
    String? bio,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.updateProfile(
        fullName: fullName,
        username: username,
        bio: bio,
      );
      await loadProfile();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
