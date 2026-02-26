import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/class_provider.dart';
import '../../providers/subject_provider.dart';
import '../../widgets/glass_card.dart';
import '../subject/create_subject_screen.dart';
import '../subject/subject_detail_screen.dart';
import '../discussion/discussion_screen.dart';
import 'class_settings_screen.dart';

class ClassDashboardScreen extends StatefulWidget {
  final String classId;
  final String className;
  const ClassDashboardScreen({super.key, required this.classId, required this.className});

  @override
  State<ClassDashboardScreen> createState() => _ClassDashboardScreenState();
}

class _ClassDashboardScreenState extends State<ClassDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  void _loadData() {
    final userId = context.read<AuthProvider>().userId!;
    context.read<ClassProvider>().loadClassDetails(widget.classId, userId);
    context.read<SubjectProvider>().loadSubjects(widget.classId);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ClassProvider>();
    final sp = context.watch<SubjectProvider>();
    final cls = cp.currentClass;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary), onPressed: () => Navigator.pop(context)),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.className, style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  if (cls != null) Text('${cls.memberCount ?? 0} members • ${cls.subjectCount ?? 0} subjects', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiary)),
                ])),
                if (cls != null) IconButton(icon: const Icon(Icons.share_rounded, color: AppTheme.accent), onPressed: () => SharePlus.instance.share(ShareParams(text: 'Join "${cls.name}" on ExamSprint!\nCode: ${cls.code} ⚡'))),
                if (cls != null) IconButton(icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClassSettingsScreen(classId: widget.classId)))),
              ]),
            ),
            // Code bar
            if (cls != null) Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: GestureDetector(
                onTap: () { Clipboard.setData(ClipboardData(text: cls.code)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied!'))); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.accent.withOpacity(0.3))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.key_rounded, size: 16, color: AppTheme.accent),
                    const SizedBox(width: 8),
                    Text('Code: ${cls.code}', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.accent, letterSpacing: 2)),
                    const SizedBox(width: 8),
                    const Icon(Icons.copy_rounded, size: 14, color: AppTheme.accent),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              child: TabBar(controller: _tabController, indicator: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(AppTheme.radiusMd)), indicatorSize: TabBarIndicatorSize.tab, labelColor: Colors.white, unselectedLabelColor: AppTheme.textTertiary, dividerColor: Colors.transparent, tabs: const [Tab(text: 'Subjects'), Tab(text: 'Discussion'), Tab(text: 'Members')]),
            ),
            const SizedBox(height: 16),
            Expanded(child: TabBarView(controller: _tabController, children: [
              _SubjectsTab(classId: widget.classId, subjects: sp.subjects, isLoading: sp.isLoading),
              DiscussionScreen(classId: widget.classId),
              _MembersTab(members: cp.members, currentUserRole: cls?.userRole, classId: widget.classId),
            ])),
          ]),
        ),
      ),
      floatingActionButton: _tabController.index == 0 ? FloatingActionButton(backgroundColor: AppTheme.accent, onPressed: () async {
        final r = await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateSubjectScreen(classId: widget.classId)));
        if (r == true) { sp.loadSubjects(widget.classId); _loadData(); }
      }, child: const Icon(Icons.add_rounded, color: Colors.white)) : null,
    );
  }
}

class _SubjectsTab extends StatelessWidget {
  final String classId;
  final List subjects;
  final bool isLoading;
  const _SubjectsTab({required this.classId, required this.subjects, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    if (subjects.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.menu_book_outlined, size: 56, color: AppTheme.textTertiary), const SizedBox(height: 12), Text('No subjects yet', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)), const SizedBox(height: 4), Text('Tap + to add subjects', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textTertiary))]));

    return AnimationLimiter(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 24), itemCount: subjects.length, itemBuilder: (context, i) {
      final s = subjects[i];
      return AnimationConfiguration.staggeredList(position: i, duration: const Duration(milliseconds: 375), child: SlideAnimation(verticalOffset: 50, child: FadeInAnimation(child: Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassCard(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubjectDetailScreen(subjectId: s.id, subjectName: s.name, classId: classId))),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.book_outlined, color: AppTheme.accent, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.name, style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            if (s.professor != null) Text(s.professor!, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiary)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(8)), child: Text('${s.resourceCount ?? 0} files', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textTertiary))),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary, size: 20),
        ]),
      )))));
    }));
  }
}

class _MembersTab extends StatelessWidget {
  final List members;
  final String? currentUserRole;
  final String classId;
  const _MembersTab({required this.members, required this.currentUserRole, required this.classId});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    return AnimationLimiter(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 24), itemCount: members.length, itemBuilder: (context, i) {
      final m = members[i];
      final Color rc = m.role == 'admin' ? AppTheme.warning : m.role == 'co_admin' ? AppTheme.success : AppTheme.textTertiary;
      return AnimationConfiguration.staggeredList(position: i, duration: const Duration(milliseconds: 375), child: SlideAnimation(verticalOffset: 50, child: FadeInAnimation(child: Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: (currentUserRole == 'admin' || currentUserRole == 'co_admin') && m.role != 'admin' ? () => _showOptions(context, m) : null,
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(10)), child: Center(child: Text(m.profile?.initials ?? '?', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)))),
          const SizedBox(width: 12),
          Expanded(child: Text(m.profile?.fullName ?? 'Unknown', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textPrimary))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: rc.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: rc.withOpacity(0.3))), child: Text(m.roleLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: rc))),
        ]),
      )))));
    }));
  }

  void _showOptions(BuildContext context, dynamic m) {
    final userId = context.read<AuthProvider>().userId!;
    showModalBottomSheet(context: context, backgroundColor: AppTheme.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(m.profile?.fullName ?? 'Member', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      const SizedBox(height: 20),
      if (m.role == 'member') ListTile(leading: const Icon(Icons.arrow_upward_rounded, color: AppTheme.success), title: const Text('Promote to Co-Admin'), onTap: () { context.read<ClassProvider>().updateMemberRole(memberId: m.id, newRole: 'co_admin', classId: classId, userId: userId); Navigator.pop(ctx); }),
      if (m.role == 'co_admin') ListTile(leading: const Icon(Icons.arrow_downward_rounded, color: AppTheme.warning), title: const Text('Demote to Member'), onTap: () { context.read<ClassProvider>().updateMemberRole(memberId: m.id, newRole: 'member', classId: classId, userId: userId); Navigator.pop(ctx); }),
      ListTile(leading: const Icon(Icons.remove_circle_outline, color: AppTheme.error), title: const Text('Remove from Class'), onTap: () { context.read<ClassProvider>().removeMember(memberId: m.id, classId: classId, userId: userId); Navigator.pop(ctx); }),
    ])));
  }
}
