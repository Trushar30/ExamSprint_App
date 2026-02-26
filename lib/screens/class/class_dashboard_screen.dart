import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme.dart';
import '../../providers/class_provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';
import '../discussion/discussion_screen.dart';
import '../subject/create_subject_screen.dart';
import '../subject/subject_detail_screen.dart';
import 'class_settings_screen.dart';

class ClassDashboardScreen extends StatefulWidget {
  final String classId;
  final String className;

  const ClassDashboardScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<ClassDashboardScreen> createState() => _ClassDashboardScreenState();
}

class _ClassDashboardScreenState extends State<ClassDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  bool _headerExpanded = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      context.read<ClassProvider>().loadClassDetails(widget.classId, userId);
    }
    context.read<SubjectProvider>().loadSubjects(widget.classId);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final classProvider = context.watch<ClassProvider>();
    final cls = classProvider.currentClass;
    final accentColor = AppColors.hashColor(widget.className);

    return Scaffold(
      backgroundColor: AppTheme.bg(brightness),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerScrolled) => [
          // ─── Hero Header ────────────────────────────────────────
          SliverAppBar(
            expandedHeight: _headerExpanded ? 220 : 0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.surface(brightness),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimary(brightness),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.share_outlined,
                  color: AppTheme.textPrimary(brightness),
                ),
                onPressed: () {
                  if (cls != null) {
                    Share.share(
                      'Join my class "${cls.name}" on ExamSprint!\nCode: ${cls.code}',
                    );
                  }
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: AppTheme.textPrimary(brightness),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClassSettingsScreen(
                        classId: widget.classId,
                      ),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withOpacity(0.2),
                      AppTheme.surface(brightness),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accentColor,
                                    accentColor.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  widget.className
                                      .substring(
                                          0,
                                          widget.className.length >= 2
                                              ? 2
                                              : 1)
                                      .toUpperCase(),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 20,
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
                                    widget.className,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          AppTheme.textPrimary(brightness),
                                    ),
                                  ),
                                  if (cls != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accentColor
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
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
                                        if (cls.semester != null) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            cls.semester!,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppTheme.textTertiary(
                                                  brightness),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                color: AppTheme.surface(brightness),
                child: _SegmentedTabs(
                  controller: _tabController,
                  brightness: brightness,
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _SubjectsTab(
              classId: widget.classId,
              brightness: brightness,
            ),
            DiscussionScreen(classId: widget.classId),
            _MembersTab(
              classId: widget.classId,
              brightness: brightness,
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateSubjectScreen(classId: widget.classId),
                  ),
                );
                _loadData();
              },
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}

// ─── Segmented Tabs ───────────────────────────────────────────────────────────

class _SegmentedTabs extends StatelessWidget {
  final TabController controller;
  final Brightness brightness;

  const _SegmentedTabs({required this.controller, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt(brightness),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.3),
              blurRadius: 8,
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textTertiary(brightness),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Subjects', height: 36),
          Tab(text: 'Discussion', height: 36),
          Tab(text: 'Members', height: 36),
        ],
      ),
    );
  }
}

// ─── Subjects Tab ─────────────────────────────────────────────────────────────

class _SubjectsTab extends StatelessWidget {
  final String classId;
  final Brightness brightness;

  const _SubjectsTab({required this.classId, required this.brightness});

  @override
  Widget build(BuildContext context) {
    final subjectProvider = context.watch<SubjectProvider>();

    if (subjectProvider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (subjectProvider.subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: AppTheme.textTertiary(brightness),
            ),
            const SizedBox(height: 16),
            Text(
              'No subjects yet',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary(brightness),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a subject to start sharing resources',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textTertiary(brightness),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
      itemCount: subjectProvider.subjects.length,
      itemBuilder: (context, index) {
        final subject = subjectProvider.subjects[index];
        final color = AppColors.hashColor(subject.name);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubjectDetailScreen(
                    subjectId: subject.id,
                    subjectName: subject.name,
                  ),
                ),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.book_outlined, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary(brightness),
                        ),
                      ),
                      if (subject.code != null)
                        Text(
                          subject.code!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textTertiary(brightness),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textTertiary(brightness),
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Members Tab ──────────────────────────────────────────────────────────────

class _MembersTab extends StatelessWidget {
  final String classId;
  final Brightness brightness;

  const _MembersTab({required this.classId, required this.brightness});

  @override
  Widget build(BuildContext context) {
    final classProvider = context.watch<ClassProvider>();
    final members = classProvider.members;

    if (classProvider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (members.isEmpty) {
      return Center(
        child: Text(
          'No members yet',
          style: GoogleFonts.inter(
            color: AppTheme.textTertiary(brightness),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final isAdmin = member.isAdmin;
        final isCoAdmin = member.isCoAdmin;
        final name = member.profile?.fullName ?? 'Unknown';
        final initials = name.isNotEmpty
            ? name
                .split(' ')
                .map((e) => e.isNotEmpty ? e[0] : '')
                .take(2)
                .join()
                .toUpperCase()
            : '?';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: isAdmin
                        ? const LinearGradient(
                            colors: [AppColors.accent, AppColors.accentLight],
                          )
                        : null,
                    color: isAdmin ? null : AppTheme.surfaceAlt(brightness),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isAdmin
                            ? Colors.white
                            : AppTheme.textSecondary(brightness),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary(brightness),
                    ),
                  ),
                ),
                if (isAdmin || isCoAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: (isAdmin ? AppColors.warning : AppColors.success)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isAdmin ? 'Admin' : 'Co-Admin',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            isAdmin ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
