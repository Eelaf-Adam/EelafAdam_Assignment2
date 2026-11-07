import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_role.dart';
import '../theme/app_theme.dart';
import '../widgets/rapport_logo.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selectedRole;

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SignUpScreen(role: _selectedRole!)),
    );
  }

  void _openSignIn() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SignInScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Center(child: RapportLogo(fontSize: 22)),
              const SizedBox(height: 40),
              Text(
                'Your Role?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose the role that best fits you. '
                'Rapport will adapt to your role.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  for (final role in UserRole.values) ...[
                    if (role != UserRole.values.first)
                      const SizedBox(width: 16),
                    Expanded(
                      child: _RoleCard(
                        role: role,
                        isSelected: _selectedRole == role,
                        onTap: () => setState(() => _selectedRole = role),
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _selectedRole == null ? null : _continue,
                child: const Text('Continue'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: GoogleFonts.poppins(color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: _openSignIn,
                    child: Text(
                      'Sign in',
                      style: GoogleFonts.poppins(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 84,
              height: 84,
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(role.avatarPath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              role.label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
