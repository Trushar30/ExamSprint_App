import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../../config/theme.dart';
import '../../config/supabase_config.dart';
import '../../models/subject.dart';
import '../../providers/ai_provider.dart';
import '../../services/subject_service.dart';
import '../../services/class_service.dart';
import 'ai_quiz_screen.dart';
import 'ai_summary_screen.dart';
import 'ai_chat_screen.dart';
import 'ai_study_plan_screen.dart';

class AiPlaygroundScreen extends StatefulWidget {
  const AiPlaygroundScreen({super.key});

  @override
  State<AiPlaygroundScreen> createState() => _AiPlaygroundScreenState();
}

class _AiPlaygroundScreenState extends State<AiPlaygroundScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _staggerCtrl;
  List<Subject> _allSubjects = [];
  bool _isLoadingSubjects = true;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _staggerCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _loadSubjects();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final classService = ClassService();
      final subjectService = SubjectService();
      final classes = await classService.getUserClasses(userId);

      final subjects = <Subject>[];
      for (final cls in classes) {
        final subs = await subjectService.getSubjects(cls.id);
        subjects.addAll(subs);
      }

      if (mounted) {
        setState(() {
          _allSubjects = subjects;
          _isLoadingSubjects = false;
        });
        context.read<AiProvider>().setAvailableSubjects(subjects);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSubjects = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final aiProvider = context.watch<AiProvider>();

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.bgGradient(brightness)),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            _buildHeader(brightness),
            const SizedBox(height: 16),

            // ── Subject Filter ──
            _buildSubjectFilter(brightness, isDark, aiProvider),
            const SizedBox(height: 8),

            // ── Context Status ──
            if (aiProvider.selectedSubject != null)
              _buildContextStatus(brightness, aiProvider),

            // ── Feature Cards ──
            Expanded(
              child: aiProvider.selectedSubject == null
                  ? _buildEmptyState(brightness)
                  : _buildFeatures(brightness, isDark, aiProvider),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent
                          .withOpacity(0.3 + 0.2 * _pulseCtrl.value),
                      blurRadius: 20 + 10 * _pulseCtrl.value,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              );
            },
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
    );
  }

  Widget _buildSubjectFilter(
      Brightness brightness, bool isDark, AiProvider aiProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'SELECT SUBJECT',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppTheme.textTertiary(brightness),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: _isLoadingSubjects
              ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  ),
                )
              : _allSubjects.isEmpty
                  ? Center(
                      child: Text(
                        'No subjects found. Join a class first!',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textTertiary(brightness),
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _allSubjects.length,
                      itemBuilder: (context, index) {
                        final subject = _allSubjects[index];
                        final isSelected =
                            aiProvider.selectedSubject?.id == subject.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => aiProvider.selectSubject(
                                isSelected ? null : subject),
                            child: AnimatedContainer(
                              duration: AppTheme.animFast,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? AppTheme.primaryGradient
                                    : null,
                                color: isSelected
                                    ? null
                                    : AppTheme.surfaceAlt(brightness),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusFull),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : AppTheme.border(brightness),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.book_rounded,
                                    size: 14,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textSecondary(brightness),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    subject.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textSecondary(brightness),
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
      ],
    );
  }

  Widget _buildContextStatus(Brightness brightness, AiProvider aiProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: AnimatedContainer(
        duration: AppTheme.animMedium,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: aiProvider.isLoadingContext
              ? AppColors.warning.withOpacity(0.1)
              : aiProvider.hasContext
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: aiProvider.isLoadingContext
                ? AppColors.warning.withOpacity(0.3)
                : aiProvider.hasContext
                    ? AppColors.success.withOpacity(0.3)
                    : AppColors.error.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            if (aiProvider.isLoadingContext)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.warning,
                ),
              )
            else
              Icon(
                aiProvider.hasContext
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
                size: 16,
                color: aiProvider.hasContext
                    ? AppColors.success
                    : AppColors.error,
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                aiProvider.isLoadingContext
                    ? 'Loading resource context...'
                    : aiProvider.hasContext
                        ? '${(aiProvider.context.length / 1000).toStringAsFixed(1)}K chars of context loaded'
                        : 'No extracted text found. Upload resources first!',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: aiProvider.isLoadingContext
                      ? AppColors.warning
                      : aiProvider.hasContext
                          ? AppColors.success
                          : AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: 64,
            color: AppTheme.textTertiary(brightness).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a subject to start',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary(brightness),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Choose a subject above to unlock AI-powered study tools',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textTertiary(brightness),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures(
      Brightness brightness, bool isDark, AiProvider aiProvider) {
    final features = [
      _FeatureData(
        icon: Icons.quiz_rounded,
        title: 'Smart Quiz',
        subtitle: 'AI-generated MCQ quiz from your resources',
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9F67FF)],
        ),
        onTap: () => _navigateTo(const AiQuizScreen()),
      ),
      _FeatureData(
        icon: Icons.summarize_rounded,
        title: 'AI Summary',
        subtitle: 'Get concise summaries of study material',
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
        ),
        onTap: () => _navigateTo(const AiSummaryScreen()),
      ),
      _FeatureData(
        icon: Icons.chat_rounded,
        title: 'Q&A Chat',
        subtitle: 'Ask questions about your resources',
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF34D399)],
        ),
        onTap: () => _navigateTo(const AiChatScreen()),
      ),
      _FeatureData(
        icon: Icons.trending_up_rounded,
        title: 'Study Plan',
        subtitle: 'Personalized day-wise study schedule',
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
        ),
        onTap: () => _navigateTo(const AiStudyPlanScreen()),
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        final delay = index * 0.15;

        return _StaggeredItem(
          animation: _staggerCtrl,
          startInterval: delay.clamp(0.0, 0.7),
          endInterval: (delay + 0.4).clamp(0.0, 1.0),
          child: _FeatureCard(
            data: feature,
            brightness: brightness,
            isDark: isDark,
            enabled: aiProvider.hasContext && !aiProvider.isLoadingContext,
          ),
        );
      },
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

// ─── Data Models ─────────────────────────────────────────────────────────────

class _FeatureData {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  _FeatureData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });
}

// ─── Feature Card ────────────────────────────────────────────────────────────

class _FeatureCard extends StatefulWidget {
  final _FeatureData data;
  final Brightness brightness;
  final bool isDark;
  final bool enabled;

  const _FeatureCard({
    required this.data,
    required this.brightness,
    required this.isDark,
    required this.enabled,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverCtrl;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = widget.enabled ? 1.0 : 0.5;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => _hoverCtrl.forward() : null,
        onTapUp: widget.enabled
            ? (_) {
                _hoverCtrl.reverse();
                widget.data.onTap();
              }
            : null,
        onTapCancel: widget.enabled ? () => _hoverCtrl.reverse() : null,
        child: AnimatedBuilder(
          animation: _hoverCtrl,
          builder: (context, child) {
            final scale = 1.0 - 0.03 * _hoverCtrl.value;
            return Transform.scale(scale: scale, child: child);
          },
          child: AnimatedOpacity(
            duration: AppTheme.animFast,
            opacity: opacity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? AppColors.darkCard
                        : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                      color: AppTheme.border(widget.brightness).withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: widget.data.gradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: widget.data.gradient.colors.first
                                  .withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Icon(widget.data.icon,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.data.title,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary(widget.brightness),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.data.subtitle,
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
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stagger Animation ──────────────────────────────────────────────────────

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
      begin: const Offset(0, 0.3),
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
      child: FadeTransition(opacity: fadeAnim, child: child),
    );
  }
}

// ─── AnimatedBuilder ─────────────────────────────────────────────────────────

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
