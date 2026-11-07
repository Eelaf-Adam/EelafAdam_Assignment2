import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/loading_button.dart';
import '../widgets/rapport_logo.dart';
import 'main_shell.dart';
import 'verify_email_screen.dart';

/// No role picker: the role comes from the profile saved at sign-up.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authServiceProvider);
      await auth.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;

      final verified = auth.currentUser?.emailVerified ?? false;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              verified ? const MainShell() : const VerifyEmailScreen(),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text;
    if (Validators.email(email) != null) {
      showMessage(context, 'Enter your email above first, then tap again.');
      return;
    }

    try {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      if (mounted) {
        showMessage(context, 'Password reset link sent to ${email.trim()}');
      }
    } on AuthException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'Welcome back',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign in with your ALU email.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),
                AppTextField(
                  controller: _emailController,
                  label: 'ALU email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _signIn(),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Please enter your password'
                      : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _forgotPassword,
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 16),
                LoadingButton(
                  label: 'Sign in',
                  isLoading: _isLoading,
                  onPressed: _signIn,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Sign up',
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
