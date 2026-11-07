import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_role.dart';
import '../providers/auth_providers.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/loading_button.dart';
import '../widgets/rapport_logo.dart';
import 'sign_in_screen.dart';
import 'verify_email_screen.dart';

/// Account creation for the role picked on the previous screen.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key, required this.role});

  final UserRole role;

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    // Run every field's validator; stop if any fails.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signUp(
            fullName: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            role: widget.role,
          );
      if (!mounted) return;

      // Clear the whole stack so "back" can't return to the sign-up form.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: RapportLogo(fontSize: 22)),
                const SizedBox(height: 28),
                Text(
                  'Create your ${role.label} account',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use your @${role.emailDomain} email address.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),
                AppTextField(
                  controller: _nameController,
                  label: 'Full name',
                  icon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.fullName,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _emailController,
                  label: 'ALU email',
                  hint: 'name@${role.emailDomain}',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => Validators.emailForRole(v, role),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _confirmController,
                  label: 'Confirm password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _signUp(),
                  validator: (v) => v != _passwordController.text
                      ? 'Passwords do not match'
                      : null,
                ),
                const SizedBox(height: 32),
                LoadingButton(
                  label: 'Sign up',
                  isLoading: _isLoading,
                  onPressed: _signUp,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account?',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                      ),
                      child: const Text(
                        'Sign in',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
