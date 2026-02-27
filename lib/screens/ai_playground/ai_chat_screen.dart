import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:ui';
import '../../config/theme.dart';
import '../../providers/ai_provider.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(AiProvider aiProvider) {
    final text = _controller.text.trim();
    if (text.isEmpty || aiProvider.isGenerating) return;

    _controller.clear();
    aiProvider.askQuestion(text);

    // Scroll to bottom after message is added
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chat_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q&A Chat',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(brightness),
                    ),
                  ),
                  Text(
                    aiProvider.selectedSubject?.name ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textTertiary(brightness),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (aiProvider.chatHistory.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  color: AppTheme.textSecondary(brightness)),
              onPressed: () => aiProvider.clearChat(),
              tooltip: 'Clear chat',
            ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: aiProvider.chatHistory.isEmpty
                ? _buildEmptyChat(brightness)
                : _buildChatMessages(brightness, isDark, aiProvider),
          ),

          // Input field
          _buildInputField(brightness, isDark, aiProvider),
        ],
      ),
    );
  }

  Widget _buildEmptyChat(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: const Icon(Icons.chat_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 24),
          Text(
            'Ask anything!',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(brightness),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'I\'ll answer questions based on your study resources',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textTertiary(brightness),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Suggestion chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _SuggestionChip(
                text: 'Explain the key concepts',
                onTap: () {
                  _controller.text = 'Explain the key concepts in this subject';
                  _sendMessage(context.read<AiProvider>());
                },
                brightness: brightness,
              ),
              _SuggestionChip(
                text: 'What are the important topics?',
                onTap: () {
                  _controller.text = 'What are the most important topics for the exam?';
                  _sendMessage(context.read<AiProvider>());
                },
                brightness: brightness,
              ),
              _SuggestionChip(
                text: 'Give me a quick revision',
                onTap: () {
                  _controller.text = 'Give me a quick revision of all topics';
                  _sendMessage(context.read<AiProvider>());
                },
                brightness: brightness,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages(
      Brightness brightness, bool isDark, AiProvider aiProvider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: aiProvider.chatHistory.length + (aiProvider.isGenerating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= aiProvider.chatHistory.length) {
          // Typing indicator
          return _buildTypingIndicator(brightness, isDark);
        }

        final msg = aiProvider.chatHistory[index];
        final isUser = msg['role'] == 'user';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF34D399)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.accent
                        : isDark
                            ? AppColors.darkSurfaceAlt
                            : AppColors.lightSurfaceAlt,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: AppTheme.border(brightness).withOpacity(0.5),
                          ),
                  ),
                  child: isUser
                      ? Text(
                          msg['content'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        )
                      : MarkdownBody(
                          data: msg['content'] ?? '',
                          styleSheet: MarkdownStyleSheet(
                            p: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textPrimary(brightness),
                              height: 1.5,
                            ),
                            strong: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                            code: GoogleFonts.robotoMono(
                              fontSize: 13,
                              color: AppColors.accent,
                              backgroundColor: AppColors.accentMuted,
                            ),
                            listBullet: GoogleFonts.inter(
                              color: AppTheme.textPrimary(brightness),
                            ),
                          ),
                        ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.person_rounded,
                      color: AppColors.accent, size: 18),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator(Brightness brightness, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceAlt
                  : AppColors.lightSurfaceAlt,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                color: AppTheme.border(brightness).withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Thinking...',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textTertiary(brightness),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
      Brightness brightness, bool isDark, AiProvider aiProvider) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppTheme.surface(brightness),
        border: Border(
          top: BorderSide(color: AppTheme.border(brightness)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppTheme.textPrimary(brightness),
              ),
              decoration: InputDecoration(
                hintText: 'Ask about your resources...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppTheme.textTertiary(brightness),
                ),
                filled: true,
                fillColor: AppTheme.surfaceAlt(brightness),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  borderSide: BorderSide(
                    color: AppTheme.border(brightness),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  borderSide: const BorderSide(
                    color: AppColors.accent,
                    width: 1.5,
                  ),
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(aiProvider),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(aiProvider),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: aiProvider.isGenerating
                    ? null
                    : AppTheme.primaryGradient,
                color: aiProvider.isGenerating
                    ? AppTheme.surfaceAlt(brightness)
                    : null,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                color: aiProvider.isGenerating
                    ? AppTheme.textTertiary(brightness)
                    : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Brightness brightness;

  const _SuggestionChip({
    required this.text,
    required this.onTap,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accentMuted,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}
