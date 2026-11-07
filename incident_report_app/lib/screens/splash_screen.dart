import 'package:flutter/material.dart';

import '../widgets/rapport_logo.dart';
import 'role_selection_screen.dart';

/// First screen: shows the Rapport logo briefly, then moves on.
/// Later, this is where we will check if the user is already signed in.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goToNextScreen();
  }

  Future<void> _goToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    // The widget may have been removed while we were waiting.
    if (!mounted) return;

    // pushReplacement removes the splash, so "back" doesn't return to it.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: RapportLogo(fontSize: 40)),
    );
  }
}
