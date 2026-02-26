import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../config/theme.dart';

class AiPlaygroundScreen extends StatefulWidget {
  const AiPlaygroundScreen({super.key});

  @override
  State<AiPlaygroundScreen> createState() => _AiPlaygroundScreenState();
}

class _AiPlaygroundScreenState extends State<AiPlaygroundScreen>
    with TickerProviderStateMixin {
  late AnimationController _orbitCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _orbitCtrl = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    _pulseCtrl = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _glowCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.bgGradient(brightness)),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppTheme.glowShadow(),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Playground',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary(brightness),
                        ),
                      ),
                      Text(
                        'Your intelligent study companion',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textTertiary(brightness),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main content — animated illustration
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: AnimatedBuilder(
                        animation: _orbitCtrl,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _OrbitPainter(
                              progress: _orbitCtrl.value,
                              pulseValue: _pulseCtrl.value,
                              accent: AppColors.accent,
                              accentLight: AppColors.accentLight,
                              isDark: isDark,
                            ),
                            child: child,
                          );
                        },
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (context, child) {
                              final scale = 1.0 + 0.08 * _pulseCtrl.value;
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: AnimatedBuilder(
                              animation: _glowCtrl,
                              builder: (context, child) {
                                return Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accent.withOpacity(
                                          0.3 + 0.2 * _glowCtrl.value,
                                        ),
                                        blurRadius: 30 + 15 * _glowCtrl.value,
                                        spreadRadius: -2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.psychology_rounded,
                                    size: 44,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'Coming Soon',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(brightness),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        'AI-powered quizzes, smart summaries,\nand personalized study plans',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textTertiary(brightness),
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Feature chips
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _FeatureChip(
                          icon: Icons.quiz_rounded,
                          label: 'Smart Quizzes',
                          brightness: brightness,
                        ),
                        _FeatureChip(
                          icon: Icons.summarize_rounded,
                          label: 'AI Summaries',
                          brightness: brightness,
                        ),
                        _FeatureChip(
                          icon: Icons.trending_up_rounded,
                          label: 'Study Plans',
                          brightness: brightness,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Brightness brightness;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accentMuted,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints orbiting dots around the center icon
class _OrbitPainter extends CustomPainter {
  final double progress;
  final double pulseValue;
  final Color accent;
  final Color accentLight;
  final bool isDark;

  _OrbitPainter({
    required this.progress,
    required this.pulseValue,
    required this.accent,
    required this.accentLight,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Draw orbit ring
    final ringPaint = Paint()
      ..color = accent.withOpacity(0.1 + 0.05 * pulseValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, ringPaint);

    // Draw orbiting dots
    const dotCount = 6;
    for (int i = 0; i < dotCount; i++) {
      final angle = (progress * 2 * math.pi) + (i * 2 * math.pi / dotCount);
      final dotRadius = 3.0 + 2.0 * ((i % 3) / 2);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      final dotPaint = Paint()
        ..color = i.isEven
            ? accent.withOpacity(0.6 + 0.3 * pulseValue)
            : accentLight.withOpacity(0.5 + 0.3 * pulseValue);
      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
    }

    // Inner ring
    final innerRingPaint = Paint()
      ..color = accent.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius * 0.6, innerRingPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      progress != oldDelegate.progress || pulseValue != oldDelegate.pulseValue;
}

// Reusable animated builder
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _AnimBuilderShell(
      listenable: animation,
      builder: builder,
      child: child,
    );
  }
}

class _AnimBuilderShell extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const _AnimBuilderShell({
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) => builder(context, child);
}
