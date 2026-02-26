import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';
import '../../config/supabase_config.dart';
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
  PlatformFile? _pickedFile;
  final List<String> _selectedTags = [];
  bool _isLoading = false;

  static const _availableTags = [
    'notes',
    'pyq',
    'slides',
    'links',
    'important',
    'assignment',
    'lab',
    'other',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isFile && _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      await context.read<ResourceProvider>().addResource(
            subjectId: widget.subjectId,
            title: _titleCtrl.text.trim(),
            userId: userId,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            tags: _selectedTags,
            linkUrl: _isFile ? null : _linkCtrl.text.trim(),
            fileName: _isFile ? _pickedFile?.name : null,
            fileBytes: _isFile ? _pickedFile?.bytes : null,
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
          'Add Resource',
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
              // Type toggle
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt(brightness),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.border(brightness)),
                ),
                child: Row(
                  children: [
                    _TypeTab(
                      label: 'Upload File',
                      icon: Icons.upload_file_rounded,
                      isActive: _isFile,
                      brightness: brightness,
                      onTap: () => setState(() => _isFile = true),
                    ),
                    _TypeTab(
                      label: 'Add Link',
                      icon: Icons.link_rounded,
                      isActive: !_isFile,
                      brightness: brightness,
                      onTap: () => setState(() => _isFile = false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // File or Link input
              AnimatedSwitcher(
                duration: AppTheme.animMedium,
                child: _isFile
                    ? _FileUploadArea(
                        key: const ValueKey('file'),
                        pickedFile: _pickedFile,
                        brightness: brightness,
                        onPick: _pickFile,
                      )
                    : TextFormField(
                        key: const ValueKey('link'),
                        controller: _linkCtrl,
                        style: TextStyle(
                          color: AppTheme.textPrimary(brightness),
                        ),
                        decoration: const InputDecoration(
                          labelText: 'URL *',
                          hintText: 'https://...',
                          prefixIcon: Icon(Icons.link_rounded),
                        ),
                        validator: (v) {
                          if (!_isFile &&
                              (v == null || v.trim().isEmpty)) {
                            return 'URL is required';
                          }
                          return null;
                        },
                      ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _titleCtrl,
                style: TextStyle(color: AppTheme.textPrimary(brightness)),
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'Resource title',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                style: TextStyle(color: AppTheme.textPrimary(brightness)),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional description',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Tags
              Text(
                'TAGS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppTheme.textTertiary(brightness),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return TagChip(
                    tag: tag,
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              AnimatedButton(
                label: 'Upload Resource',
                icon: Icons.cloud_upload_outlined,
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Brightness brightness;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppTheme.animFast,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                    ? Colors.white
                    : AppTheme.textTertiary(brightness),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? Colors.white
                      : AppTheme.textTertiary(brightness),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileUploadArea extends StatelessWidget {
  final PlatformFile? pickedFile;
  final Brightness brightness;
  final VoidCallback onPick;

  const _FileUploadArea({
    super.key,
    required this.pickedFile,
    required this.brightness,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: AnimatedContainer(
        duration: AppTheme.animMedium,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt(brightness),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: pickedFile != null
                ? AppColors.success.withValues(alpha: 0.5)
                : AppTheme.border(brightness),
            width: pickedFile != null ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              pickedFile != null
                  ? Icons.check_circle_outline_rounded
                  : Icons.cloud_upload_outlined,
              size: 40,
              color: pickedFile != null
                  ? AppColors.success
                  : AppTheme.textTertiary(brightness),
            ),
            const SizedBox(height: 12),
            Text(
              pickedFile != null
                  ? pickedFile!.name
                  : 'Tap to select a file',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: pickedFile != null
                    ? AppTheme.textPrimary(brightness)
                    : AppTheme.textTertiary(brightness),
              ),
            ),
            if (pickedFile != null) ...[
              const SizedBox(height: 4),
              Text(
                '${(pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textTertiary(brightness),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
