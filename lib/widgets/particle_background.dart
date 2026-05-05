import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../config/theme.dart';

class ParticleBackground extends StatefulWidget {
  final Brightness brightness;
  final Widget child;

  const ParticleBackground({
    super.key,
    required this.brightness,
    required this.child,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<_Particle> _particles = [];
  final math.Random _rnd = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Initialize particles
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        x: _rnd.nextDouble(),
        y: _rnd.nextDouble(),
        speedX: (_rnd.nextDouble() - 0.5) * 0.2,
        speedY: (_rnd.nextDouble() - 0.5) * 0.2,
        size: _rnd.nextDouble() * 3 + 1,
      ));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        for (var p in _particles) {
          p.x += p.speedX * 0.01;
          p.y += p.speedY * 0.01;
          if (p.x < 0) p.x = 1.0;
          if (p.x > 1) p.x = 0.0;
          if (p.y < 0) p.y = 1.0;
          if (p.y > 1) p.y = 0.0;
        }

        final angle = _ctrl.value * 2 * math.pi;
        final isDark = widget.brightness == Brightness.dark;

        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.accent.withValues(alpha: 0.1),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(
                  math.cos(angle) * 0.3,
                  math.sin(angle) * 0.3,
                ),
                radius: 1.5,
                colors: isDark
                    ? [
                        const Color(0xFF1A0A2E).withValues(alpha: 0.8),
                        const Color(0xFF0B0B14).withValues(alpha: 0.8),
                        const Color(0xFF0A0A12).withValues(alpha: 0.8),
                      ]
                    : [
                        const Color(0xFFEDE7F6).withValues(alpha: 0.8),
                        const Color(0xFFF7F7FC).withValues(alpha: 0.8),
                        const Color(0xFFF0F0F8).withValues(alpha: 0.8),
                      ],
              ),
            ),
            child: widget.child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _Particle {
  double x, y;
  double speedX, speedY;
  double size;

  _Particle({
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.size,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;

  _ParticlePainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var p in particles) {
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
