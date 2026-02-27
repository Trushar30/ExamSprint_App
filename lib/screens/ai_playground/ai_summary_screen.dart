import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme.dart';
import '../../providers/ai_provider.dart';

class AiSummaryScreen extends StatefulWidget {
  const AiSummaryScreen({super.key});

  @override
  State<AiSummaryScreen> createState() => _AiSummaryScreenState();
}

class _AiSummaryScreenState extends State<AiSummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aiProvider = context.read<AiProvider>();
      if (aiProvider.summaryResult.isEmpty && !aiProvider.isGenerating) {
        aiProvider.generateSummary();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
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
                  colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.summarize_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              'AI Summary',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(brightness),
              ),
            ),
          ],
        ),
        actions: [
          if (aiProvider.summaryResult.isNotEmpty)
            IconButton(
              icon: Icon(Icons.share_rounded,
                  color: AppTheme.textSecondary(brightness)),
              onPressed: () {
                SharePlus.instance.share(
                  ShareParams(text: aiProvider.summaryResult),
                );
              },
            ),
        ],
      ),
      body: _buildBody(brightness, aiProvider),
    );
  }

  Widget _buildBody(Brightness brightness, AiProvider aiProvider) {
    if (aiProvider.isGenerating) {
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
              'Generating summary...',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(brightness),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analyzing your resources',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textTertiary(brightness),
              ),
            ),
          ],
        ),
      );
    }

    if (aiProvider.error != null) {
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
                onPressed: () => aiProvider.generateSummary(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (aiProvider.summaryResult.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Subject badge
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.book_rounded, size: 14, color: AppColors.info),
                const SizedBox(width: 6),
                Text(
                  aiProvider.selectedSubject?.name ?? 'Summary',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Markdown content
        Expanded(
          child: Markdown(
            data: aiProvider.summaryResult,
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
                color: AppColors.accent,
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
        // Bottom bar
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
                  onPressed: () => aiProvider.generateSummary(),
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
}
