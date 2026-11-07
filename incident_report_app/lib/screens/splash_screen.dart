import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../widgets/rapport_logo.dart';
import 'main_shell.dart';
import 'role_selection_screen.dart';
import 'verify_email_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goToNextScreen();
  }

  Future<void> _goToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = ref.read(authServiceProvider).currentUser;

    final Widget next;
    if (user == null) {
      next = const RoleSelectionScreen();
    } else if (!user.emailVerified) {
      next = const VerifyEmailScreen();
    } else {
      next = const MainShell();
    }

    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: RapportLogo(fontSize: 40)));
  }
}
