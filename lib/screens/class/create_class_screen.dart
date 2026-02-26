import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme.dart';
import '../../providers/class_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/animated_button.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _semesterCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _uniCtrl = TextEditingController();

  int _currentStep = 0;
  bool _isCreated = false;
  String? _classCode;
  bool _isLoading = false;

  late AnimationController _successCtrl;
  late Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _semesterCtrl.dispose();
    _deptCtrl.dispose();
    _uniCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed {
    if (_currentStep == 0) return _nameCtrl.text.trim().isNotEmpty;
    return true;
  }

  void _nextStep() {
    if (_currentStep < 1) {
      setState(() => _currentStep++);
    } else {
      _createClass();
    }
  }

  Future<void> _createClass() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    try {
      final cp = context.read<ClassProvider>();
      await cp.createClass(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        semester: _semesterCtrl.text.trim().isEmpty ? null : _semesterCtrl.text.trim(),
        department: _deptCtrl.text.trim().isEmpty ? null : _deptCtrl.text.trim(),
        university: _uniCtrl.text.trim().isEmpty ? null : _uniCtrl.text.trim(),
        userId: userId,
      );

      if (mounted && cp.currentClass != null) {
        setState(() {
          _isCreated = true;
          _classCode = cp.currentClass!.code;
          _isLoading = false;
        });
        _successCtrl.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary(brightness)),
          onPressed: () => Navigator.pop(context, _isCreated),
        ),
        title: _isCreated
            ? null
            : Text(
                'Create Class',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(brightness),
                ),
              ),
      ),
      body: _isCreated ? _buildSuccess(brightness) : _buildForm(brightness),
    );
  }

  Widget _buildForm(Brightness brightness) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            Row(
              children: List.generate(2, (i) {
                final isActive = i <= _currentStep;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 1 ? 8 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isActive
                          ? AppColors.accent
                          : AppTheme.border(brightness),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              'Step ${_currentStep + 1} of 2',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textTertiary(brightness),
              ),
            ),
            const SizedBox(height: 28),

            AnimatedSwitcher(
              duration: AppTheme.animMedium,
              child: _currentStep == 0
                  ? _Step1(
                      key: const ValueKey(0),
                      nameCtrl: _nameCtrl,
                      descCtrl: _descCtrl,
                      brightness: brightness,
                      onChanged: () => setState(() {}),
                    )
                  : _Step2(
                      key: const ValueKey(1),
                      semesterCtrl: _semesterCtrl,
                      deptCtrl: _deptCtrl,
                      uniCtrl: _uniCtrl,
                      brightness: brightness,
                    ),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: AnimatedButton(
                      label: 'Back',
                      outlined: true,
                      onPressed: () => setState(() => _currentStep--),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: AnimatedButton(
                    label: _currentStep < 1 ? 'Next' : 'Create Class',
                    icon: _currentStep < 1 ? Icons.arrow_forward_rounded : Icons.check_rounded,
                    isLoading: _isLoading,
                    onPressed: _canProceed ? _nextStep : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess(Brightness brightness) {
    return Center(
      child: ScaleTransition(
        scale: _successScale,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppTheme.glowShadow(),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 52,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Class Created!',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(brightness),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Share this code with your classmates',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textTertiary(brightness),
                ),
              ),
              const SizedBox(height: 28),
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                child: Text(
                  _classCode ?? '',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                    letterSpacing: 8,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedButton(
                    label: 'Copy',
                    icon: Icons.copy_rounded,
                    width: 140,
                    outlined: true,
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: _classCode ?? ''),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied!')),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  AnimatedButton(
                    label: 'Share',
                    icon: Icons.share_rounded,
                    width: 140,
                    onPressed: () {
                      Share.share(
                        'Join my class on ExamSprint!\nCode: $_classCode',
                      );
                    },
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

class _Step1 extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final Brightness brightness;
  final VoidCallback onChanged;

  const _Step1({
    super.key,
    required this.nameCtrl,
    required this.descCtrl,
    required this.brightness,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Info',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary(brightness),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Give your class a name and description',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textTertiary(brightness),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: nameCtrl,
          onChanged: (_) => onChanged(),
          style: TextStyle(color: AppTheme.textPrimary(brightness)),
          decoration: const InputDecoration(
            labelText: 'Class Name *',
            hintText: 'e.g., Data Structures & Algorithms',
            prefixIcon: Icon(Icons.class_outlined),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: descCtrl,
          style: TextStyle(color: AppTheme.textPrimary(brightness)),
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Brief description of the class',
            prefixIcon: Icon(Icons.description_outlined),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}

class _Step2 extends StatelessWidget {
  final TextEditingController semesterCtrl;
  final TextEditingController deptCtrl;
  final TextEditingController uniCtrl;
  final Brightness brightness;

  const _Step2({
    super.key,
    required this.semesterCtrl,
    required this.deptCtrl,
    required this.uniCtrl,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary(brightness),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Optional details to help organize',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textTertiary(brightness),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: semesterCtrl,
          style: TextStyle(color: AppTheme.textPrimary(brightness)),
          decoration: const InputDecoration(
            labelText: 'Semester',
            hintText: 'e.g., Fall 2025',
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: deptCtrl,
          style: TextStyle(color: AppTheme.textPrimary(brightness)),
          decoration: const InputDecoration(
            labelText: 'Department',
            hintText: 'e.g., Computer Science',
            prefixIcon: Icon(Icons.account_balance_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: uniCtrl,
          style: TextStyle(color: AppTheme.textPrimary(brightness)),
          decoration: const InputDecoration(
            labelText: 'University',
            hintText: 'e.g., MIT',
            prefixIcon: Icon(Icons.school_outlined),
          ),
        ),
      ],
    );
  }
}
