import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/class_provider.dart';
import '../../widgets/glass_card.dart';

class ClassSettingsScreen extends StatelessWidget {
  final String classId;
  const ClassSettingsScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ClassProvider>();
    final cls = cp.currentClass;
    final userId = context.read<AuthProvider>().userId!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(8, 8, 16, 0), child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary), onPressed: () => Navigator.pop(context)),
            Text('Class Settings', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ])),
          Expanded(child: ListView(padding: const EdgeInsets.all(24), children: [
            if (cls != null) ...[
              GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Class Info', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                _InfoRow(label: 'Name', value: cls.name),
                _InfoRow(label: 'Code', value: cls.code),
                if (cls.semester != null) _InfoRow(label: 'Semester', value: cls.semester!),
                if (cls.department != null) _InfoRow(label: 'Department', value: cls.department!),
                if (cls.university != null) _InfoRow(label: 'University', value: cls.university!),
              ])),
              const SizedBox(height: 16),
            ],
            // Leave class
            GlassCard(
              onTap: () async {
                final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.surface,
                  title: Text(cls?.isAdmin == true ? 'Delete Class?' : 'Leave Class?', style: const TextStyle(color: AppTheme.textPrimary)),
                  content: Text(cls?.isAdmin == true ? 'This will permanently delete the class and all its data.' : 'You will lose access to all resources in this class.', style: const TextStyle(color: AppTheme.textSecondary)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: AppTheme.error), child: Text(cls?.isAdmin == true ? 'Delete' : 'Leave')),
                  ],
                ));
                if (confirm == true && context.mounted) {
                  await cp.leaveClass(classId: classId, userId: userId);
                  if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              child: Row(children: [
                Icon(cls?.isAdmin == true ? Icons.delete_outline_rounded : Icons.logout_rounded, color: AppTheme.error),
                const SizedBox(width: 12),
                Text(cls?.isAdmin == true ? 'Delete Class' : 'Leave Class', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.error)),
              ]),
            ),
          ])),
        ])),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
      SizedBox(width: 100, child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textTertiary))),
      Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary))),
    ]));
  }
}
