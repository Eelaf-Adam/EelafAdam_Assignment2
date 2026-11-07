import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar.dart';
import '../widgets/loading_button.dart';
import 'home_screen.dart';
import 'role_selection_screen.dart';

/// Shown until the user clicks the link in their verification email.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isChecking = false;
  bool _isResending = false;

  Future<void> _checkVerified() async {
    setState(() => _isChecking = true);
    try {
      final verified =
          await ref.read(authServiceProvider).checkEmailVerified();
      if (!mounted) return;

      if (verified) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        showMessage(
          context,
          'Not verified yet. Check your inbox (and spam folder).',
        );
      }
    } catch (_) {
      if (mounted) showMessage(context, 'Could not check. Please try again.');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      await ref.read(authServiceProvider).sendVerificationEmail();
      if (mounted) showMessage(context, 'Verification email sent again.');
    } on AuthException catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _useDifferentAccount() async {
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.read(authServiceProvider).currentUser?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 48,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Verify your email',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  style: const TextStyle(color: AppColors.textSecondary),
                  children: [
                    const TextSpan(text: 'We sent a verification link to\n'),
                    TextSpan(
                      text: email,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(
                      text: '\n\nOpen it, then come back and tap the button below.',
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              LoadingButton(
                label: "I've verified my email",
                isLoading: _isChecking,
                onPressed: _checkVerified,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isResending ? null : _resend,
                child: Text(_isResending ? 'Sending...' : 'Resend email'),
              ),
              TextButton(
                onPressed: _useDifferentAccount,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                child: const Text('Use a different account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
