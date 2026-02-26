import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:ui';
import 'dart:math' as math;
import '../../config/theme.dart';
import '../../models/resource.dart';
import '../../widgets/glass_card.dart';

class ResourceReaderScreen extends StatefulWidget {
  final Resource resource;

  const ResourceReaderScreen({super.key, required this.resource});

  @override
  State<ResourceReaderScreen> createState() => _ResourceReaderScreenState();
}

class _ResourceReaderScreenState extends State<ResourceReaderScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _pulseCtrl;
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _showInfo = false;
  bool _pdfLoadFailed = false;
  bool _pdfLoading = true;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..forward();
    _pulseCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _openExternal() async {
    final url = widget.resource.fileUrl ?? widget.resource.linkUrl;
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _share() {
    final url = widget.resource.fileUrl ?? widget.resource.linkUrl ?? '';
    SharePlus.instance.share(
      ShareParams(
        title: widget.resource.title,
        text: '${widget.resource.title}\n$url',
      ),
    );
  }

  bool get _isImage {
    final ft = widget.resource.fileType?.toLowerCase() ?? '';
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ft);
  }

  bool get _isPdf {
    return widget.resource.fileType?.toLowerCase() == 'pdf';
  }

  bool get _isLink {
    return widget.resource.isLink && !widget.resource.isFile;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final res = widget.resource;

    return Scaffold(
      backgroundColor: AppTheme.bg(brightness),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(gradient: AppTheme.bgGradient(brightness)),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // ── Custom App Bar ──
                _buildAppBar(brightness, isDark, res),

                // ── Content Area ──
                Expanded(
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _entryCtrl,
                      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
                    )),
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _entryCtrl,
                          curve: const Interval(0.2, 0.7),
                        ),
                      ),
                      child: _buildContent(brightness, isDark, res),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Info Panel Overlay ──
          if (_showInfo)
            _buildInfoOverlay(brightness, isDark, res),
        ],
      ),
    );
  }

  Widget _buildAppBar(Brightness brightness, bool isDark, Resource res) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryCtrl, curve: const Interval(0, 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(
          children: [
            // Back
            _AppBarButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
              brightness: brightness,
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    res.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(brightness),
                    ),
                  ),
                  if (res.uploader != null)
                    Text(
                      'by ${res.uploader!.fullName}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textTertiary(brightness),
                      ),
                    ),
                ],
              ),
            ),
            // Actions
            _AppBarButton(
              icon: Icons.info_outline_rounded,
              onTap: () => setState(() => _showInfo = !_showInfo),
              brightness: brightness,
              isActive: _showInfo,
            ),
            const SizedBox(width: 6),
            _AppBarButton(
              icon: Icons.share_rounded,
              onTap: _share,
              brightness: brightness,
            ),
            const SizedBox(width: 6),
            if (_isPdf) ...[
              const SizedBox(width: 6),
              _AppBarButton(
                icon: Icons.zoom_in_rounded,
                onTap: () => _pdfViewerController.zoomLevel += 0.5,
                brightness: brightness,
              ),
              const SizedBox(width: 6),
              _AppBarButton(
                icon: Icons.zoom_out_rounded,
                onTap: () => _pdfViewerController.zoomLevel -= 0.5,
                brightness: brightness,
              ),
            ],
            const SizedBox(width: 6),
            _AppBarButton(
              icon: Icons.open_in_new_rounded,
              onTap: _openExternal,
              brightness: brightness,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Brightness brightness, bool isDark, Resource res) {
    if (_isImage) {
      return _buildImageViewer(brightness, isDark, res);
    } else if (_isPdf) {
      return _buildPdfViewer(brightness, isDark, res);
    } else if (_isLink) {
      return _buildLinkViewer(brightness, isDark, res);
    } else {
      return _buildFileViewer(brightness, isDark, res);
    }
  }

  // ─── Image Viewer ──────────────────────────────────────────────────────────

  Widget _buildImageViewer(Brightness brightness, bool isDark, Resource res) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt(brightness),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            ),
            child: CachedNetworkImage(
              imageUrl: res.fileUrl!,
              fit: BoxFit.contain,
              placeholder: (_, __) => _buildLoadingState(brightness),
              errorWidget: (_, __, ___) => _buildErrorState(brightness),
            ),
          ),
        ),
      ),
    );
  }

  // ─── PDF Viewer ────────────────────────────────────────────────────────────

  Widget _buildPdfViewer(Brightness brightness, bool isDark, Resource res) {
    if (res.fileUrl == null) {
      return _buildErrorState(brightness);
    }

    // If PDF failed to load, show fallback
    if (_pdfLoadFailed) {
      return _buildPdfFallback(brightness, isDark, res);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt(brightness),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
          border: Border.all(
            color: AppTheme.border(brightness).withOpacity(0.5),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
          child: Stack(
            children: [
              SfPdfViewer.network(
                res.fileUrl!,
                controller: _pdfViewerController,
                canShowScrollHead: false,
                canShowScrollStatus: false,
                onDocumentLoaded: (_) {
                  if (mounted) setState(() => _pdfLoading = false);
                },
                onDocumentLoadFailed: (_) {
                  if (mounted) {
                    setState(() {
                      _pdfLoadFailed = true;
                      _pdfLoading = false;
                    });
                  }
                },
              ),
              if (_pdfLoading)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 2,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading PDF…',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textTertiary(brightness),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfFallback(Brightness brightness, bool isDark, Resource res) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt(brightness),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(
                color: const Color(0xFFEF4444).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, child) {
                    final rotation = math.sin(_pulseCtrl.value * math.pi) * 0.05;
                    return Transform.rotate(angle: rotation, child: child);
                  },
                  child: Container(
                    width: 88,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PDF',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  res.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(brightness),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'PDF preview is not available in the browser.\nOpen externally to view this file.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textTertiary(brightness),
                    height: 1.5,
                  ),
                ),
                if (res.fileSizeFormatted.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    res.fileSizeFormatted,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textTertiary(brightness),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _openExternal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withOpacity(0.3),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.open_in_new_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Open PDF',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Link Viewer ───────────────────────────────────────────────────────────

  Widget _buildLinkViewer(Brightness brightness, bool isDark, Resource res) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Link card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt(brightness),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(
                color: AppColors.info.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.info.withOpacity(isDark ? 0.15 : 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, child) {
                    final scale = 1.0 + 0.06 * _pulseCtrl.value;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.info.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.link_rounded, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  res.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(brightness),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  res.linkUrl ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.info,
                  ),
                ),
                if (res.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    res.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary(brightness),
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: _openExternal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.info.withOpacity(0.3),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.open_in_browser_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Open Link',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Generic File Viewer ───────────────────────────────────────────────────

  Widget _buildFileViewer(Brightness brightness, bool isDark, Resource res) {
    final typeColors = _getTypeColors(res.fileType);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt(brightness),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(
                color: typeColors[0].withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, child) {
                    final rotation = math.sin(_pulseCtrl.value * math.pi) * 0.05;
                    return Transform.rotate(angle: rotation, child: child);
                  },
                  child: Container(
                    width: 88,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: typeColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: typeColors[0].withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getFileIcon(res.fileType),
                          color: Colors.white,
                          size: 36,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (res.fileType ?? 'FILE').toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  res.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(brightness),
                  ),
                ),
                const SizedBox(height: 8),
                if (res.fileSizeFormatted.isNotEmpty)
                  Text(
                    res.fileSizeFormatted,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textTertiary(brightness),
                    ),
                  ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _openExternal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: typeColors),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      boxShadow: [
                        BoxShadow(
                          color: typeColors[0].withOpacity(0.3),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.download_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Open File',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Info Overlay ──────────────────────────────────────────────────────────

  Widget _buildInfoOverlay(Brightness brightness, bool isDark, Resource res) {
    return GestureDetector(
      onTap: () => setState(() => _showInfo = false),
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, // absorb taps
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _entryCtrl,
                curve: Curves.easeOutCubic,
              )),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface.withOpacity(0.96)
                      : AppColors.lightSurface.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  border: Border.all(
                    color: AppTheme.border(brightness).withOpacity(0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textTertiary(brightness).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Resource Details',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(brightness),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info rows
                    _InfoRow(
                      icon: Icons.title_rounded,
                      label: 'Title',
                      value: res.title,
                      brightness: brightness,
                    ),
                    if (res.description.isNotEmpty)
                      _InfoRow(
                        icon: Icons.description_outlined,
                        label: 'Description',
                        value: res.description,
                        brightness: brightness,
                      ),
                    if (res.uploader != null)
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Uploaded by',
                        value: res.uploader!.fullName,
                        brightness: brightness,
                      ),
                    _InfoRow(
                      icon: Icons.access_time_rounded,
                      label: 'Uploaded',
                      value: timeago.format(res.createdAt),
                      brightness: brightness,
                    ),
                    if (res.fileType != null)
                      _InfoRow(
                        icon: Icons.insert_drive_file_outlined,
                        label: 'Type',
                        value: res.fileType!.toUpperCase(),
                        brightness: brightness,
                      ),
                    if (res.fileSizeFormatted.isNotEmpty)
                      _InfoRow(
                        icon: Icons.data_usage_rounded,
                        label: 'Size',
                        value: res.fileSizeFormatted,
                        brightness: brightness,
                      ),

                    // Tags
                    if (res.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: res.tags.map((tag) {
                          final color = AppColors.getTagColor(tag);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusFull),
                              border: Border.all(
                                color: color.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(Brightness brightness) {
    return Center(
      child: CircularProgressIndicator(
        color: AppColors.accent,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildErrorState(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            size: 48,
            color: AppTheme.textTertiary(brightness),
          ),
          const SizedBox(height: 12),
          Text(
            'Failed to load',
            style: GoogleFonts.inter(
              color: AppTheme.textTertiary(brightness),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getTypeColors(String? fileType) {
    switch (fileType?.toLowerCase()) {
      case 'pdf':
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case 'doc':
      case 'docx':
        return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
      case 'ppt':
      case 'pptx':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case 'xls':
      case 'xlsx':
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case 'zip':
      case 'rar':
        return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
      default:
        return [AppColors.accent, AppColors.accentLight];
    }
  }

  IconData _getFileIcon(String? fileType) {
    switch (fileType?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}

// ─── App Bar Button ──────────────────────────────────────────────────────────

class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Brightness brightness;
  final bool isActive;

  const _AppBarButton({
    required this.icon,
    required this.onTap,
    required this.brightness,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accent.withOpacity(0.15)
              : AppTheme.surfaceAlt(brightness),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppColors.accent.withOpacity(0.3)
                : AppTheme.border(brightness).withOpacity(0.5),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive
              ? AppColors.accent
              : AppTheme.textSecondary(brightness),
        ),
      ),
    );
  }
}

// ─── Info Row ────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Brightness brightness;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.textTertiary(brightness)),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textTertiary(brightness),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary(brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated builder helper ─────────────────────────────────────────────────

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
