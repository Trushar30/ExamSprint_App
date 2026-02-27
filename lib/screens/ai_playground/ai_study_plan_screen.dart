import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme.dart';
import '../../providers/ai_provider.dart';

class AiStudyPlanScreen extends StatefulWidget {
  const AiStudyPlanScreen({super.key});

  @override
  State<AiStudyPlanScreen> createState() => _AiStudyPlanScreenState();
}

class _AiStudyPlanScreenState extends State<AiStudyPlanScreen> {
  int _days = 7;
  bool _hasGenerated = false;

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
                  colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.trending_up_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              'Study Plan',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(brightness),
              ),
            ),
          ],
        ),
        actions: [
          if (aiProvider.studyPlanResult.isNotEmpty)
            IconButton(
              icon: Icon(Icons.share_rounded,
                  color: AppTheme.textSecondary(brightness)),
              onPressed: () {
                SharePlus.instance.share(
                  ShareParams(text: aiProvider.studyPlanResult),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Settings (shown before generation or when not generating)
          if (!_hasGenerated && !aiProvider.isGenerating)
            _buildSettings(brightness, isDark, aiProvider),

          // Loading
          if (aiProvider.isGenerating) Expanded(child: _buildLoading(brightness)),

          // Result
          if (aiProvider.studyPlanResult.isNotEmpty && !aiProvider.isGenerating)
            Expanded(child: _buildResult(brightness, isDark, aiProvider)),

          // Error
          if (aiProvider.error != null &&
              !aiProvider.isGenerating &&
              aiProvider.studyPlanResult.isEmpty)
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
                    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.3),
                      blurRadius: 24,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: const Icon(Icons.trending_up_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                'Create Study Plan',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(brightness),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AI will create a personalized study plan\nfor ${aiProvider.selectedSubject?.name ?? "your subject"}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textTertiary(brightness),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Days selector
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassDecoration(brightness: brightness),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Days Available',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary(brightness),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [3, 5, 7, 14, 30].map((count) {
                        final isSelected = _days == count;
                        return GestureDetector(
                          onTap: () => setState(() => _days = count),
                          child: AnimatedContainer(
                            duration: AppTheme.animFast,
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFF59E0B),
                                        Color(0xFFFBBF24)
                                      ],
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : AppTheme.surfaceAlt(brightness),
                              borderRadius: BorderRadius.circular(12),
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
                                  fontSize: 16,
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
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '$_days days',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textTertiary(brightness),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _hasGenerated = true);
                    aiProvider.generateStudyPlan(days: _days);
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate Plan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Creating your study plan...',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary(brightness),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyzing topics and prioritizing',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textTertiary(brightness),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(
      Brightness brightness, bool isDark, AiProvider aiProvider) {
    return Column(
      children: [
        Expanded(
          child: Markdown(
            data: aiProvider.studyPlanResult,
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
              h3: GoogleFonts.spaceGrotesk(
                fontSize: 16,
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
                color: const Color(0xFFF59E0B),
              ),
              em: GoogleFonts.inter(
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondary(brightness),
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
            border: Border(
              top: BorderSide(color: AppTheme.border(brightness)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      aiProvider.generateStudyPlan(days: _days),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    aiProvider.error!,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              aiProvider.clearError();
              setState(() => _hasGenerated = false);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
