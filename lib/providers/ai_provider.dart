import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/ai_service.dart';
import '../services/text_extraction_service.dart';

// ── Quiz Question Model ─────────────────────────────────────────────────────

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      correctIndex: json['correctIndex'] as int? ?? 0,
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

// ── AI Provider ─────────────────────────────────────────────────────────────

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
  List<QuizQuestion> _quizQuestions = [];
  String _quizRawFallback = '';
  String _summaryResult = '';
  String _studyPlanResult = '';
  List<Map<String, String>> _chatHistory = [];

  // Quiz interactive state
  Map<int, int> _selectedAnswers = {};
  Set<int> _revealedAnswers = {};
  int _currentQuestionIndex = 0;
  bool _quizCompleted = false;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<Subject> get availableSubjects => _availableSubjects;
  Subject? get selectedSubject => _selectedSubject;
  String get context => _context;
  bool get isLoadingContext => _isLoadingContext;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  bool get hasContext => _context.isNotEmpty;

  List<QuizQuestion> get quizQuestions => _quizQuestions;
  bool get hasQuiz => _quizQuestions.isNotEmpty;
  String get quizRawFallback => _quizRawFallback;
  String get summaryResult => _summaryResult;
  String get studyPlanResult => _studyPlanResult;
  List<Map<String, String>> get chatHistory => _chatHistory;

  // Quiz interactive getters
  Map<int, int> get selectedAnswers => _selectedAnswers;
  Set<int> get revealedAnswers => _revealedAnswers;
  int get currentQuestionIndex => _currentQuestionIndex;
  bool get quizCompleted => _quizCompleted;

  int get quizScore {
    int score = 0;
    for (final entry in _selectedAnswers.entries) {
      if (entry.key < _quizQuestions.length &&
          entry.value == _quizQuestions[entry.key].correctIndex) {
        score++;
      }
    }
    return score;
  }

  // ── Subject Management ─────────────────────────────────────────────────────
  void setAvailableSubjects(List<Subject> subjects) {
    _availableSubjects = subjects;
    notifyListeners();
  }

  Future<void> selectSubject(Subject? subject) async {
    if (subject?.id == _selectedSubject?.id) return;

    _selectedSubject = subject;
    _quizQuestions = [];
    _quizRawFallback = '';
    _summaryResult = '';
    _studyPlanResult = '';
    _chatHistory = [];
    _error = null;
    _resetQuizState();
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
      // First, process any resources that haven't been extracted yet
      for (final subjectId in subjectIds) {
        await _textExtractionService.extractMissingResources(subjectId);
      }

      // Then build context from all completed extractions
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
    _quizQuestions = [];
    _quizRawFallback = '';
    _resetQuizState();
    notifyListeners();

    try {
      final raw = await _aiService.generateQuiz(
        context: _context,
        subjectName: _selectedSubject!.name,
        questionCount: questionCount,
      );

      // Try to parse JSON from the response
      _quizQuestions = _parseQuizJson(raw);

      if (_quizQuestions.isEmpty) {
        // Fallback: store raw for markdown display
        _quizRawFallback = raw;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isGenerating = false;
    notifyListeners();
  }

  List<QuizQuestion> _parseQuizJson(String raw) {
    try {
      // Strip markdown code fences if AI wrapped in them
      String cleaned = raw.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
        cleaned = cleaned.replaceFirst(RegExp(r'\n?```\s*$'), '');
        cleaned = cleaned.trim();
      }

      final decoded = jsonDecode(cleaned);

      if (decoded is List) {
        return decoded
            .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
            .where((q) => q.question.isNotEmpty && q.options.length == 4)
            .toList();
      }

      // Handle { "questions": [...] } wrapper
      if (decoded is Map && decoded.containsKey('questions')) {
        final list = decoded['questions'] as List;
        return list
            .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
            .where((q) => q.question.isNotEmpty && q.options.length == 4)
            .toList();
      }
    } catch (_) {
      // JSON parsing failed — will fall back to raw display
    }
    return [];
  }

  // ── Quiz Interaction ──────────────────────────────────────────────────────

  void selectAnswer(int questionIndex, int optionIndex) {
    if (_revealedAnswers.contains(questionIndex)) return; // already locked
    _selectedAnswers[questionIndex] = optionIndex;
    notifyListeners();
  }

  void revealAnswer(int questionIndex) {
    _revealedAnswers.add(questionIndex);
    notifyListeners();
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < _quizQuestions.length) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _quizQuestions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  void completeQuiz() {
    _quizCompleted = true;
    notifyListeners();
  }

  void restartQuiz() {
    _resetQuizState();
    notifyListeners();
  }

  void _resetQuizState() {
    _selectedAnswers = {};
    _revealedAnswers = {};
    _currentQuestionIndex = 0;
    _quizCompleted = false;
  }

  // ── Other AI Features (unchanged) ─────────────────────────────────────────

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
    _quizQuestions = [];
    _quizRawFallback = '';
    _summaryResult = '';
    _studyPlanResult = '';
    _chatHistory = [];
    _error = null;
    _resetQuizState();
    notifyListeners();
  }
}
