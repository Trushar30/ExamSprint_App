import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/theme.dart';
import '../../services/discussion_service.dart';
import '../../config/supabase_config.dart';
import '../../models/discussion.dart';

class DiscussionScreen extends StatefulWidget {
  final String classId;
  const DiscussionScreen({super.key, required this.classId});

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  final DiscussionService _service = DiscussionService();
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  List<Discussion> _messages = [];
  bool _isLoading = true;
  bool _showScrollBtn = false;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(() {
      final show = _scrollCtrl.hasClients &&
          _scrollCtrl.offset <
              _scrollCtrl.position.maxScrollExtent - 200;
      if (show != _showScrollBtn) setState(() => _showScrollBtn = show);
    });
  }

  Future<void> _load() async {
    final messages = await _service.getMessages(widget.classId);
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
    _scrollToBottom();

    _service.subscribeToMessages(widget.classId, (msg) {
      setState(() => _messages.add(msg));
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    _msgCtrl.clear();
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    await _service.sendMessage(
      classId: widget.classId,
      userId: userId,
      message: text,
    );
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final userId = SupabaseConfig.client.auth.currentUser?.id;

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                      ),
                    )
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color: AppTheme.textTertiary(brightness),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No messages yet',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      AppTheme.textSecondary(brightness),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Start the conversation!',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color:
                                      AppTheme.textTertiary(brightness),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final msg = _messages[i];
                            final isMe = msg.userId == userId;
                            final showSender = i == 0 ||
                                _messages[i - 1].userId != msg.userId;

                            return _MessageBubble(
                              message: msg.message,
                              senderName: msg.profile?.fullName ?? 'Unknown',
                              time: timeago.format(msg.createdAt),
                              isMe: isMe,
                              showSender: showSender,
                              brightness: brightness,
                            );
                          },
                        ),
            ),

            // Input bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 24),
              decoration: BoxDecoration(
                color: AppTheme.surface(brightness),
                border: Border(
                  top: BorderSide(
                    color: AppTheme.border(brightness).withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt(brightness),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                        border: Border.all(
                          color: AppTheme.border(brightness),
                        ),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        style: TextStyle(
                          color: AppTheme.textPrimary(brightness),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: AppTheme.textTertiary(brightness),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.glowShadow(),
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Scroll-to-bottom FAB
        if (_showScrollBtn)
          Positioned(
            bottom: 80,
            right: 16,
            child: GestureDetector(
              onTap: _scrollToBottom,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surface(brightness),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.border(brightness),
                  ),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textSecondary(brightness),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final String senderName;
  final String time;
  final bool isMe;
  final bool showSender;
  final Brightness brightness;

  const _MessageBubble({
    required this.message,
    required this.senderName,
    required this.time,
    required this.isMe,
    required this.showSender,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 4,
        top: showSender ? 8 : 0,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showSender && !isMe)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                senderName,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isMe
                  ? AppColors.accent
                  : AppTheme.surfaceAlt(brightness),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              border: isMe
                  ? null
                  : Border.all(
                      color: AppTheme.border(brightness).withValues(alpha: 0.3),
                    ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isMe
                        ? Colors.white
                        : AppTheme.textPrimary(brightness),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.6)
                        : AppTheme.textTertiary(brightness),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
