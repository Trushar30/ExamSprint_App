import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/ai_service.dart';
import '../../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _hasApiKey = false;
  bool _isApiKeyVisible = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final key = await AiService.getApiKey();
    if (mounted) {
      setState(() {
        _hasApiKey = key != null && key.isNotEmpty;
        if (_hasApiKey) {
          _apiKeyController.text = key!;
        }
      });
    }
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;

    setState(() => _isSaving = true);
    await AiService.setApiKey(key);
    if (mounted) {
      setState(() {
        _hasApiKey = true;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text('API key saved successfully!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _removeApiKey() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove API Key?'),
        content: const Text(
          'AI Playground features will stop working until a new key is added.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AiService.removeApiKey();
      if (mounted) {
        setState(() {
          _hasApiKey = false;
          _apiKeyController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('API key removed'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.bgGradient(brightness)),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Text(
                'Settings',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(brightness),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Customize your experience',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textTertiary(brightness),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Appearance ───────────────────────────
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
                    const SizedBox(height: 28),

                    // ─── Account ──────────────────────────────
                    _SectionTitle('Account', brightness),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: auth.currentUser?.email ?? '—',
                            brightness: brightness,
                          ),
                          Divider(
                            color: AppTheme.border(brightness).withOpacity(0.3),
                            height: 1,
                          ),
                          _SettingsTile(
                            icon: Icons.lock_outline_rounded,
                            label: 'Change Password',
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.textTertiary(brightness),
                              size: 20,
                            ),
                            brightness: brightness,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password reset email sent'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ─── AI Playground ────────────────────────
                    _SectionTitle('AI Playground', brightness),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status indicator
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.auto_awesome,
                                    color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Gemini API Key',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary(brightness),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _hasApiKey
                                                ? AppColors.success
                                                : AppColors.error,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _hasApiKey
                                              ? 'Connected'
                                              : 'Not configured',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: _hasApiKey
                                                ? AppColors.success
                                                : AppColors.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // API key input
                          TextField(
                            controller: _apiKeyController,
                            obscureText: !_isApiKeyVisible,
                            style: GoogleFonts.robotoMono(
                              fontSize: 13,
                              color: AppTheme.textPrimary(brightness),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Paste your Gemini API key here...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textTertiary(brightness),
                              ),
                              filled: true,
                              fillColor: AppTheme.surfaceAlt(brightness),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppTheme.border(brightness),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.accent,
                                  width: 1.5,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isApiKeyVisible
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  size: 18,
                                  color: AppTheme.textTertiary(brightness),
                                ),
                                onPressed: () => setState(
                                    () => _isApiKeyVisible = !_isApiKeyVisible),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isSaving ? null : _saveApiKey,
                                  icon: _isSaving
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.save_rounded, size: 18),
                                  label: Text(_isSaving ? 'Saving...' : 'Save Key'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              if (_hasApiKey) ...[
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 44,
                                  child: OutlinedButton(
                                    onPressed: _removeApiKey,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(color: AppColors.error),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Icon(Icons.delete_outline, size: 18),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Get API key link
                          InkWell(
                            onTap: () async {
                              final uri = Uri.parse(AiService.apiKeyUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.info.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.key_rounded,
                                      color: AppColors.info, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Get a free Gemini API Key',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.info,
                                          ),
                                        ),
                                        Text(
                                          'aistudio.google.com/apikey',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppColors.info.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.open_in_new_rounded,
                                      color: AppColors.info, size: 16),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Info text
                          Text(
                            '🔒 Your key is stored locally on this device only. It is never shared with us.',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textTertiary(brightness),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ─── Notifications ────────────────────────
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
                    const SizedBox(height: 28),

                    // ─── About ────────────────────────────────
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
                    const SizedBox(height: 28),

                    // ─── Danger Zone ──────────────────────────
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────

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

// ─── Theme Option ─────────────────────────────────────────────────────────────

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

// ─── Settings Tile ────────────────────────────────────────────────────────────

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

// ─── Switch Tile ──────────────────────────────────────────────────────────────

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
