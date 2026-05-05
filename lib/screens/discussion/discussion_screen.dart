import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
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

class _DiscussionScreenState extends State<DiscussionScreen>
    with TickerProviderStateMixin {
  final DiscussionService _service = DiscussionService();
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  List<Discussion> _messages = [];
  bool _isLoading = true;
  bool _showScrollBtn = false;
  
  Discussion? _replyingTo;
  bool _isTyping = false; // Simulated typing indicator

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(() {
      final show = _scrollCtrl.hasClients &&
          _scrollCtrl.offset < _scrollCtrl.position.maxScrollExtent - 200;
      if (show != _showScrollBtn) setState(() => _showScrollBtn = show);
    });
  }

  Future<void> _load() async {
    final messages = await _service.getMessages(widget.classId);
    if (mounted) {
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    }

    _service.subscribeToMessages(widget.classId, (msg) {
      if (mounted) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 100, // overshoot for new message
          duration: const Duration(milliseconds: 400),
          curve: AppTheme.springCurve,
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

    // Optional: prepend quote if replying
    final finalMessage = _replyingTo != null
        ? '> Replying to ${_replyingTo!.profile?.fullName ?? 'Someone'}:\n> ${_replyingTo!.message}\n\n$text'
        : text;

    setState(() => _replyingTo = null);

    // Simulate typing indicator briefly before sending to network
    setState(() => _isTyping = true);
    _scrollToBottom();
    
    await _service.sendMessage(
      classId: widget.classId,
      userId: userId,
      message: finalMessage,
    );
    
    setState(() => _isTyping = false);
  }

  void _handleReply(Discussion msg) {
    setState(() => _replyingTo = msg);
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
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
                      child: CircularProgressIndicator(color: AppColors.accent))
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceAlt(brightness),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 32,
                                  color: AppTheme.textTertiary(brightness),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary(brightness),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start the conversation!',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppTheme.textTertiary(brightness),
                                ),
                              ),
                            ],
                          ),
                        )
                      : AnimationLimiter(
                          child: ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            itemCount: _messages.length + (_isTyping ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i == _messages.length) {
                                return const _TypingIndicator();
                              }

                              final msg = _messages[i];
                              final isMe = msg.userId == userId;
                              final showSender = i == 0 ||
                                  _messages[i - 1].userId != msg.userId;

                              // Check if day changed for date separator
                              final prevMsg = i > 0 ? _messages[i - 1] : null;
                              final showDate = prevMsg == null ||
                                  !DateUtils.isSameDay(
                                      msg.createdAt, prevMsg.createdAt);

                              return AnimationConfiguration.staggeredList(
                                position: i,
                                duration: const Duration(milliseconds: 300),
                                child: SlideAnimation(
                                  verticalOffset: 20,
                                  child: FadeInAnimation(
                                    child: Column(
                                      children: [
                                        if (showDate)
                                          _DateSeparator(
                                              date: msg.createdAt,
                                              brightness: brightness),
                                        GestureDetector(
                                          onLongPress: () => _handleReply(msg),
                                          child: _MessageBubble(
                                            message: msg.message,
                                            senderName: msg.profile?.fullName ??
                                                'Unknown',
                                            time: timeago.format(msg.createdAt),
                                            isMe: isMe,
                                            showSender: showSender,
                                            brightness: brightness,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),

            // Input bar
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyingTo != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: AppTheme.surfaceAlt(brightness),
                    child: Row(
                      children: [
                        Icon(Icons.reply_rounded,
                            size: 16, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Replying to ${_replyingTo!.profile?.fullName ?? 'Unknown'}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary(brightness),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _replyingTo = null),
                          child: Icon(Icons.close_rounded,
                              size: 16, color: AppTheme.textTertiary(brightness)),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface(brightness),
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.border(brightness).withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceAlt(brightness),
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                            border: Border.all(
                              color: AppTheme.border(brightness),
                            ),
                          ),
                          child: TextField(
                            controller: _msgCtrl,
                            focusNode: _focusNode,
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
          ],
        ),

        // Scroll-to-bottom FAB
        if (_showScrollBtn)
          Positioned(
            bottom: 100, // adjusted for new input bar height
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
                  boxShadow: AppTheme.glowShadow(),
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

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  final Brightness brightness;

  const _DateSeparator({required this.date, required this.brightness});

  @override
  Widget build(BuildContext context) {
    String label;
    if (DateUtils.isSameDay(date, DateTime.now())) {
      label = 'Today';
    } else if (DateUtils.isSameDay(
        date, DateTime.now().subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      label = DateFormat.yMMMd().format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceAlt(brightness),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textTertiary(brightness),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt(brightness),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, child) {
                    final t = (_ctrl.value * 3 - i) % 3;
                    final offset =
                        t >= 0 && t <= 1 ? -4 * Math.sin(t * Math.pi) : 0.0;
                    return Transform.translate(
                      offset: Offset(0, offset),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.textTertiary(brightness),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class Math {
  static double sin(double radians) {
    return math.sin(radians);
  }

  static const double pi = 3.1415926535897932;
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
    // Basic quote parsing
    final isReply = message.startsWith('> Replying to');
    String displayMessage = message;
    String? quoteText;

    if (isReply) {
      final parts = message.split('\n\n');
      if (parts.length > 1) {
        quoteText = parts[0].replaceAll('> ', '');
        displayMessage = parts.sublist(1).join('\n\n');
      }
    }

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
              maxWidth: MediaQuery.of(context).size.width * 0.75,
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
                      color: AppTheme.border(brightness).withOpacity(0.3),
                    ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (quoteText != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.white.withOpacity(0.15) : AppTheme.surface(brightness).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: isMe ? Colors.white : AppColors.accent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      quoteText,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isMe ? Colors.white.withOpacity(0.8) : AppTheme.textSecondary(brightness),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Text(
                  displayMessage,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isMe ? Colors.white : AppTheme.textPrimary(brightness),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
                              : AppTheme.textTertiary(brightness),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all_rounded,
                          size: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
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
