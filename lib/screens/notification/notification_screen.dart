import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:ui';
import 'dart:math' as math;
import '../../config/theme.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late AnimationController _fabCtrl;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _fabCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _fabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final notifProvider = context.watch<NotificationProvider>();
    final authProvider = context.watch<AuthProvider>();
    final notifications = notifProvider.notifications;

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.bgGradient(brightness)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // ─── Animated Header ─────────────────────────────────
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _headerCtrl,
                  curve: Curves.easeOutCubic,
                )),
                child: FadeTransition(
                  opacity: _headerCtrl,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        _AnimatedBackButton(
                          onTap: () => Navigator.pop(context),
                          brightness: brightness,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notifications',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary(brightness),
                                ),
                              ),
                              Text(
                                notifProvider.hasUnread
                                    ? '${notifProvider.unreadCount} unread'
                                    : 'All caught up ✨',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: notifProvider.hasUnread
                                      ? AppColors.accent
                                      : AppTheme.textTertiary(brightness),
                                  fontWeight: notifProvider.hasUnread
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (notifications.isNotEmpty)
                          _HeaderAction(
                            icon: Icons.done_all_rounded,
                            tooltip: 'Mark all read',
                            brightness: brightness,
                            onTap: () {
                              final uid = authProvider.userId;
                              if (uid != null) {
                                notifProvider.markAllAsRead(uid);
                              }
                            },
                          ),
                        const SizedBox(width: 8),
                        if (notifications.isNotEmpty)
                          _HeaderAction(
                            icon: Icons.delete_sweep_rounded,
                            tooltip: 'Clear all',
                            brightness: brightness,
                            isDestructive: true,
                            onTap: () => _showClearDialog(context),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Notification List ──────────────────────────────
              Expanded(
                child: notifProvider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      )
                    : notifications.isEmpty
                        ? _EmptyState(brightness: brightness)
                        : RefreshIndicator(
                            onRefresh: () async {
                              final uid = authProvider.userId;
                              if (uid != null) {
                                await notifProvider.loadNotifications(uid);
                              }
                            },
                            color: AppColors.accent,
                            child: AnimationLimiter(
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 100),
                                itemCount: notifications.length,
                                itemBuilder: (context, index) {
                                  final notif = notifications[index];
                                  return AnimationConfiguration.staggeredList(
                                    position: index,
                                    duration:
                                        const Duration(milliseconds: 400),
                                    child: SlideAnimation(
                                      verticalOffset: 60,
                                      child: FadeInAnimation(
                                        child: _NotificationCard(
                                          notification: notif,
                                          brightness: brightness,
                                          onTap: () {
                                            if (!notif.isRead) {
                                              notifProvider
                                                  .markAsRead(notif.id);
                                            }
                                          },
                                          onDismissed: () {
                                            notifProvider
                                                .deleteNotification(notif.id);
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(brightness),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          'Clear All Notifications?',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary(brightness),
          ),
        ),
        content: Text(
          'This will permanently remove all your notifications.',
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary(brightness),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textTertiary(brightness)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final uid = context.read<AuthProvider>().userId;
              if (uid != null) {
                context.read<NotificationProvider>().clearAll(uid);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Animated Back Button
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedBackButton extends StatefulWidget {
  final VoidCallback onTap;
  final Brightness brightness;

  const _AnimatedBackButton({
    required this.onTap,
    required this.brightness,
  });

  @override
  State<_AnimatedBackButton> createState() => _AnimatedBackButtonState();
}

class _AnimatedBackButtonState extends State<_AnimatedBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.9).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
        ),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.surfaceAlt(widget.brightness),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.border(widget.brightness).withOpacity(0.5),
            ),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppTheme.textPrimary(widget.brightness),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Header Action Button
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderAction extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Brightness brightness;
  final VoidCallback onTap;
  final bool isDestructive;

  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.brightness,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_HeaderAction> createState() => _HeaderActionState();
}

class _HeaderActionState extends State<_HeaderAction>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isDestructive ? AppColors.error : AppColors.accent;
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.85).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
          ),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Notification Card — Glassmorphism + swipe-to-dismiss
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationCard extends StatefulWidget {
  final NotificationModel notification;
  final Brightness brightness;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _NotificationCard({
    required this.notification,
    required this.brightness,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Color _typeColor() {
    switch (widget.notification.type) {
      case NotificationType.resourceAdded:
        return AppColors.info;
      case NotificationType.announcement:
        return AppColors.warning;
      case NotificationType.memberJoined:
        return AppColors.success;
      case NotificationType.discussionReply:
        return const Color(0xFF8B5CF6);
    }
  }

  List<Color> _typeGradient() {
    switch (widget.notification.type) {
      case NotificationType.resourceAdded:
        return [const Color(0xFF3B82F6), const Color(0xFF60A5FA)];
      case NotificationType.announcement:
        return [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
      case NotificationType.memberJoined:
        return [const Color(0xFF10B981), const Color(0xFF34D399)];
      case NotificationType.discussionReply:
        return [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)];
    }
  }

  IconData _typeIcon() {
    switch (widget.notification.type) {
      case NotificationType.resourceAdded:
        return Icons.upload_file_rounded;
      case NotificationType.announcement:
        return Icons.campaign_rounded;
      case NotificationType.memberJoined:
        return Icons.person_add_alt_1_rounded;
      case NotificationType.discussionReply:
        return Icons.chat_bubble_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final isUnread = !n.isRead;
    final typeColor = _typeColor();
    final gradient = _typeGradient();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(n.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => widget.onDismissed(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.error.withOpacity(0.0),
                AppColors.error.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 26),
              SizedBox(height: 4),
              Text(
                'Delete',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        child: GestureDetector(
          onTapDown: (_) => _pressCtrl.forward(),
          onTapUp: (_) {
            _pressCtrl.reverse();
            widget.onTap();
          },
          onTapCancel: () => _pressCtrl.reverse(),
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 0.97).animate(
              CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.brightness == Brightness.dark
                        ? AppColors.darkCard
                        : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                      color: isUnread
                          ? typeColor.withOpacity(0.4)
                          : AppTheme.border(widget.brightness).withOpacity(0.3),
                      width: isUnread ? 1.5 : 1,
                    ),
                    boxShadow: isUnread
                        ? [
                            BoxShadow(
                              color: typeColor.withOpacity(0.1),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Type Icon with gradient ──
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: gradient.first.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _typeIcon(),
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // ── Content ──
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 15,
                                      fontWeight: isUnread
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: AppTheme.textPrimary(
                                          widget.brightness),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Unread dot
                                if (isUnread) ...[
                                  const SizedBox(width: 8),
                                  _PulsingDot(color: typeColor),
                                ],
                              ],
                            ),
                            if (n.body.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                n.body,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color:
                                      AppTheme.textSecondary(widget.brightness),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Type label pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: typeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    n.typeLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: typeColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: AppTheme.textTertiary(
                                      widget.brightness),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  timeago.format(n.createdAt),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppTheme.textTertiary(
                                        widget.brightness),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Pulsing Unread Dot
// ─────────────────────────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder2(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3 + 0.3 * _ctrl.value),
                blurRadius: 6 + 4 * _ctrl.value,
                spreadRadius: 1 + 1 * _ctrl.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatefulWidget {
  final Brightness brightness;
  const _EmptyState({required this.brightness});

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder2(
        animation: _ctrl,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -6 * math.sin(_ctrl.value * math.pi)),
            child: child,
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.12),
                    AppColors.accentLight.withOpacity(0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 44,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Notifications',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary(widget.brightness),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up! 🎉\nNew activity will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textTertiary(widget.brightness),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AnimatedBuilder2 — local helper to avoid conflict with main_shell.dart's
// ─────────────────────────────────────────────────────────────────────────────

class AnimatedBuilder2 extends StatelessWidget {
  final Listenable animation;
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder2({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _AnimShell(listenable: animation, builder: builder, child: child);
  }
}

class _AnimShell extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const _AnimShell({
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) => builder(context, child);
}
