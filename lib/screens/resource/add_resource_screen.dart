import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/resource_provider.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/tag_chip.dart';

class AddResourceScreen extends StatefulWidget {
  final String subjectId;
  const AddResourceScreen({super.key, required this.subjectId});

  @override
  State<AddResourceScreen> createState() => _AddResourceScreenState();
}

class _AddResourceScreenState extends State<AddResourceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  bool _isFile = true;
  String? _fileName;
  Uint8List? _fileBytes;
  final List<String> _selectedTags = [];
  final _predefinedTags = ['Notes', 'PYQ', 'Slides', 'Links', 'Important', 'Assignment', 'Lab'];

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); _linkCtrl.dispose(); super.dispose(); }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() { _fileName = result.files.first.name; _fileBytes = result.files.first.bytes; });
      if (_titleCtrl.text.isEmpty) _titleCtrl.text = _fileName!.split('.').first;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isFile && _fileBytes == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick a file'))); return; }
    if (!_isFile && _linkCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a URL'))); return; }

    final userId = context.read<AuthProvider>().userId!;
    final rp = context.read<ResourceProvider>();
    final result = await rp.addResource(
      subjectId: widget.subjectId, title: _titleCtrl.text.trim(), userId: userId,
      description: _descCtrl.text.trim(),
      linkUrl: _isFile ? null : _linkCtrl.text.trim(),
      fileName: _isFile ? _fileName : null,
      fileBytes: _isFile ? _fileBytes : null,
      tags: _selectedTags,
    );
    if (result != null && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<ResourceProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(8, 8, 16, 0), child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary), onPressed: () => Navigator.pop(context)),
            Text('Add Resource', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ])),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Type toggle
            Container(
              decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              child: Row(children: [
                Expanded(child: GestureDetector(onTap: () => setState(() => _isFile = true), child: AnimatedContainer(duration: AppTheme.animFast, padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: _isFile ? AppTheme.accent : Colors.transparent, borderRadius: BorderRadius.circular(AppTheme.radiusMd)), child: Center(child: Text('📄 File', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _isFile ? Colors.white : AppTheme.textTertiary)))))),
                Expanded(child: GestureDetector(onTap: () => setState(() => _isFile = false), child: AnimatedContainer(duration: AppTheme.animFast, padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: !_isFile ? AppTheme.accent : Colors.transparent, borderRadius: BorderRadius.circular(AppTheme.radiusMd)), child: Center(child: Text('🔗 Link', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: !_isFile ? Colors.white : AppTheme.textTertiary)))))),
              ]),
            ),
            const SizedBox(height: 20),

            // File picker or URL
            if (_isFile) GestureDetector(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(border: Border.all(color: AppTheme.border, style: BorderStyle.solid), borderRadius: BorderRadius.circular(AppTheme.radiusLg), color: AppTheme.surfaceLight),
                child: Column(children: [
                  Icon(_fileName != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined, size: 40, color: _fileName != null ? AppTheme.success : AppTheme.textTertiary),
                  const SizedBox(height: 8),
                  Text(_fileName ?? 'Tap to pick a file', style: GoogleFonts.inter(fontSize: 14, color: _fileName != null ? AppTheme.textPrimary : AppTheme.textTertiary)),
                ]),
              ),
            )
            else TextFormField(controller: _linkCtrl, decoration: const InputDecoration(labelText: 'URL', hintText: 'https://', prefixIcon: Icon(Icons.link, color: AppTheme.textTertiary)), style: const TextStyle(color: AppTheme.textPrimary)),
            const SizedBox(height: 16),

            TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title *', hintText: 'Resource title', prefixIcon: Icon(Icons.title, color: AppTheme.textTertiary)), style: const TextStyle(color: AppTheme.textPrimary), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 16),

            TextFormField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', hintText: 'Optional', prefixIcon: Icon(Icons.description_outlined, color: AppTheme.textTertiary)), style: const TextStyle(color: AppTheme.textPrimary)),
            const SizedBox(height: 20),

            // Tags
            Text('Tags', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: _predefinedTags.map((t) => TagChip(tag: t, selected: _selectedTags.contains(t), onTap: () => setState(() { if (_selectedTags.contains(t)) _selectedTags.remove(t); else _selectedTags.add(t); }))).toList()),
            const SizedBox(height: 32),

            AnimatedButton(label: 'Upload Resource', isLoading: rp.isUploading, onPressed: _submit, icon: Icons.upload_rounded),
          ])))),
        ])),
      ),
    );
  }
}
