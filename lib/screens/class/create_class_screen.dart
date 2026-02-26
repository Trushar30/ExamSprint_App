import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/class_provider.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/glass_card.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _semesterController = TextEditingController();
  final _deptController = TextEditingController();
  final _uniController = TextEditingController();

  String? _createdCode;
  bool _isCreated = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _semesterController.dispose();
    _deptController.dispose();
    _uniController.dispose();
    super.dispose();
  }

  Future<void> _createClass() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthProvider>().userId!;
    final classProvider = context.read<ClassProvider>();

    final result = await classProvider.createClass(
      name: _nameController.text.trim(),
      userId: userId,
      description: _descController.text.trim(),
      semester: _semesterController.text.trim().isEmpty
          ? null
          : _semesterController.text.trim(),
      department: _deptController.text.trim().isEmpty
          ? null
          : _deptController.text.trim(),
      university: _uniController.text.trim().isEmpty
          ? null
          : _uniController.text.trim(),
    );

    if (result != null) {
      setState(() {
        _createdCode = result.code;
        _isCreated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final classProvider = context.watch<ClassProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context, _isCreated),
                    ),
                    Text(
                      'Create Class',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _isCreated
                      ? _SuccessView(
                          code: _createdCode!,
                          className: _nameController.text.trim(),
                          onDone: () => Navigator.pop(context, true),
                        )
                      : Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Set up your class',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Create a class and invite your classmates',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 28),

                              _buildField(
                                controller: _nameController,
                                label: 'Class Name *',
                                hint: 'e.g., 6IT, CSE-A, BCA Sem 4',
                                icon: Icons.class_outlined,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Class name is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              _buildField(
                                controller: _descController,
                                label: 'Description',
                                hint: 'Brief description of this class',
                                icon: Icons.description_outlined,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildField(
                                      controller: _semesterController,
                                      label: 'Semester',
                                      hint: 'e.g., Sem 6',
                                      icon: Icons.calendar_today_outlined,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildField(
                                      controller: _deptController,
                                      label: 'Department',
                                      hint: 'e.g., IT',
                                      icon: Icons.business_outlined,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              _buildField(
                                controller: _uniController,
                                label: 'University',
                                hint: 'e.g., CHARUSAT',
                                icon: Icons.school_outlined,
                              ),
                              const SizedBox(height: 32),

                              AnimatedButton(
                                label: 'Create Class',
                                isLoading: classProvider.isLoading,
                                onPressed: _createClass,
                                icon: Icons.add_rounded,
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textTertiary),
      ),
      style: const TextStyle(color: AppTheme.textPrimary),
      validator: validator,
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String code;
  final String className;
  final VoidCallback onDone;

  const _SuccessView({
    required this.code,
    required this.className,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            size: 48,
            color: AppTheme.success,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Class Created! 🎉',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '"$className" is ready. Share the code below!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textTertiary,
          ),
        ),
        const SizedBox(height: 32),
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'CLASS CODE',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textTertiary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                code,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionChip(
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied!')),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _ActionChip(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text: 'Join my class "$className" on ExamSprint!\n\nClass Code: $code\n\nDownload ExamSprint to get all resources in one place! ⚡',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        AnimatedButton(
          label: 'Go to Dashboard',
          onPressed: onDone,
          icon: Icons.arrow_forward_rounded,
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
