import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
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
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _profCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');
      await context.read<SubjectProvider>().createSubject(
            classId: widget.classId,
            name: _nameCtrl.text.trim(),
            userId: userId,
            code: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
            professor: _profCtrl.text.trim().isEmpty ? null : _profCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

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
          'Add Subject',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary(brightness),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subject Details',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(brightness),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add a new subject to your class',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textTertiary(brightness),
                ),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _nameCtrl,
                style: TextStyle(color: AppTheme.textPrimary(brightness)),
                decoration: const InputDecoration(
                  labelText: 'Subject Name *',
                  hintText: 'e.g., Data Structures',
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeCtrl,
                style: TextStyle(color: AppTheme.textPrimary(brightness)),
                decoration: const InputDecoration(
                  labelText: 'Subject Code',
                  hintText: 'e.g., CS201',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _profCtrl,
                style: TextStyle(color: AppTheme.textPrimary(brightness)),
                decoration: const InputDecoration(
                  labelText: 'Professor',
                  hintText: 'e.g., Dr. Smith',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: TextStyle(color: AppTheme.textPrimary(brightness)),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional description',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              AnimatedButton(
                label: 'Create Subject',
                icon: Icons.add_rounded,
                isLoading: _isLoading,
                onPressed: _create,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
