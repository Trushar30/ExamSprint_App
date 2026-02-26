import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/class_provider.dart';
import '../../widgets/glass_card.dart';
import '../class/create_class_screen.dart';
import '../class/join_class_screen.dart';
import '../class/class_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  late AnimationController _greetCtrl;

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _greetCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _greetCtrl.dispose();
    super.dispose();
  }

  void _loadClasses() {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      context.read<ClassProvider>().loadUserClasses(userId);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final classProvider = context.watch<ClassProvider>();
    final brightness = Theme.of(context).brightness;

    final filteredClasses = classProvider.classes.where((cls) {
      if (_searchQuery.isEmpty) return true;
      return cls.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (cls.department ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.bgGradient(brightness)),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Greeting Banner ──────────────────────────────────────
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _greetCtrl,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(
                opacity: _greetCtrl,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'ExamSprint',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary(brightness),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('⚡', style: TextStyle(fontSize: 22)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_getGreeting()}, ${authProvider.profile?.fullName.split(' ').first ?? 'Student'} 👋',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.textTertiary(brightness),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppTheme.glowShadow(),
                        ),
                        child: Center(
                          child: Text(
                            authProvider.profile?.initials ?? '?',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ─── Search Bar ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt(brightness),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.border(brightness)),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(color: AppTheme.textPrimary(brightness)),
                  decoration: InputDecoration(
                    hintText: 'Search your classes...',
                    hintStyle: TextStyle(color: AppTheme.textTertiary(brightness)),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppTheme.textTertiary(brightness),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ─── Quick Actions ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.add_rounded,
                      label: 'Create Class',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF9F67FF)],
                      ),
                      brightness: brightness,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateClassScreen(),
                          ),
                        );
                        if (result == true) _loadClasses();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.login_rounded,
                      label: 'Join Class',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF34D399)],
                      ),
                      brightness: brightness,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const JoinClassScreen(),
                          ),
                        );
                        if (result == true) _loadClasses();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Section Header ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Classes',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(brightness),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${classProvider.classes.length}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ─── Class List ───────────────────────────────────────────
            Expanded(
              child: classProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                      ),
                    )
                  : filteredClasses.isEmpty
                      ? _EmptyState(brightness: brightness)
                      : RefreshIndicator(
                          onRefresh: () async => _loadClasses(),
                          color: AppColors.accent,
                          child: AnimationLimiter(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                              itemCount: filteredClasses.length,
                              itemBuilder: (context, index) {
                                final cls = filteredClasses[index];
                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration:
                                      const Duration(milliseconds: 375),
                                  child: SlideAnimation(
                                    verticalOffset: 50,
                                    child: FadeInAnimation(
                                      child: _ClassCard(
                                        cls: cls,
                                        brightness: brightness,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ClassDashboardScreen(
                                                classId: cls.id,
                                                className: cls.name,
                                              ),
                                            ),
                                          );
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
    );
  }
}

// ─── Quick Action Card ────────────────────────────────────────────────────────

class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final Brightness brightness;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.brightness,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 100),
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
        scale: Tween<double>(begin: 1.0, end: 0.95).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

// ─── Class Card ───────────────────────────────────────────────────────────────

class _ClassCard extends StatelessWidget {
  final dynamic cls;
  final VoidCallback onTap;
  final Brightness brightness;

  const _ClassCard({
    required this.cls,
    required this.onTap,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = AppColors.hashColor(cls.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Colored initials
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      cls.name
                          .substring(0, cls.name.length >= 2 ? 2 : 1)
                          .toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cls.name,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary(brightness),
                        ),
                      ),
                      if (cls.semester != null || cls.department != null)
                        Text(
                          [cls.semester, cls.department]
                              .where((e) => e != null)
                              .join(' • '),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textTertiary(brightness),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cls.code,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            if (cls.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                cls.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary(brightness),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoPill(
                  icon: Icons.person_outline,
                  label: cls.userRole == 'admin'
                      ? 'Admin'
                      : cls.userRole == 'co_admin'
                          ? 'Co-Admin'
                          : 'Member',
                  color: cls.userRole == 'admin'
                      ? AppColors.warning
                      : cls.userRole == 'co_admin'
                          ? AppColors.success
                          : AppTheme.textTertiary(brightness),
                  brightness: brightness,
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textTertiary(brightness),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info Pill ────────────────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Brightness brightness;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final Brightness brightness;
  const _EmptyState({required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.school_outlined,
              size: 40,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No classes yet',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary(brightness),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create or join a class to get started',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textTertiary(brightness),
            ),
          ),
          const SizedBox(height: 80), // space for bottom nav
        ],
      ),
    );
  }
}
