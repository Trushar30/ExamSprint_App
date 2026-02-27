import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:ui';
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

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
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
              child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 16),
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
      ),
      body: Column(
        children: [
          // Quiz settings
          if (aiProvider.quizResult.isEmpty && !aiProvider.isGenerating)
            _buildSettings(brightness, isDark, aiProvider),

          // Loading indicator
          if (aiProvider.isGenerating)
            Expanded(child: _buildLoadingState(brightness)),

          // Quiz result
          if (aiProvider.quizResult.isNotEmpty && !aiProvider.isGenerating)
            Expanded(child: _buildQuizResult(brightness, isDark, aiProvider)),

          // Error
          if (aiProvider.error != null && !aiProvider.isGenerating)
            _buildError(brightness, aiProvider),
        ],
      ),
    );
  }

  Widget _buildSettings(
      Brightness brightness, bool isDark, AiProvider aiProvider) {
    return Expanded(
      child: Center(
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
                          onTap: () =>
                              setState(() => _questionCount = count),
                          child: AnimatedContainer(
                            duration: AppTheme.animFast,
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? AppTheme.primaryGradient
                                  : null,
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
      ),
    );
  }

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

  Widget _buildQuizResult(
      Brightness brightness, bool isDark, AiProvider aiProvider) {
    return Column(
      children: [
        Expanded(
          child: Markdown(
            data: aiProvider.quizResult,
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
        // Bottom action bar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: AppTheme.surface(brightness),
            border: Border(
              top: BorderSide(color: AppTheme.border(brightness)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    aiProvider.generateQuiz(questionCount: _questionCount);
                  },
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

  Widget _buildError(Brightness brightness, AiProvider aiProvider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                aiProvider.error!,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
