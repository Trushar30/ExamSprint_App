import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/animated_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;

  @override
  void initState() {
    super.initState();
    final p = context.read<AuthProvider>().profile;
    _nameCtrl = TextEditingController(text: p?.fullName ?? '');
    _usernameCtrl = TextEditingController(text: p?.username ?? '');
    _bioCtrl = TextEditingController(text: p?.bio ?? '');
  }

  @override
  void dispose() { _nameCtrl.dispose(); _usernameCtrl.dispose(); _bioCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    await context.read<AuthProvider>().updateProfile(fullName: _nameCtrl.text.trim(), username: _usernameCtrl.text.trim(), bio: _bioCtrl.text.trim());
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = auth.profile;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(8, 8, 16, 0), child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary), onPressed: () => Navigator.pop(context)),
            Text('Profile', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const Spacer(),
            if (!_isEditing) IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.accent), onPressed: () => setState(() => _isEditing = true)),
          ])),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
            // Avatar
            Container(width: 96, height: 96, decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(24), boxShadow: AppTheme.glowShadow), child: Center(child: Text(p?.initials ?? '?', style: GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white)))),
            const SizedBox(height: 16),
            if (!_isEditing) ...[
              Text(p?.fullName ?? 'Student', style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              if (p?.username != null) Text('@${p!.username}', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textTertiary)),
              if (p?.bio != null && p!.bio!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(p.bio!, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary))),
              const SizedBox(height: 8),
              Text(auth.currentUser?.email ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textTertiary)),
            ],
            if (_isEditing) ...[
              const SizedBox(height: 16),
              GlassCard(padding: const EdgeInsets.all(20), child: Column(children: [
                TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline, color: AppTheme.textTertiary)), style: const TextStyle(color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                TextFormField(controller: _usernameCtrl, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.alternate_email, color: AppTheme.textTertiary)), style: const TextStyle(color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                TextFormField(controller: _bioCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio', prefixIcon: Icon(Icons.info_outline, color: AppTheme.textTertiary)), style: const TextStyle(color: AppTheme.textPrimary)),
                const SizedBox(height: 20),
                AnimatedButton(label: 'Save', isLoading: auth.isLoading, onPressed: _save, icon: Icons.check_rounded),
                const SizedBox(height: 8),
                AnimatedButton(label: 'Cancel', outlined: true, onPressed: () => setState(() => _isEditing = false)),
              ])),
            ],
            const SizedBox(height: 32),
            // Sign out
            GlassCard(
              onTap: () async {
                await auth.signOut();
                if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.logout_rounded, color: AppTheme.error),
                const SizedBox(width: 8),
                Text('Sign Out', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.error)),
              ]),
            ),
          ]))),
        ])),
      ),
    );
  }
}
