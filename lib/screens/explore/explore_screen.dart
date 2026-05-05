import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/class_provider.dart';
import '../../widgets/glass_card.dart';
import '../class/class_dashboard_screen.dart';
import '../class/create_class_screen.dart';
import '../class/join_class_screen.dart';
import '../../widgets/animated_builder.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late AnimationController _headerCtrl;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadClasses());
  }

  Future<void> _loadClasses() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      await context.read<ClassProvider>().loadUserClasses(userId);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _headerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final classProvider = context.watch<ClassProvider>();
    final classes = classProvider.classes.where((c) {
      return c.name.toLowerCase().contains(_searchQuery) ||
             (c.department?.toLowerCase().contains(_searchQuery) ?? false) ||
             c.code.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient(brightness)),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ───────────────────────────────────────────────
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _headerCtrl,
                  curve: AppTheme.springCurve,
                )),
                child: FadeTransition(
                  opacity: _headerCtrl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                        child: Text(
                          'Explore',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary(brightness),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Your classes and study groups',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.textTertiary(brightness),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // ─── Search Bar ─────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceAlt(brightness),
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            border: Border.all(
                              color: AppTheme.border(brightness),
                            ),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: 'Search classes, subjects...',
                              hintStyle: TextStyle(
                                color: AppTheme.textTertiary(brightness),
                              ),
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
                            style: TextStyle(
                              color: AppTheme.textPrimary(brightness),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Stats Row ───────────────────────────────────────────
              if (classProvider.classes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _StatBadge(
                        label: 'Classes',
                        value: classProvider.classes.length.toString(),
                        icon: Icons.class_outlined,
                        color: AppColors.info,
                        brightness: brightness,
                      ),
                      const SizedBox(width: 12),
                      _StatBadge(
                        label: 'Subjects',
                        value: classProvider.classes.fold<int>(
                            0, (sum, c) => sum + (c.subjectCount ?? 0)).toString(),
                        icon: Icons.book_outlined,
                        color: AppColors.accent,
                        brightness: brightness,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // ─── Class Grid ─────────────────────────────────────────
              Expanded(
                child: classProvider.isLoading && classes.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.accent))
                    : classes.isEmpty
                        ? _buildEmptyState(brightness)
                        : RefreshIndicator(
                            onRefresh: _loadClasses,
                            color: AppColors.accent,
                            child: AnimationLimiter(
                              child: GridView.builder(
                                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.85,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: classes.length,
                                itemBuilder: (context, index) {
                                  return AnimationConfiguration.staggeredGrid(
                                    position: index,
                                    duration: const Duration(milliseconds: 500),
                                    columnCount: 2,
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: _ClassGridCard(
                                          classModel: classes[index],
                                          brightness: brightness,
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
      floatingActionButton: _buildFABs(brightness),
    );
  }

  Widget _buildEmptyState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppTheme.glowShadow(),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            _searchQuery.isNotEmpty ? 'No classes found' : 'No classes yet',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(brightness),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Join or create a class to get started',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textTertiary(brightness),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFABs(Brightness brightness) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: 'join_class',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JoinClassScreen()),
            );
          },
          backgroundColor: AppTheme.surfaceAlt(brightness),
          icon: Icon(Icons.login_rounded, color: AppColors.info),
          label: Text('Join', style: TextStyle(color: AppTheme.textPrimary(brightness))),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'create_class',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateClassScreen()),
            );
          },
          backgroundColor: AppColors.accent,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Create Class', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 80), // Avoid bottom nav bar
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Brightness brightness;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppTheme.textSecondary(brightness),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClassGridCard extends StatelessWidget {
  final classModel; // Using dynamic here to avoid importing model explicitly if it conflicts, but better to use ClassModel
  final Brightness brightness;

  const _ClassGridCard({
    required this.classModel,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.hashColor(classModel.name);
    
    return GlassCard(
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClassDashboardScreen(
            classId: classModel.id,
            className: classModel.name,
          )),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top color bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.school_rounded, color: color, size: 18),
                ),
                const SizedBox(height: 12),
                
                // Name
                Text(
                  classModel.name,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(brightness),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                // Code
                Text(
                  'Code: ${classModel.code}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textTertiary(brightness),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                
                // Bottom stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people_rounded, size: 12, color: AppTheme.textTertiary(brightness)),
                        const SizedBox(width: 4),
                        Text(
                          '${classModel.memberCount ?? 0}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary(brightness),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.folder_copy_rounded, size: 12, color: AppTheme.textTertiary(brightness)),
                        const SizedBox(width: 4),
                        Text(
                          '${classModel.subjectCount ?? 0}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary(brightness),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
