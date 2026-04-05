import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme.dart';
import '../../providers/ai_provider.dart';

class AiQuizScreen extends StatefulWidget {
  const AiQuizScreen({super.key});

  @override
  State<AiQuizScreen> createState() => _AiQuizScreenState();
}

class _AiQuizScreenState extends State<AiQuizScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  int _questionCount = 10;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final aiProvider = context.watch<AiProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bg(brightness),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: AppTheme.textPrimary(brightness)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF9F67FF)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.quiz_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              'Smart Quiz',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(brightness),
              ),
            ),
          ],
        ),
        actions: [
          if (aiProvider.hasQuiz && !aiProvider.isGenerating)
            IconButton(
              icon: Icon(Icons.share_rounded,
                  color: AppTheme.textSecondary(brightness)),
              onPressed: () => _shareQuiz(aiProvider),
            ),
        ],
      ),
      body: _buildBody(brightness, isDark, aiProvider),
    );
  }

  Widget _buildBody(Brightness brightness, bool isDark, AiProvider aiProvider) {
    // Error state
    if (aiProvider.error != null && !aiProvider.isGenerating) {
      return _buildErrorState(brightness, aiProvider);
    }

    // Loading
    if (aiProvider.isGenerating) {
      return _buildLoadingState(brightness);
    }

    // Interactive quiz
    if (aiProvider.hasQuiz) {
      if (aiProvider.quizCompleted) {
        return _buildResultsSummary(brightness, isDark, aiProvider);
      }
      return _buildInteractiveQuiz(brightness, isDark, aiProvider);
    }

    // Fallback: raw markdown (if JSON parse failed)
    if (aiProvider.quizRawFallback.isNotEmpty) {
      return _buildRawFallback(brightness, isDark, aiProvider);
    }

    // Settings / generate screen
    return _buildSettings(brightness, isDark, aiProvider);
  }

  // ─── Settings Screen ───────────────────────────────────────────────────────

  Widget _buildSettings(
      Brightness brightness, bool isDark, AiProvider aiProvider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF9F67FF)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                    blurRadius: 24,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: const Icon(Icons.quiz_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'Generate a Quiz',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(brightness),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI will create MCQ questions from\n${aiProvider.selectedSubject?.name ?? "your"} resources',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textTertiary(brightness),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Question count selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassDecoration(brightness: brightness),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Number of Questions',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary(brightness),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [5, 10, 15, 20].map((count) {
                      final isSelected = _questionCount == count;
                      return GestureDetector(
                        onTap: () => setState(() => _questionCount = count),
                        child: AnimatedContainer(
                          duration: AppTheme.animFast,
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient:
                                isSelected ? AppTheme.primaryGradient : null,
                            color: isSelected
                                ? null
                                : AppTheme.surfaceAlt(brightness),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : AppTheme.border(brightness),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$count',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textPrimary(brightness),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    aiProvider.generateQuiz(questionCount: _questionCount),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate Quiz'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Loading State ─────────────────────────────────────────────────────────

  Widget _buildLoadingState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Generating your quiz...',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary(brightness),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a moment',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textTertiary(brightness),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Interactive Quiz (one question at a time) ─────────────────────────────

  Widget _buildInteractiveQuiz(
      Brightness brightness, bool isDark, AiProvider aiProvider) {
    final questions = aiProvider.quizQuestions;
    final currentIndex = aiProvider.currentQuestionIndex;
    final question = questions[currentIndex];
    final selectedOption = aiProvider.selectedAnswers[currentIndex];
    final isRevealed = aiProvider.revealedAnswers.contains(currentIndex);
    final answeredCount = aiProvider.revealedAnswers.length;

    return Column(
      children: [
        // Subject badge + progress
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              // Subject chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border:
                      Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.book_rounded,
                        size: 12, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 4),
                    Text(
                      aiProvider.selectedSubject?.name ?? 'Quiz',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Score badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '${aiProvider.quizScore}/$answeredCount correct',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${currentIndex + 1} of ${questions.length}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary(brightness),
                    ),
                  ),
                  Text(
                    '${((currentIndex + 1) / questions.length * 100).round()}%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (currentIndex + 1) / questions.length,
                  backgroundColor: AppTheme.surfaceAlt(brightness),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),

        // Question card
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                      color: AppTheme.border(brightness).withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    question.question,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(brightness),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Options
                ...List.generate(question.options.length, (optIndex) {
                  final label = String.fromCharCode(65 + optIndex); // A, B, C, D
                  final isSelected = selectedOption == optIndex;
                  final isCorrect = optIndex == question.correctIndex;

                  Color borderColor = AppTheme.border(brightness);
                  Color bgColor = isDark
                      ? AppColors.darkSurfaceAlt
                      : AppColors.lightSurfaceAlt;
                  Color labelColor = AppTheme.textPrimary(brightness);
                  Color letterBg = AppTheme.surfaceAlt(brightness);
                  Color letterColor = AppTheme.textSecondary(brightness);

                  if (isRevealed) {
                    if (isCorrect) {
                      borderColor = AppColors.success;
                      bgColor = AppColors.success.withOpacity(0.08);
                      labelColor = AppColors.success;
                      letterBg = AppColors.success;
                      letterColor = Colors.white;
                    } else if (isSelected && !isCorrect) {
                      borderColor = AppColors.error;
                      bgColor = AppColors.error.withOpacity(0.08);
                      labelColor = AppColors.error;
                      letterBg = AppColors.error;
                      letterColor = Colors.white;
                    }
                  } else if (isSelected) {
                    borderColor = AppColors.accent;
                    bgColor = AppColors.accent.withOpacity(0.08);
                    letterBg = AppColors.accent;
                    letterColor = Colors.white;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: isRevealed
                          ? null
                          : () => aiProvider.selectAnswer(currentIndex, optIndex),
                      child: AnimatedContainer(
                        duration: AppTheme.animFast,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: AppTheme.animFast,
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: letterBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  label,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: letterColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                question.options[optIndex],
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: labelColor,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            if (isRevealed && isCorrect)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.success, size: 20),
                            if (isRevealed && isSelected && !isCorrect)
                              const Icon(Icons.cancel_rounded,
                                  color: AppColors.error, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Explanation (after reveal)
                if (isRevealed) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border:
                          Border.all(color: AppColors.info.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded,
                            color: AppColors.info, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            question.explanation,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textPrimary(brightness),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom action bar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: AppTheme.surface(brightness),
            border: Border(top: BorderSide(color: AppTheme.border(brightness))),
          ),
          child: Row(
            children: [
              // Previous button
              if (currentIndex > 0)
                IconButton(
                  onPressed: () {
                    aiProvider.previousQuestion();
                    _pageController.previousPage(
                      duration: AppTheme.animMedium,
                      curve: Curves.easeOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary(brightness),
                    backgroundColor: AppTheme.surfaceAlt(brightness),
                  ),
                ),
              if (currentIndex > 0) const SizedBox(width: 8),

              // Check / Next button
              Expanded(
                child: !isRevealed
                    ? ElevatedButton.icon(
                        onPressed: selectedOption != null
                            ? () => aiProvider.revealAnswer(currentIndex)
                            : null,
                        icon:
                            const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Check Answer'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          disabledBackgroundColor:
                              AppTheme.surfaceAlt(brightness),
                          disabledForegroundColor:
                              AppTheme.textTertiary(brightness),
                        ),
                      )
                    : currentIndex < questions.length - 1
                        ? ElevatedButton.icon(
                            onPressed: () {
                              aiProvider.nextQuestion();
                            },
                            icon: const Icon(Icons.arrow_forward_rounded,
                                size: 18),
                            label: const Text('Next Question'),
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () => aiProvider.completeQuiz(),
                            icon: const Icon(Icons.emoji_events_rounded,
                                size: 18),
                            label: const Text('View Results'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Results Summary ───────────────────────────────────────────────────────

  Widget _buildResultsSummary(
      Brightness brightness, bool isDark, AiProvider aiProvider) {
    final total = aiProvider.quizQuestions.length;
    final score = aiProvider.quizScore;
    final percentage = (score / total * 100).round();
    final isPassing = percentage >= 60;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Score circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isPassing
                    ? [AppColors.success, const Color(0xFF34D399)]
                    : [AppColors.warning, const Color(0xFFFBBF24)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isPassing ? AppColors.success : AppColors.warning)
                      .withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$percentage%',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$score / $total',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            isPassing ? 'Great Job! 🎉' : 'Keep Practicing! 💪',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(brightness),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPassing
                ? 'You have a solid understanding of the material.'
                : 'Review the topics you missed and try again.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textTertiary(brightness),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Stats row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassDecoration(brightness: brightness),
            child: Row(
              children: [
                _buildStatItem(
                  brightness,
                  Icons.check_circle_rounded,
                  AppColors.success,
                  '$score',
                  'Correct',
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: AppTheme.border(brightness),
                ),
                _buildStatItem(
                  brightness,
                  Icons.cancel_rounded,
                  AppColors.error,
                  '${total - score}',
                  'Wrong',
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: AppTheme.border(brightness),
                ),
                _buildStatItem(
                  brightness,
                  Icons.percent_rounded,
                  AppColors.info,
                  '$percentage%',
                  'Score',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Question results list
          ...List.generate(aiProvider.quizQuestions.length, (index) {
            final q = aiProvider.quizQuestions[index];
            final userAnswer = aiProvider.selectedAnswers[index];
            final isCorrect = userAnswer == q.correctIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  aiProvider.goToQuestion(index);
                  aiProvider.restartQuiz();
                  // Re-reveal all already answered
                  for (final key in aiProvider.selectedAnswers.keys) {
                    aiProvider.revealAnswer(key);
                  }
                  aiProvider.goToQuestion(index);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? AppColors.success.withOpacity(0.06)
                        : AppColors.error.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: isCorrect
                          ? AppColors.success.withOpacity(0.25)
                          : AppColors.error.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color:
                              isCorrect ? AppColors.success : AppColors.error,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          q.question,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textPrimary(brightness),
                            height: 1.4,
                          ),
                        ),
                      ),
                      Icon(
                        isCorrect
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color:
                            isCorrect ? AppColors.success : AppColors.error,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    aiProvider.restartQuiz();
                  },
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Review'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    aiProvider.generateQuiz(questionCount: _questionCount);
                  },
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('New Quiz'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(Brightness brightness, IconData icon, Color color,
      String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(brightness),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.textTertiary(brightness),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Raw Markdown Fallback ─────────────────────────────────────────────────

  Widget _buildRawFallback(
      Brightness brightness, bool isDark, AiProvider aiProvider) {
    return Column(
      children: [
        // Warning banner
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing raw output — tap Regenerate for interactive mode',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Markdown(
            data: aiProvider.quizRawFallback,
            padding: const EdgeInsets.all(20),
            styleSheet: MarkdownStyleSheet(
              h1: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(brightness),
              ),
              h2: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(brightness),
              ),
              p: GoogleFonts.inter(
                fontSize: 15,
                color: AppTheme.textPrimary(brightness),
                height: 1.6,
              ),
              strong: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
              listBullet: GoogleFonts.inter(
                color: AppTheme.textPrimary(brightness),
              ),
              horizontalRuleDecoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppTheme.border(brightness),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: AppTheme.surface(brightness),
            border: Border(top: BorderSide(color: AppTheme.border(brightness))),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      aiProvider.generateQuiz(questionCount: _questionCount),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Regenerate'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Error State ───────────────────────────────────────────────────────────

  Widget _buildErrorState(Brightness brightness, AiProvider aiProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              aiProvider.error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.error, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                aiProvider.clearError();
                aiProvider.generateQuiz(questionCount: _questionCount);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _shareQuiz(AiProvider aiProvider) {
    final buffer = StringBuffer();
    buffer.writeln(
        '📝 Quiz: ${aiProvider.selectedSubject?.name ?? "Study Quiz"}');
    buffer.writeln('Score: ${aiProvider.quizScore}/${aiProvider.quizQuestions.length}');
    buffer.writeln('');

    for (int i = 0; i < aiProvider.quizQuestions.length; i++) {
      final q = aiProvider.quizQuestions[i];
      buffer.writeln('Q${i + 1}. ${q.question}');
      for (int j = 0; j < q.options.length; j++) {
        buffer.writeln(
            '${String.fromCharCode(65 + j)}) ${q.options[j]}');
      }
      buffer.writeln(
          'Answer: ${String.fromCharCode(65 + q.correctIndex)}');
      buffer.writeln('');
    }

    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }
}
