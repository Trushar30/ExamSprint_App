import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../providers/resource_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/tag_chip.dart';
import '../resource/add_resource_screen.dart';

class SubjectDetailScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String classId;
  const SubjectDetailScreen({super.key, required this.subjectId, required this.subjectName, required this.classId});

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  @override
  void initState() { super.initState(); context.read<ResourceProvider>().loadResources(widget.subjectId); }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<ResourceProvider>();
    final resources = rp.filteredResources;
    final predefinedTags = ['Notes', 'PYQ', 'Slides', 'Links', 'Important', 'Assignment', 'Lab'];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(8, 8, 16, 0), child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary), onPressed: () => Navigator.pop(context)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.subjectName, style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              Text('${rp.resources.length} resources', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiary)),
            ])),
          ])),
          const SizedBox(height: 12),
          // Tag filters
          SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 24), children: [
            TagChip(tag: 'All', selected: rp.selectedTag == null, onTap: () => rp.setSelectedTag(null)),
            const SizedBox(width: 8),
            ...predefinedTags.map((t) => Padding(padding: const EdgeInsets.only(right: 8), child: TagChip(tag: t, selected: rp.selectedTag?.toLowerCase() == t.toLowerCase(), onTap: () => rp.setSelectedTag(rp.selectedTag?.toLowerCase() == t.toLowerCase() ? null : t)))),
          ])),
          const SizedBox(height: 12),
          // Resources
          Expanded(child: rp.isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
            : resources.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.folder_open_outlined, size: 56, color: AppTheme.textTertiary), const SizedBox(height: 12), Text('No resources yet', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)), const SizedBox(height: 4), Text('Tap + to share a resource', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textTertiary))]))
            : AnimationLimiter(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 24), itemCount: resources.length, itemBuilder: (context, i) {
              final r = resources[i];
              return AnimationConfiguration.staggeredList(position: i, duration: const Duration(milliseconds: 375), child: SlideAnimation(verticalOffset: 50, child: FadeInAnimation(child: Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassCard(
                onTap: () async {
                  final url = r.fileUrl ?? r.linkUrl;
                  if (url != null) {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(r.typeIcon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      Row(children: [
                        if (r.uploader != null) Text(r.uploader!.fullName, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiary)),
                        if (r.uploader != null) Text(' • ', style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
                        Text(timeago.format(r.createdAt), style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiary)),
                        if (r.fileSizeFormatted.isNotEmpty) Text(' • ${r.fileSizeFormatted}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiary)),
                      ]),
                    ])),
                    Icon(r.isLink ? Icons.open_in_new_rounded : Icons.download_rounded, color: AppTheme.accent, size: 20),
                  ]),
                  if (r.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(r.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary))),
                  if (r.tags.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Wrap(spacing: 6, runSpacing: 4, children: r.tags.map((t) => TagChip(tag: t)).toList())),
                ]),
              )))));
            })),
          ),
        ])),
      ),
      floatingActionButton: FloatingActionButton(backgroundColor: AppTheme.accent, onPressed: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddResourceScreen(subjectId: widget.subjectId)));
        if (result == true) rp.loadResources(widget.subjectId);
      }, child: const Icon(Icons.add_rounded, color: Colors.white)),
    );
  }
}
