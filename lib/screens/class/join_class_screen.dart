import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/class_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/animated_button.dart';
import 'class_dashboard_screen.dart';

class JoinClassScreen extends StatefulWidget {
  const JoinClassScreen({super.key});

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _digitControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLookingUp = false;
  bool _isJoining = false;
  bool _classFound = false;
  dynamic _foundClass;

  late AnimationController _slideCtrl;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    _slideCtrl.dispose();
    super.dispose();
  }

  String get _code => _digitControllers.map((c) => c.text).join();

  Future<void> _lookupClass() async {
    if (_code.length != 6) return;
    setState(() => _isLookingUp = true);

    try {
      final cls = await context.read<ClassProvider>().lookupClassByCode(_code);
      if (cls != null) {
        setState(() {
          _classFound = true;
          _foundClass = cls;
          _isLookingUp = false;
        });
        _slideCtrl.forward();
      } else {
        setState(() {
          _classFound = false;
          _foundClass = null;
          _isLookingUp = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Class not found')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _classFound = false;
        _foundClass = null;
        _isLookingUp = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Class not found: $e')),
        );
      }
    }
  }

  Future<void> _joinClass() async {
    if (_foundClass == null) return;
    setState(() => _isJoining = true);
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    try {
      final cp = context.read<ClassProvider>();
      final success = await cp.joinClass(
        classId: _foundClass!.id,
        userId: userId,
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ClassDashboardScreen(
              classId: _foundClass!.id,
              className: _foundClass!.name,
            ),
          ),
        );
      } else if (mounted) {
        setState(() => _isJoining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(cp.error ?? 'Could not join class')),
        );
      }
    } catch (e) {
      setState(() => _isJoining = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (_code.length == 6) {
      _lookupClass();
    } else {
      setState(() {
        _classFound = false;
        _foundClass = null;
      });
      _slideCtrl.reverse();
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
          'Join Class',
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
          children: [
            const SizedBox(height: 32),
            Icon(
              Icons.login_rounded,
              size: 52,
              color: AppColors.accent,
            ),
            const SizedBox(height: 20),
            Text(
              'Enter Class Code',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(brightness),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask your admin for the 6-character code',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textTertiary(brightness),
              ),
            ),
            const SizedBox(height: 36),

            // Digit boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                return Container(
                  width: 48,
                  height: 58,
                  margin: EdgeInsets.only(
                    right: i < 5 ? 8 : 0,
                    left: i == 3 ? 8 : 0,
                  ),
                  child: TextField(
                    controller: _digitControllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    onChanged: (v) => _onDigitChanged(i, v),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary(brightness),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                      filled: true,
                      fillColor: AppTheme.surfaceAlt(brightness),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide(
                          color: AppTheme.border(brightness),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: const BorderSide(
                          color: AppColors.accent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            if (_isLookingUp)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.accent),
              ),

            // Class preview
            if (_classFound && _foundClass != null) ...[
              const SizedBox(height: 24),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _slideCtrl,
                  curve: Curves.easeOutCubic,
                )),
                child: FadeTransition(
                  opacity: _slideCtrl,
                  child: GlassCard(
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
                                  _foundClass!.name
                                      .substring(
                                          0,
                                          _foundClass!.name.length >= 2
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
                                    _foundClass!.name,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary(
                                          brightness),
                                    ),
                                  ),
                                  if (_foundClass!.university != null)
                                    Text(
                                      _foundClass!.university!,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppTheme.textTertiary(
                                            brightness),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_foundClass!.description.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            _foundClass!.description,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textSecondary(brightness),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        AnimatedButton(
                          label: 'Join Class',
                          icon: Icons.login_rounded,
                          isLoading: _isJoining,
                          color: AppColors.success,
                          onPressed: _joinClass,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
