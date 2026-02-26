import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/discussion_service.dart';
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

  @override
  void initState() { super.initState(); _loadMessages(); _subscribe(); }

  Future<void> _loadMessages() async {
    _messages = await _service.getMessages(widget.classId);
    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  void _subscribe() {
    _service.subscribeToMessages(widget.classId, (msg) {
      if (!_messages.any((m) => m.id == msg.id)) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    final userId = context.read<AuthProvider>().userId!;
    final msg = await _service.sendMessage(classId: widget.classId, userId: userId, message: text);
    if (!_messages.any((m) => m.id == msg.id)) setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  @override
  void dispose() { _service.dispose(); _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().userId;

    return Column(children: [
      Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
        : _messages.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppTheme.textTertiary), const SizedBox(height: 12), Text('No messages yet', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)), const SizedBox(height: 4), Text('Start the discussion!', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textTertiary))]))
        : ListView.builder(controller: _scrollCtrl, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), itemCount: _messages.length, itemBuilder: (context, i) {
          final msg = _messages[i];
          final isMe = msg.userId == userId;
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) Padding(padding: const EdgeInsets.only(right: 8), child: Container(width: 32, height: 32, decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(8)), child: Center(child: Text(msg.profile?.initials ?? '?', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))))),
              Flexible(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? AppTheme.accent.withOpacity(0.2) : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16)),
                  border: Border.all(color: isMe ? AppTheme.accent.withOpacity(0.3) : AppTheme.border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (!isMe) Text(msg.profile?.fullName ?? 'Unknown', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.accent)),
                  Text(msg.message, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(timeago.format(msg.createdAt), style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textTertiary)),
                ]),
              )),
            ],
          ));
        }),
      ),
      // Input
      Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(color: AppTheme.surface, border: Border(top: BorderSide(color: AppTheme.border))),
        child: Row(children: [
          Expanded(child: TextField(controller: _msgCtrl, style: const TextStyle(color: AppTheme.textPrimary), decoration: InputDecoration(hintText: 'Type a message...', hintStyle: const TextStyle(color: AppTheme.textTertiary), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppTheme.border)), filled: true, fillColor: AppTheme.surfaceLight, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)), onSubmitted: (_) => _sendMessage())),
          const SizedBox(width: 8),
          Container(decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(24)), child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: _sendMessage)),
        ]),
      ),
    ]);
  }
}
