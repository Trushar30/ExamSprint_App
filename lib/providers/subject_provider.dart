import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/subject_service.dart';

class SubjectProvider extends ChangeNotifier {
  final SubjectService _subjectService = SubjectService();

  List<Subject> _subjects = [];
  bool _isLoading = false;
  String? _error;

  List<Subject> get subjects => _subjects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSubjects(String classId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _subjects = await _subjectService.getSubjects(classId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Subject?> createSubject({
    required String classId,
    required String name,
    required String userId,
    String? code,
    String? professor,
    String? description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final subject = await _subjectService.createSubject(
        classId: classId,
        name: name,
        userId: userId,
        code: code,
        professor: professor,
        description: description,
      );
      _subjects.add(subject);
      _isLoading = false;
      notifyListeners();
      return subject;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteSubject(String subjectId, String classId) async {
    try {
      await _subjectService.deleteSubject(subjectId);
      _subjects.removeWhere((s) => s.id == subjectId);
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
