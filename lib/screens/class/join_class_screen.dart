import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/class_provider.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/glass_card.dart';
import 'class_dashboard_screen.dart';

class JoinClassScreen extends StatefulWidget {
  const JoinClassScreen({super.key});

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final _codeController = TextEditingController();
  dynamic _previewClass;
  bool _isLooking = false;
  bool _isJoining = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _lookupClass() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a 6-character class code')),
      );
      return;
    }

    setState(() => _isLooking = true);

    final classProvider = context.read<ClassProvider>();
    final result = await classProvider.lookupClassByCode(code);

    setState(() {
      _previewClass = result;
      _isLooking = false;
    });

    if (result == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No class found with this code')),
      );
    }
  }

  Future<void> _joinClass() async {
    if (_previewClass == null) return;

    setState(() => _isJoining = true);

    final userId = context.read<AuthProvider>().userId!;
    final classProvider = context.read<ClassProvider>();

    final success = await classProvider.joinClass(
      classId: _previewClass!.id,
      userId: userId,
    );

    setState(() => _isJoining = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ClassDashboardScreen(
            classId: _previewClass!.id,
            className: _previewClass!.name,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(classProvider.error ?? 'Failed to join class'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Join Class',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter Class Code',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ask your classmate for the 6-character code',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Code input
                      TextFormField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: 8,
                        ),
                        decoration: InputDecoration(
                          hintText: '• • • • • •',
                          hintStyle: GoogleFonts.spaceGrotesk(
                            fontSize: 28,
                            color: AppTheme.textTertiary,
                            letterSpacing: 8,
                          ),
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            borderSide:
                                const BorderSide(color: AppTheme.accent, width: 2),
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceLight,
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        onChanged: (value) {
                          if (value.length == 6) {
                            _lookupClass();
                          } else {
                            setState(() => _previewClass = null);
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      if (_isLooking)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(color: AppTheme.accent),
                          ),
                        ),

                      // Preview card
                      if (_previewClass != null)
                        AnimatedOpacity(
                          opacity: _previewClass != null ? 1 : 0,
                          duration: AppTheme.animMedium,
                          child: GlassCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _previewClass!.name
                                              .substring(
                                                  0,
                                                  _previewClass!.name.length >= 2
                                                      ? 2
                                                      : 1)
                                              .toUpperCase(),
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _previewClass!.name,
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          if (_previewClass!.semester != null ||
                                              _previewClass!.department != null)
                                            Text(
                                              [
                                                _previewClass!.semester,
                                                _previewClass!.department
                                              ]
                                                  .where((e) => e != null)
                                                  .join(' • '),
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: AppTheme.textTertiary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (_previewClass!.description.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _previewClass!.description,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                                if (_previewClass!.university != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.school_outlined,
                                          size: 14,
                                          color: AppTheme.textTertiary),
                                      const SizedBox(width: 4),
                                      Text(
                                        _previewClass!.university!,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppTheme.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 20),
                                AnimatedButton(
                                  label: 'Join Class',
                                  isLoading: _isJoining,
                                  onPressed: _joinClass,
                                  icon: Icons.login_rounded,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
