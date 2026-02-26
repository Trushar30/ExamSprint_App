import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/resource.dart';
import '../../services/resource_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/animated_button.dart';
import '../resource/resource_reader_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;

  late AnimationController _editCtrl;

  List<Resource> _userResources = [];
  bool _loadingResources = true;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().profile;
    _nameCtrl = TextEditingController(text: profile?.fullName ?? '');
    _usernameCtrl = TextEditingController(text: profile?.username ?? '');
    _bioCtrl = TextEditingController(text: profile?.bio ?? '');

    _editCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _loadUserResources();
  }

  Future<void> _loadUserResources() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id;
    if (userId == null) {
      setState(() => _loadingResources = false);
      return;
    }

    try {
      final resources = await ResourceService().getUserResources(userId);
      if (mounted) {
        setState(() {
          _userResources = resources;
          _loadingResources = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingResources = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _editCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (_isEditing) {
      _editCtrl.reverse();
    } else {
      _editCtrl.forward();
    }
    setState(() => _isEditing = !_isEditing);
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthProvider>();
    await auth.updateProfile(
      fullName: _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
    );
    _toggleEdit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.bgGradient(brightness)),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary(brightness),
                    ),
                  ),
                  GestureDetector(
                    onTap: _isEditing ? _saveProfile : _toggleEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _isEditing
                            ? AppColors.accent
                            : AppColors.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isEditing ? 'Save' : 'Edit',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _isEditing
                              ? Colors.white
                              : AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ─── Avatar ──────────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: AppTheme.glowShadow(),
                      ),
                      child: Center(
                        child: Text(
                          profile?.initials ?? '?',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.surface(brightness),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.border(brightness),
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (!_isEditing) ...[
                Center(
                  child: Text(
                    profile?.fullName ?? 'Unknown',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(brightness),
                    ),
                  ),
                ),
                if (profile?.username != null)
                  Center(
                    child: Text(
                      '@${profile!.username}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                if (profile?.bio.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: Text(
                        profile!.bio,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondary(brightness),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 28),

              // ─── Stats Row ───────────────────────────────────────
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      value: '—',
                      label: 'Classes',
                      brightness: brightness,
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppTheme.border(brightness),
                    ),
                    _StatItem(
                      value: _loadingResources ? '…' : '${_userResources.length}',
                      label: 'Resources',
                      brightness: brightness,
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppTheme.border(brightness),
                    ),
                    _StatItem(
                      value: '—',
                      label: 'Messages',
                      brightness: brightness,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Edit Form ───────────────────────────────────────
              if (_isEditing) ...[
                GlassCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        style: TextStyle(
                          color: AppTheme.textPrimary(brightness),
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameCtrl,
                        style: TextStyle(
                          color: AppTheme.textPrimary(brightness),
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bioCtrl,
                        maxLines: 3,
                        style: TextStyle(
                          color: AppTheme.textPrimary(brightness),
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          prefixIcon: Icon(Icons.info_outline),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedButton(
                  label: 'Cancel',
                  outlined: true,
                  onPressed: () {
                    _nameCtrl.text = profile?.fullName ?? '';
                    _usernameCtrl.text = profile?.username ?? '';
                    _bioCtrl.text = profile?.bio ?? '';
                    _toggleEdit();
                  },
                ),
              ],

              // ─── Profile Info Sections ───────────────────────────
              if (!_isEditing) ...[
                _ProfileSection(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: auth.currentUser?.email ?? '—',
                  brightness: brightness,
                ),
                const SizedBox(height: 12),
                _ProfileSection(
                  icon: Icons.calendar_today_outlined,
                  label: 'Joined',
                  value: profile != null
                      ? '${profile.createdAt.day}/${profile.createdAt.month}/${profile.createdAt.year}'
                      : '—',
                  brightness: brightness,
                ),
                const SizedBox(height: 32),

                // ═════════════════════════════════════════════════════
                //  MY RESOURCES SECTION
                // ═════════════════════════════════════════════════════
                _SectionTitle('My Resources', brightness),
                const SizedBox(height: 12),
                _buildMyResources(brightness, isDark),
                const SizedBox(height: 32),

                // ═════════════════════════════════════════════════════
                //  SETTINGS SECTION
                // ═════════════════════════════════════════════════════

                // ─── Appearance ─────────────────────────────────────
                _SectionTitle('Appearance', brightness),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    children: [
                      _ThemeOption(
                        icon: Icons.dark_mode_rounded,
                        label: 'Dark',
                        isSelected: themeProvider.themeMode == ThemeMode.dark,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                        brightness: brightness,
                      ),
                      Divider(
                        color: AppTheme.border(brightness).withOpacity(0.3),
                        height: 1,
                      ),
                      _ThemeOption(
                        icon: Icons.light_mode_rounded,
                        label: 'Light',
                        isSelected: themeProvider.themeMode == ThemeMode.light,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                        brightness: brightness,
                      ),
                      Divider(
                        color: AppTheme.border(brightness).withOpacity(0.3),
                        height: 1,
                      ),
                      _ThemeOption(
                        icon: Icons.brightness_auto_rounded,
                        label: 'System',
                        isSelected: themeProvider.themeMode == ThemeMode.system,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                        brightness: brightness,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Notifications ──────────────────────────────────
                _SectionTitle('Notifications', brightness),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    children: [
                      _SwitchTile(
                        icon: Icons.notifications_outlined,
                        label: 'Push Notifications',
                        value: true,
                        brightness: brightness,
                        onChanged: (_) {},
                      ),
                      Divider(
                        color: AppTheme.border(brightness).withOpacity(0.3),
                        height: 1,
                      ),
                      _SwitchTile(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Discussion Alerts',
                        value: true,
                        brightness: brightness,
                        onChanged: (_) {},
                      ),
                      Divider(
                        color: AppTheme.border(brightness).withOpacity(0.3),
                        height: 1,
                      ),
                      _SwitchTile(
                        icon: Icons.upload_file_rounded,
                        label: 'New Resource Alerts',
                        value: false,
                        brightness: brightness,
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── About ──────────────────────────────────────────
                _SectionTitle('About', brightness),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        label: 'Version',
                        value: '1.0.0',
                        brightness: brightness,
                      ),
                      Divider(
                        color: AppTheme.border(brightness).withOpacity(0.3),
                        height: 1,
                      ),
                      _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy Policy',
                        trailing: Icon(
                          Icons.open_in_new_rounded,
                          color: AppTheme.textTertiary(brightness),
                          size: 16,
                        ),
                        brightness: brightness,
                      ),
                      Divider(
                        color: AppTheme.border(brightness).withOpacity(0.3),
                        height: 1,
                      ),
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        label: 'Terms of Service',
                        trailing: Icon(
                          Icons.open_in_new_rounded,
                          color: AppTheme.textTertiary(brightness),
                          size: 16,
                        ),
                        brightness: brightness,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Danger Zone ────────────────────────────────────
                _SectionTitle('Danger Zone', brightness),
                const SizedBox(height: 12),
                GlassCard(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sign Out?'),
                        content: const Text(
                          'You will need to sign in again to access your classes.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      }
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sign Out',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── My Resources Widget ──────────────────────────────────────────────────

  Widget _buildMyResources(Brightness brightness, bool isDark) {
    if (_loadingResources) {
      return const SizedBox(
        height: 130,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent,
          ),
        ),
      );
    }

    if (_userResources.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 40,
              color: AppTheme.textTertiary(brightness),
            ),
            const SizedBox(height: 10),
            Text(
              'No resources uploaded yet',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textTertiary(brightness),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Resources you upload will appear here',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textTertiary(brightness).withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _userResources.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final res = _userResources[index];
          return _ResourceCard(
            resource: res,
            brightness: brightness,
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => ResourceReaderScreen(resource: res),
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
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _ResourceCard extends StatefulWidget {
  final Resource resource;
  final Brightness brightness;
  final bool isDark;
  final VoidCallback onTap;

  const _ResourceCard({
    required this.resource,
    required this.brightness,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ResourceCard> createState() => _ResourceCardState();
}

class _ResourceCardState extends State<_ResourceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  List<Color> get _typeColors {
    switch (widget.resource.fileType?.toLowerCase()) {
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
      case 'jpg':
      case 'jpeg':
      case 'png':
        return [const Color(0xFFEC4899), const Color(0xFFDB2777)];
      default:
        if (widget.resource.isLink) {
          return [const Color(0xFF3B82F6), const Color(0xFF60A5FA)];
        }
        return [AppColors.accent, AppColors.accentLight];
    }
  }

  IconData get _typeIcon {
    switch (widget.resource.fileType?.toLowerCase()) {
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
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      default:
        if (widget.resource.isLink) return Icons.link_rounded;
        return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.resource;

    return GestureDetector(
      onTapDown: (_) => _tapCtrl.forward(),
      onTapUp: (_) {
        _tapCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _tapCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _tapCtrl,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - 0.04 * _tapCtrl.value,
            child: child,
          );
        },
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.darkSurfaceAlt
                : AppColors.lightSurfaceAlt,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: AppTheme.border(widget.brightness).withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: _typeColors[0].withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _typeColors),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 12),
              // Title
              Expanded(
                child: Text(
                  res.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(widget.brightness),
                  ),
                ),
              ),
              // Meta
              Row(
                children: [
                  if (res.fileSizeFormatted.isNotEmpty)
                    Text(
                      res.fileSizeFormatted,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppTheme.textTertiary(widget.brightness),
                      ),
                    ),
                  if (res.fileSizeFormatted.isNotEmpty)
                    const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      timeago.format(res.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppTheme.textTertiary(widget.brightness),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Brightness brightness;

  const _StatItem({
    required this.value,
    required this.label,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary(brightness),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textTertiary(brightness),
          ),
        ),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Brightness brightness;

  const _ProfileSection({
    required this.icon,
    required this.label,
    required this.value,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary(brightness)),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary(brightness),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary(brightness),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Section Widgets ────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final Brightness brightness;
  const _SectionTitle(this.title, this.brightness);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppTheme.textTertiary(brightness),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Brightness brightness;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.accent
                  : AppTheme.textSecondary(brightness),
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? AppColors.accent
                      : AppTheme.textPrimary(brightness),
                ),
              ),
            ),
            AnimatedContainer(
              duration: AppTheme.animFast,
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.accent
                      : AppTheme.border(brightness),
                  width: 2,
                ),
                color: isSelected
                    ? AppColors.accent
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final Brightness brightness;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    required this.brightness,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.textSecondary(brightness),
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary(brightness),
                ),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textTertiary(brightness),
                ),
              ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Brightness brightness;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.brightness,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary(brightness), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary(brightness),
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

// ─── Animated Builder helper ─────────────────────────────────────────────────

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
