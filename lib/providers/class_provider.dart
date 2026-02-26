import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../models/class_member.dart';
import '../services/class_service.dart';

class ClassProvider extends ChangeNotifier {
  final ClassService _classService = ClassService();

  List<ClassModel> _classes = [];
  ClassModel? _currentClass;
  List<ClassMember> _members = [];
  bool _isLoading = false;
  String? _error;

  List<ClassModel> get classes => _classes;
  ClassModel? get currentClass => _currentClass;
  List<ClassMember> get members => _members;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserClasses(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _classes = await _classService.getUserClasses(userId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<ClassModel?> createClass({
    required String name,
    required String userId,
    String? description,
    String? semester,
    String? department,
    String? university,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newClass = await _classService.createClass(
        name: name,
        userId: userId,
        description: description,
        semester: semester,
        department: department,
        university: university,
      );
      _classes.insert(0, newClass);
      _isLoading = false;
      notifyListeners();
      return newClass;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<ClassModel?> lookupClassByCode(String code) async {
    try {
      return await _classService.getClassByCode(code);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> joinClass({
    required String classId,
    required String userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final isMember = await _classService.isMember(
        classId: classId,
        userId: userId,
      );
      if (isMember) {
        _error = 'You are already a member of this class';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _classService.joinClass(classId: classId, userId: userId);
      await loadUserClasses(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadClassDetails(String classId, String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentClass = await _classService.getClassDetails(classId, userId);
      _members = await _classService.getClassMembers(classId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateMemberRole({
    required String memberId,
    required String newRole,
    required String classId,
    required String userId,
  }) async {
    try {
      await _classService.updateMemberRole(
        memberId: memberId,
        newRole: newRole,
      );
      await loadClassDetails(classId, userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeMember({
    required String memberId,
    required String classId,
    required String userId,
  }) async {
    try {
      await _classService.removeMember(memberId);
      await loadClassDetails(classId, userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> leaveClass({
    required String classId,
    required String userId,
  }) async {
    try {
      await _classService.leaveClass(classId: classId, userId: userId);
      _classes.removeWhere((c) => c.id == classId);
      _currentClass = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
