import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/class_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';

class ClassSettingsScreen extends StatelessWidget {
  final String classId;

  const ClassSettingsScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final cp = context.watch<ClassProvider>();
    final cls = cp.currentClass;
    final userId = context.read<AuthProvider>().userId;

    return Scaffold(
      backgroundColor: AppTheme.bg(brightness),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: AppTheme.textPrimary(brightness)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Class Settings',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary(brightness),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Info ──────────────────────────────────────────────
            Text(
              'CLASS INFORMATION',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppTheme.textTertiary(brightness),
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Name',
                    value: cls?.name ?? '—',
                    brightness: brightness,
                  ),
                  Divider(color: AppTheme.border(brightness).withOpacity(0.3), height: 20),
                  _InfoRow(
                    label: 'Code',
                    value: cls?.code ?? '—',
                    brightness: brightness,
                    valueColor: AppColors.accent,
                  ),
                  if (cls?.semester != null) ...[
                    Divider(color: AppTheme.border(brightness).withOpacity(0.3), height: 20),
                    _InfoRow(
                      label: 'Semester',
                      value: cls!.semester!,
                      brightness: brightness,
                    ),
                  ],
                  if (cls?.department != null) ...[
                    Divider(color: AppTheme.border(brightness).withOpacity(0.3), height: 20),
                    _InfoRow(
                      label: 'Department',
                      value: cls!.department!,
                      brightness: brightness,
                    ),
                  ],
                  if (cls?.university != null) ...[
                    Divider(color: AppTheme.border(brightness).withOpacity(0.3), height: 20),
                    _InfoRow(
                      label: 'University',
                      value: cls!.university!,
                      brightness: brightness,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ─── Danger Zone ───────────────────────────────────────
            Text(
              'DANGER ZONE',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              onTap: () async {
                final action = cls?.isAdmin == true ? 'Delete' : 'Leave';
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('$action Class?'),
                    content: Text(
                      cls?.isAdmin == true
                          ? 'This will permanently delete this class and all its data.'
                          : 'You will lose access to all resources in this class.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        child: Text(action),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await cp.leaveClass(
                    classId: classId,
                    userId: userId ?? '',
                  );
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                }
              },
              child: Row(
                children: [
                  Icon(
                    cls?.isAdmin == true
                        ? Icons.delete_outline_rounded
                        : Icons.logout_rounded,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    cls?.isAdmin == true ? 'Delete Class' : 'Leave Class',
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
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Brightness brightness;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.brightness,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textSecondary(brightness),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.textPrimary(brightness),
          ),
        ),
      ],
    );
  }
}
