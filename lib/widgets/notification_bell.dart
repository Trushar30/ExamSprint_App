import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../config/theme.dart';
import '../providers/notification_provider.dart';
import '../screens/notification/notification_screen.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with TickerProviderStateMixin {
  late AnimationController _shakeCtrl;
  late AnimationController _badgeCtrl;
  late AnimationController _pressCtrl;
  int _prevUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _badgeCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _badgeCtrl.dispose();
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final count = context.read<NotificationProvider>().unreadCount;
    if (count > _prevUnreadCount && _prevUnreadCount >= 0) {
      // New notification arrived — trigger shake + badge bounce
      _shakeCtrl.forward(from: 0);
      _badgeCtrl.forward(from: 0);
    }
    _prevUnreadCount = count;
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final brightness = Theme.of(context).brightness;
    final hasUnread = notifProvider.hasUnread;
    final count = notifProvider.unreadCount;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const NotificationScreen(),
            transitionsBuilder: (_, anim, __, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: anim,
                  curve: Curves.easeOutCubic,
                )),
                child: FadeTransition(
                  opacity: anim,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.88).animate(
          CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Bell Icon ──
            AnimatedBuilder3(
              animation: _shakeCtrl,
              builder: (context, child) {
                final shakeValue = math.sin(_shakeCtrl.value * math.pi * 4) *
                    (1 - _shakeCtrl.value);
                return Transform.rotate(
                  angle: shakeValue * 0.15,
                  child: child,
                );
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: hasUnread
                      ? AppColors.accent.withOpacity(0.12)
                      : AppTheme.surfaceAlt(brightness),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasUnread
                        ? AppColors.accent.withOpacity(0.3)
                        : AppTheme.border(brightness).withOpacity(0.5),
                  ),
                  boxShadow: hasUnread
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.15),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  hasUnread
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_outlined,
                  size: 22,
                  color: hasUnread
                      ? AppColors.accent
                      : AppTheme.textSecondary(brightness),
                ),
              ),
            ),

            // ── Badge ──
            if (hasUnread)
              Positioned(
                top: -4,
                right: -4,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _badgeCtrl,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    constraints: const BoxConstraints(minWidth: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.accentLight],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AnimatedBuilder3 — local helper to avoid conflict
// ─────────────────────────────────────────────────────────────────────────────

class AnimatedBuilder3 extends StatelessWidget {
  final Listenable animation;
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder3({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _AnimHelper(listenable: animation, builder: builder, child: child);
  }
}

class _AnimHelper extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const _AnimHelper({
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) => builder(context, child);
}
