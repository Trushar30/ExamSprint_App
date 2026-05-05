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
  // Local filter state for summary
  Set<String> _selectedResourceIds = {};
  String _topicFocus = '';
  bool _hasGenerated = false;

  void _generate(AiProvider aiProvider) {
    setState(() => _hasGenerated = true);
    aiProvider.generateSummary(
      topicFocus: _topicFocus.isNotEmpty ? _topicFocus : null,
      selectedResourceIds:
          _selectedResourceIds.isNotEmpty ? _selectedResourceIds : null,
    );
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
    // Show settings before first generation
    if (!_hasGenerated && !aiProvider.isGenerating) {
      return _buildSettings(brightness, aiProvider);
    }

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

    if (aiProvider.error != null && aiProvider.summaryResult.isEmpty) {
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
                  setState(() => _hasGenerated = false);
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (aiProvider.summaryResult.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildResult(brightness, aiProvider);
  }

  // ─── Settings / Filters Screen ────────────────────────────────────────────

  Widget _buildSettings(Brightness brightness, AiProvider aiProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 24,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.summarize_rounded,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  'Configure Summary',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(brightness),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose what to summarize from ${aiProvider.selectedSubject?.name ?? "your subject"}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textTertiary(brightness),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 1. Chapter / Resource Selection ──
          _buildSectionLabel(
              brightness, Icons.menu_book_rounded, 'CHAPTERS / RESOURCES'),
          const SizedBox(height: 8),
          _buildResourcePicker(brightness, aiProvider),
          const SizedBox(height: 20),

          // ── 2. Topic Focus ──
          _buildSectionLabel(
              brightness, Icons.center_focus_strong_rounded, 'TOPIC FOCUS'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: AppTheme.glassDecoration(brightness: brightness),
            child: TextField(
              onChanged: (val) => setState(() => _topicFocus = val),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textPrimary(brightness),
              ),
              decoration: InputDecoration(
                hintText: 'e.g. "Linked Lists", "Normalization"...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textTertiary(brightness),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
                prefixIcon: Icon(Icons.search_rounded,
                    size: 18, color: AppTheme.textTertiary(brightness)),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 32, minHeight: 0),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Leave empty to cover all topics',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.textTertiary(brightness),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Active Filters Summary ──
          if (_topicFocus.isNotEmpty || _selectedResourceIds.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppColors.info.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded,
                      size: 16, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildFilterSummary(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.info,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Generate Button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _generate(aiProvider),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Summary'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Resource Picker (shared pattern) ─────────────────────────────────────

  Widget _buildResourcePicker(Brightness brightness, AiProvider aiProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.glassDecoration(brightness: brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list_rounded,
                  size: 14, color: AppTheme.textTertiary(brightness)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _selectedResourceIds.isEmpty
                      ? 'All resources (no filter)'
                      : '${_selectedResourceIds.length} of ${aiProvider.availableResources.length} selected',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _selectedResourceIds.isEmpty
                        ? AppTheme.textTertiary(brightness)
                        : AppColors.accent,
                  ),
                ),
              ),
              if (aiProvider.availableResources.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedResourceIds.length ==
                          aiProvider.availableResources.length) {
                        _selectedResourceIds = {};
                      } else {
                        _selectedResourceIds = aiProvider.availableResources
                            .map((r) => r['id']!)
                            .toSet();
                      }
                    });
                  },
                  child: Text(
                    _selectedResourceIds.length ==
                            aiProvider.availableResources.length
                        ? 'Clear All'
                        : 'Select All',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),
          if (aiProvider.isLoadingResources) ...[
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
            ),
          ] else if (aiProvider.availableResources.isEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'No resources found in this subject',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textTertiary(brightness),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            ...aiProvider.availableResources.map((resource) {
              final isSelected =
                  _selectedResourceIds.contains(resource['id']);
              final fileType = resource['file_type'] ?? '';
              final typeEmoji = _getFileTypeEmoji(fileType);

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedResourceIds.remove(resource['id']);
                      } else {
                        _selectedResourceIds.add(resource['id']!);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: AppTheme.animFast,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withOpacity(0.08)
                          : AppTheme.surfaceAlt(brightness),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent.withOpacity(0.4)
                            : AppTheme.border(brightness).withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: AppTheme.animFast,
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppTheme.textTertiary(brightness),
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(typeEmoji,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            resource['title'] ?? 'Untitled',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? AppTheme.textPrimary(brightness)
                                  : AppTheme.textSecondary(brightness),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ─── Result View ──────────────────────────────────────────────────────────

  Widget _buildResult(Brightness brightness, AiProvider aiProvider) {
    return Column(
      children: [
        // Subject + filter badge
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
                if (_selectedResourceIds.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_selectedResourceIds.length} ch.',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
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
                  onPressed: () => _generate(aiProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Regenerate'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _hasGenerated = false);
                },
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Filters'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(
      Brightness brightness, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.accent),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppTheme.textTertiary(brightness),
          ),
        ),
      ],
    );
  }

  String _getFileTypeEmoji(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'ppt':
      case 'pptx':
        return '📊';
      case 'txt':
      case 'md':
        return '📃';
      default:
        return '📎';
    }
  }

  String _buildFilterSummary() {
    final parts = <String>[];
    if (_selectedResourceIds.isNotEmpty) {
      parts.add('${_selectedResourceIds.length} chapter(s) selected');
    }
    if (_topicFocus.isNotEmpty) {
      parts.add('Topic: "$_topicFocus"');
    }
    return 'Filters: ${parts.join(' • ')}';
  }
}
