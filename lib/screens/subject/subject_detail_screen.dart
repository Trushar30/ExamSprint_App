import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/resource_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/tag_chip.dart';
import '../resource/add_resource_screen.dart';
import '../resource/resource_reader_screen.dart';

class SubjectDetailScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const SubjectDetailScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  String? _selectedTag;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ResourceProvider>().loadResources(widget.subjectId);
    });
  }

  IconData _getResourceIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'pdf':
      case 'document':
        return Icons.picture_as_pdf_rounded;
      case 'image':
        return Icons.image_rounded;
      case 'link':
        return Icons.link_rounded;
      case 'video':
        return Icons.play_circle_outline_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getResourceColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'pdf':
      case 'document':
        return AppColors.error;
      case 'image':
        return AppColors.success;
      case 'link':
        return AppColors.info;
      case 'video':
        return AppColors.warning;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final resourceProvider = context.watch<ResourceProvider>();
    final color = AppColors.hashColor(widget.subjectName);

    final filteredResources = resourceProvider.resources.where((r) {
      if (_selectedTag == null) return true;
      return r.tags.contains(_selectedTag);
    }).toList();

    final allTags = resourceProvider.resources
        .expand((r) => r.tags)
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.bg(brightness),
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppTheme.surface(brightness),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded,
                  color: AppTheme.textPrimary(brightness)),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.15),
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
                        Text(
                          widget.subjectName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary(brightness),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${resourceProvider.resources.length} resources',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textTertiary(brightness),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Tags filter
          if (allTags.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    TagChip(
                      tag: 'All',
                      selected: _selectedTag == null,
                      onTap: () => setState(() => _selectedTag = null),
                    ),
                    const SizedBox(width: 8),
                    ...allTags.map((tag) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: TagChip(
                            tag: tag,
                            selected: _selectedTag == tag,
                            onTap: () => setState(
                              () => _selectedTag =
                                  _selectedTag == tag ? null : tag,
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),

          // Resources
          if (resourceProvider.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            )
          else if (filteredResources.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 48,
                      color: AppTheme.textTertiary(brightness),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No resources yet',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary(brightness),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add the first resource for this subject',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textTertiary(brightness),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final resource = filteredResources[index];
                  final resType = resource.fileUrl != null ? 'document' : 'link';
                  final icon = _getResourceIcon(resType);
                  final iconColor = _getResourceColor(resType);

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    child: GlassCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                ResourceReaderScreen(resource: resource),
                            transitionsBuilder: (_, animation, __, child) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                )),
                                child: child,
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 400),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: iconColor, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  resource.title,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary(brightness),
                                  ),
                                ),
                                if (resource.description.isNotEmpty)
                                  Text(
                                    resource.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.textTertiary(brightness),
                                    ),
                                  ),
                                if (resource.tags.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Wrap(
                                      spacing: 4,
                                      children: resource.tags
                                          .take(3)
                                          .map((t) => TagChip(tag: t))
                                          .toList(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: AppTheme.textTertiary(brightness),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: filteredResources.length,
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AddResourceScreen(subjectId: widget.subjectId),
            ),
          );
          if (mounted) {
            context
                .read<ResourceProvider>()
                .loadResources(widget.subjectId);
          }
        },
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
