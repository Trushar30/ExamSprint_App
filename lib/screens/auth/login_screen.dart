import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/glass_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;

  late AnimationController _bgCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _bgCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() => _isSignUp = !_isSignUp);
    _fadeCtrl.reset();
    _fadeCtrl.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    bool success;
    if (_isSignUp) {
      success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
      );
    } else {
      success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.error ?? 'Something went wrong',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.error.withOpacity(0.9),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (context, child) {
          final angle = _bgCtrl.value * 2 * math.pi;
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(
                  math.cos(angle) * 0.3,
                  math.sin(angle) * 0.3,
                ),
                radius: 1.5,
                colors: isDark
                    ? [
                        const Color(0xFF1A0A2E),
                        const Color(0xFF0B0B14),
                        const Color(0xFF0A0A12),
                      ]
                    : [
                        const Color(0xFFEDE7F6),
                        const Color(0xFFF7F7FC),
                        const Color(0xFFF0F0F8),
                      ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: AppTheme.glowShadow(),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ExamSprint',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(brightness),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: AppTheme.animMedium,
                      child: Text(
                        _isSignUp
                            ? 'Create your account'
                            : 'Welcome back, student',
                        key: ValueKey(_isSignUp),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textTertiary(brightness),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Segmented toggle
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt(brightness),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: AppTheme.border(brightness),
                        ),
                      ),
                      child: Row(
                        children: [
                          _SegmentTab(
                            label: 'Sign In',
                            isActive: !_isSignUp,
                            onTap: () {
                              if (_isSignUp) _toggleMode();
                            },
                            brightness: brightness,
                          ),
                          _SegmentTab(
                            label: 'Sign Up',
                            isActive: _isSignUp,
                            onTap: () {
                              if (!_isSignUp) _toggleMode();
                            },
                            brightness: brightness,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form Card
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Name (signup)
                            AnimatedSize(
                              duration: AppTheme.animMedium,
                              curve: Curves.easeInOut,
                              child: _isSignUp
                                  ? Column(
                                      children: [
                                        _AnimatedField(
                                          controller: _nameController,
                                          label: 'Full Name',
                                          hint: 'Enter your name',
                                          icon: Icons.person_outline,
                                          brightness: brightness,
                                          validator: (v) {
                                            if (_isSignUp &&
                                                (v == null ||
                                                    v.trim().isEmpty)) {
                                              return 'Name is required';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            _AnimatedField(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'you@example.com',
                              icon: Icons.email_outlined,
                              brightness: brightness,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                if (!v.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            _AnimatedField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                              brightness: brightness,
                              obscureText: _obscurePassword,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color:
                                      AppTheme.textTertiary(brightness),
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password is required';
                                }
                                if (v.length < 6) {
                                  return 'Min 6 characters';
                                }
                                return null;
                              },
                            ),

                            if (!_isSignUp) ...[
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Forgot password?',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ),
                            ] else
                              const SizedBox(height: 24),

                            AnimatedButton(
                              label:
                                  _isSignUp ? 'Create Account' : 'Sign In',
                              isLoading: authProvider.isLoading,
                              onPressed: _submit,
                              icon: _isSignUp
                                  ? Icons.person_add_outlined
                                  : Icons.login_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Social placeholder
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppTheme.border(brightness),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textTertiary(brightness),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppTheme.border(brightness),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialButton(
                          icon: Icons.g_mobiledata_rounded,
                          brightness: brightness,
                        ),
                        const SizedBox(width: 16),
                        _SocialButton(
                          icon: Icons.apple_rounded,
                          brightness: brightness,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Segment Tab ──────────────────────────────────────────────────────────────

class _SegmentTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Brightness brightness;

  const _SegmentTab({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppTheme.animFast,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? Colors.white
                  : AppTheme.textTertiary(brightness),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Animated Text Field ──────────────────────────────────────────────────────

class _AnimatedField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Brightness brightness;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _AnimatedField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.brightness,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: AppTheme.textPrimary(brightness)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textTertiary(brightness)),
        suffixIcon: suffix,
      ),
      validator: validator,
    );
  }
}

// ─── Social Button ────────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Brightness brightness;

  const _SocialButton({required this.icon, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt(brightness),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border(brightness)),
      ),
      child: Icon(
        icon,
        color: AppTheme.textSecondary(brightness),
        size: 28,
      ),
    );
  }
}

// ─── AnimatedBuilder ──────────────────────────────────────────────────────────

class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _AnimBuilder(listenable: animation, builder: builder, child: child);
  }
}

class _AnimBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const _AnimBuilder({
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) => builder(context, child);
}
