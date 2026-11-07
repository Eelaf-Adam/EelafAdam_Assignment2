import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../widgets/rapport_logo.dart';
import 'home_screen.dart';
import 'role_selection_screen.dart';
import 'verify_email_screen.dart';

/// First screen: shows the Rapport logo, then sends the user to the
/// right place depending on whether they are already signed in.
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

    // The widget may have been removed while we were waiting.
    if (!mounted) return;

    // Firebase remembers the last signed-in user on this device.
    final user = ref.read(authServiceProvider).currentUser;

    final Widget next;
    if (user == null) {
      next = const RoleSelectionScreen();
    } else if (!user.emailVerified) {
      next = const VerifyEmailScreen();
    } else {
      next = const HomeScreen();
    }

    // pushReplacement removes the splash, so "back" doesn't return to it.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: RapportLogo(fontSize: 40)),
    );
  }
}
