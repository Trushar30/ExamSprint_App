import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subject_provider.dart';
import '../../widgets/animated_button.dart';

class CreateSubjectScreen extends StatefulWidget {
  final String classId;
  const CreateSubjectScreen({super.key, required this.classId});

  @override
  State<CreateSubjectScreen> createState() => _CreateSubjectScreenState();
}

class _CreateSubjectScreenState extends State<CreateSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _profCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() { _nameCtrl.dispose(); _codeCtrl.dispose(); _profCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().userId!;
    final result = await context.read<SubjectProvider>().createSubject(
      classId: widget.classId, name: _nameCtrl.text.trim(), userId: userId,
      code: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
      professor: _profCtrl.text.trim().isEmpty ? null : _profCtrl.text.trim(),
      description: _descCtrl.text.trim(),
    );
    if (result != null && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SubjectProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(8, 8, 16, 0), child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary), onPressed: () => Navigator.pop(context)),
            Text('Add Subject', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ])),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Subject Details', style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text('Add a subject so everyone can share resources', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textTertiary)),
            const SizedBox(height: 28),
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Subject Name *', hintText: 'e.g., Data Structures', prefixIcon: Icon(Icons.book_outlined, color: AppTheme.textTertiary)), style: const TextStyle(color: AppTheme.textPrimary), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextFormField(controller: _codeCtrl, decoration: const InputDecoration(labelText: 'Subject Code', hintText: 'e.g., CS301', prefixIcon: Icon(Icons.tag, color: AppTheme.textTertiary)), style: const TextStyle(color: AppTheme.textPrimary))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _profCtrl, decoration: const InputDecoration(labelText: 'Professor', hintText: 'Prof. Name', prefixIcon: Icon(Icons.person_outline, color: AppTheme.textTertiary)), style: const TextStyle(color: AppTheme.textPrimary))),
            ]),
            const SizedBox(height: 16),
            TextFormField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', hintText: 'Optional description', prefixIcon: Icon(Icons.description_outlined, color: AppTheme.textTertiary)), style: const TextStyle(color: AppTheme.textPrimary)),
            const SizedBox(height: 32),
            AnimatedButton(label: 'Create Subject', isLoading: sp.isLoading, onPressed: _submit, icon: Icons.add_rounded),
          ])))),
        ])),
      ),
    );
  }
}
