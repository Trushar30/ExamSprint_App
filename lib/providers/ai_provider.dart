import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/ai_service.dart';
import '../services/text_extraction_service.dart';

class AiProvider extends ChangeNotifier {
  final AiService _aiService = AiService();
  final TextExtractionService _textExtractionService = TextExtractionService();

  // ── State ──────────────────────────────────────────────────────────────────
  List<Subject> _availableSubjects = [];
  Subject? _selectedSubject;
  String _context = '';
  bool _isLoadingContext = false;
  bool _isGenerating = false;
  String? _error;

  // AI Results
  String _quizResult = '';
  String _summaryResult = '';
  String _studyPlanResult = '';
  List<Map<String, String>> _chatHistory = [];

  // ── Getters ────────────────────────────────────────────────────────────────
  List<Subject> get availableSubjects => _availableSubjects;
  Subject? get selectedSubject => _selectedSubject;
  String get context => _context;
  bool get isLoadingContext => _isLoadingContext;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  bool get hasContext => _context.isNotEmpty;

  String get quizResult => _quizResult;
  String get summaryResult => _summaryResult;
  String get studyPlanResult => _studyPlanResult;
  List<Map<String, String>> get chatHistory => _chatHistory;

  // ── Subject Management ─────────────────────────────────────────────────────
  void setAvailableSubjects(List<Subject> subjects) {
    _availableSubjects = subjects;
    notifyListeners();
  }

  Future<void> selectSubject(Subject? subject) async {
    if (subject?.id == _selectedSubject?.id) return;

    _selectedSubject = subject;
    _quizResult = '';
    _summaryResult = '';
    _studyPlanResult = '';
    _chatHistory = [];
    _error = null;
    notifyListeners();

    if (subject != null) {
      await _loadContext([subject.id]);
    } else {
      _context = '';
      notifyListeners();
    }
  }

  Future<void> _loadContext(List<String> subjectIds) async {
    _isLoadingContext = true;
    _error = null;
    notifyListeners();

    try {
      _context =
          await _textExtractionService.buildContextForSubjects(subjectIds);
    } catch (e) {
      _error = 'Failed to load resource context: $e';
    }

    _isLoadingContext = false;
    notifyListeners();
  }

  // ── AI Features ────────────────────────────────────────────────────────────

  Future<void> generateQuiz({int questionCount = 10}) async {
    if (!hasContext || _selectedSubject == null) {
      _error = 'Please select a subject with resources first';
      notifyListeners();
      return;
    }

    _isGenerating = true;
    _error = null;
    _quizResult = '';
    notifyListeners();

    try {
      _quizResult = await _aiService.generateQuiz(
        context: _context,
        subjectName: _selectedSubject!.name,
        questionCount: questionCount,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isGenerating = false;
    notifyListeners();
  }

  Future<void> generateSummary() async {
    if (!hasContext || _selectedSubject == null) {
      _error = 'Please select a subject with resources first';
      notifyListeners();
      return;
    }

    _isGenerating = true;
    _error = null;
    _summaryResult = '';
    notifyListeners();

    try {
      _summaryResult = await _aiService.generateSummary(
        context: _context,
        subjectName: _selectedSubject!.name,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isGenerating = false;
    notifyListeners();
  }

  Future<void> askQuestion(String question) async {
    if (!hasContext || _selectedSubject == null) {
      _error = 'Please select a subject with resources first';
      notifyListeners();
      return;
    }

    _chatHistory.add({'role': 'user', 'content': question});
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final answer = await _aiService.answerQuestion(
        context: _context,
        question: question,
        subjectName: _selectedSubject!.name,
        chatHistory: _chatHistory,
      );
      _chatHistory.add({'role': 'assistant', 'content': answer});
    } catch (e) {
      _error = e.toString();
      _chatHistory.add({
        'role': 'assistant',
        'content': 'Sorry, I encountered an error. Please try again.',
      });
    }

    _isGenerating = false;
    notifyListeners();
  }

  Future<void> generateStudyPlan({int days = 7}) async {
    if (!hasContext || _selectedSubject == null) {
      _error = 'Please select a subject with resources first';
      notifyListeners();
      return;
    }

    _isGenerating = true;
    _error = null;
    _studyPlanResult = '';
    notifyListeners();

    try {
      _studyPlanResult = await _aiService.generateStudyPlan(
        context: _context,
        subjectName: _selectedSubject!.name,
        daysAvailable: days,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isGenerating = false;
    notifyListeners();
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  void clearChat() {
    _chatHistory = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearAll() {
    _selectedSubject = null;
    _context = '';
    _quizResult = '';
    _summaryResult = '';
    _studyPlanResult = '';
    _chatHistory = [];
    _error = null;
    notifyListeners();
  }
}
