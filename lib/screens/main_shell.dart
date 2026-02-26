import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../config/theme.dart';
import 'home/home_screen.dart';
import 'explore/explore_screen.dart';
import 'ai_playground/ai_playground_screen.dart';
import 'profile/profile_screen.dart';
import 'class/create_class_screen.dart';
import 'class/join_class_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _navSlideCtrl;
  late AnimationController _fabPulseCtrl;
  late AnimationController _fabRotateCtrl;
  late AnimationController _indicatorCtrl;

  final _screens = const [
    HomeScreen(),
    ExploreScreen(),
    AiPlaygroundScreen(),
    ProfileScreen(),
  ];

  static const _navItems = [
    _NavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
    _NavItem(Icons.school_rounded, Icons.school_outlined, 'Classes'),
    _NavItem(Icons.auto_awesome, Icons.auto_awesome_outlined, 'AI'),
    _NavItem(Icons.person_rounded, Icons.person_outlined, 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _navSlideCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _fabPulseCtrl = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fabRotateCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _indicatorCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navSlideCtrl.dispose();
    _fabPulseCtrl.dispose();
    _fabRotateCtrl.dispose();
    _indicatorCtrl.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );

    _indicatorCtrl.forward(from: 0);
  }

  void _onFabPressed() {
    // Rotate animation
    _fabRotateCtrl.forward(from: 0);

    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _QuickActionsSheet(isDark: isDark, brightness: brightness),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      extendBody: true,
      bottomNavigationBar: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _navSlideCtrl,
          curve: Curves.easeOutBack,
        )),
        child: SizedBox(
          height: 100,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // ── Nav Bar Body ──
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: ClipPath(
                  clipper: _NavBarClipper(),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface.withOpacity(0.92)
                            : AppColors.lightSurface.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        border: Border.all(
                          color: AppTheme.border(brightness).withOpacity(0.4),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                          if (isDark)
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.06),
                              blurRadius: 40,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Left side: Home, Classes
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _NavButton(
                                  item: _navItems[0],
                                  isActive: _currentIndex == 0,
                                  onTap: () => _onTabTapped(0),
                                  brightness: brightness,
                                ),
                                _NavButton(
                                  item: _navItems[1],
                                  isActive: _currentIndex == 1,
                                  onTap: () => _onTabTapped(1),
                                  brightness: brightness,
                                ),
                              ],
                            ),
                          ),
                          // Center gap for FAB
                          const SizedBox(width: 72),
                          // Right side: AI, Profile
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _NavButton(
                                  item: _navItems[2],
                                  isActive: _currentIndex == 2,
                                  onTap: () => _onTabTapped(2),
                                  brightness: brightness,
                                ),
                                _NavButton(
                                  item: _navItems[3],
                                  isActive: _currentIndex == 3,
                                  onTap: () => _onTabTapped(3),
                                  brightness: brightness,
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

              // ── Floating Center "+" Button ──
              Positioned(
                bottom: 40,
                child: AnimatedBuilder(
                  animation: _fabPulseCtrl,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(
                              0.25 + 0.2 * _fabPulseCtrl.value,
                            ),
                            blurRadius: 20 + 12 * _fabPulseCtrl.value,
                            spreadRadius: 1 + 3 * _fabPulseCtrl.value,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: GestureDetector(
                    onTap: _onFabPressed,
                    child: AnimatedBuilder(
                      animation: _fabRotateCtrl,
                      builder: (context, child) {
                        final rotation = Tween<double>(begin: 0, end: 0.125)
                            .animate(CurvedAnimation(
                              parent: _fabRotateCtrl,
                              curve: Curves.easeOutBack,
                            ))
                            .value;
                        final scale = Tween<double>(begin: 1.0, end: 0.9)
                            .animate(CurvedAnimation(
                              parent: _fabRotateCtrl,
                              curve: Curves.easeInOut,
                            ))
                            .value;
                        return Transform.rotate(
                          angle: rotation * 2 * math.pi,
                          child: Transform.scale(
                            scale: scale,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.accent,
                              AppColors.accentLight,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.15)
                                : Colors.white.withOpacity(0.6),
                            width: 2.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
//  Custom clipper for the concave notch in the center of the nav bar
// ─────────────────────────────────────────────────────────────────────────────

class _NavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const notchRadius = 38.0;
    const cornerRadius = 24.0;
    final centerX = size.width / 2;

    final path = Path();

    // Start from top-left with rounded corner
    path.moveTo(cornerRadius, 0);

    // Top edge up to the notch
    path.lineTo(centerX - notchRadius - 12, 0);

    // Smooth concave notch
    path.quadraticBezierTo(
      centerX - notchRadius + 4, 0,
      centerX - notchRadius + 8, 6,
    );
    path.arcToPoint(
      Offset(centerX + notchRadius - 8, 6),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    path.quadraticBezierTo(
      centerX + notchRadius - 4, 0,
      centerX + notchRadius + 12, 0,
    );

    // Continue top edge to top-right corner
    path.lineTo(size.width - cornerRadius, 0);

    // Top-right corner
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

    // Right edge
    path.lineTo(size.width, size.height - cornerRadius);

    // Bottom-right corner
    path.quadraticBezierTo(
      size.width, size.height, size.width - cornerRadius, size.height,
    );

    // Bottom edge
    path.lineTo(cornerRadius, size.height);

    // Bottom-left corner
    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

    // Left edge
    path.lineTo(0, cornerRadius);

    // Top-left corner
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Nav Item model
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  const _NavItem(this.activeIcon, this.icon, this.label);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Individual Nav Button with bounce + glow animations
// ─────────────────────────────────────────────────────────────────────────────

class _NavButton extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  final Brightness brightness;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.brightness,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with TickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late AnimationController _scaleCtrl;
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleCtrl = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _glowCtrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    if (widget.isActive) {
      _glowCtrl.forward();
    }
  }

  @override
  void didUpdateWidget(_NavButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _bounceCtrl.forward(from: 0);
      _glowCtrl.forward(from: 0);
    } else if (!widget.isActive && oldWidget.isActive) {
      _glowCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _scaleCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.accent;
    final inactiveColor = AppTheme.textTertiary(widget.brightness);
    final color = widget.isActive ? activeColor : inactiveColor;

    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) {
        _scaleCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleCtrl.reverse(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_bounceCtrl, _scaleCtrl, _glowCtrl]),
        builder: (context, child) {
          final bounce = Curves.elasticOut.transform(
            _bounceCtrl.value.clamp(0.0, 1.0),
          );
          final pressScale = 1.0 - 0.1 * _scaleCtrl.value;
          final bounceOffset = -6 * bounce * (1 - _bounceCtrl.value);

          return Transform.translate(
            offset: Offset(0, bounceOffset),
            child: Transform.scale(
              scale: pressScale,
              child: child,
            ),
          );
        },
        child: SizedBox(
          width: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with animated glow behind it
              Stack(
                alignment: Alignment.center,
                children: [
                  // Glow circle behind active icon
                  AnimatedBuilder(
                    animation: _glowCtrl,
                    builder: (context, child) {
                      return Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isActive
                              ? activeColor.withOpacity(0.12 * _glowCtrl.value)
                              : Colors.transparent,
                        ),
                      );
                    },
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: Icon(
                      widget.isActive ? widget.item.activeIcon : widget.item.icon,
                      key: ValueKey('${widget.item.label}_${widget.isActive}'),
                      color: color,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              // Label with fade
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                  fontSize: widget.isActive ? 10 : 9,
                  fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                child: Text(widget.item.label),
              ),
              const SizedBox(height: 3),
              // Active indicator dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: widget.isActive ? 5 : 0,
                height: widget.isActive ? 5 : 0,
                decoration: BoxDecoration(
                  color: widget.isActive ? activeColor : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: widget.isActive
                      ? [
                          BoxShadow(
                            color: activeColor.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Quick Actions Bottom Sheet (on FAB tap)
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsSheet extends StatefulWidget {
  final bool isDark;
  final Brightness brightness;

  const _QuickActionsSheet({
    required this.isDark,
    required this.brightness,
  });

  @override
  State<_QuickActionsSheet> createState() => _QuickActionsSheetState();
}

class _QuickActionsSheetState extends State<_QuickActionsSheet>
    with TickerProviderStateMixin {
  late AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? AppColors.darkSurface.withOpacity(0.95)
                  : AppColors.lightSurface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(
                color: AppTheme.border(widget.brightness).withOpacity(0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(widget.isDark ? 0.4 : 0.12),
                  blurRadius: 40,
                  offset: const Offset(0, -10),
                ),
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.08),
                  blurRadius: 60,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textTertiary(widget.brightness).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Quick Actions',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(widget.brightness),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'What would you like to do?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textTertiary(widget.brightness),
                  ),
                ),
                const SizedBox(height: 24),
                // Action buttons
                _StaggeredItem(
                  animation: _staggerCtrl,
                  startInterval: 0.0,
                  endInterval: 0.5,
                  child: _ActionTile(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Create Class',
                    subtitle: 'Start a new study group',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9F67FF)],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateClassScreen(),
                        ),
                      );
                    },
                    brightness: widget.brightness,
                  ),
                ),
                const SizedBox(height: 12),
                _StaggeredItem(
                  animation: _staggerCtrl,
                  startInterval: 0.2,
                  endInterval: 0.7,
                  child: _ActionTile(
                    icon: Icons.login_rounded,
                    title: 'Join Class',
                    subtitle: 'Enter a class code to join',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF34D399)],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const JoinClassScreen(),
                        ),
                      );
                    },
                    brightness: widget.brightness,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StaggeredItem extends StatelessWidget {
  final AnimationController animation;
  final double startInterval;
  final double endInterval;
  final Widget child;

  const _StaggeredItem({
    required this.animation,
    required this.startInterval,
    required this.endInterval,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Interval(startInterval, endInterval, curve: Curves.easeOutCubic),
    ));
    final fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: animation,
      curve: Interval(startInterval, endInterval, curve: Curves.easeOut),
    ));

    return SlideTransition(
      position: slideAnim,
      child: FadeTransition(
        opacity: fadeAnim,
        child: child,
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final Brightness brightness;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    required this.brightness,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverCtrl;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hoverCtrl.forward(),
      onTapUp: (_) {
        _hoverCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _hoverCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _hoverCtrl,
        builder: (context, child) {
          final scale = 1.0 - 0.03 * _hoverCtrl.value;
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceAlt(widget.brightness),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: AppTheme.border(widget.brightness).withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradient.colors.first.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(widget.brightness),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textTertiary(widget.brightness),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppTheme.textTertiary(widget.brightness),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Animated builder helper (avoids conflict with Flutter's AnimatedBuilder)
// ─────────────────────────────────────────────────────────────────────────────

class AnimatedBuilder extends StatelessWidget {
  final Listenable animation;
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
