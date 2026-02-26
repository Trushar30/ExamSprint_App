import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
