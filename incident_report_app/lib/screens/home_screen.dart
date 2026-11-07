import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../theme/app_theme.dart';
import 'role_selection_screen.dart';

/// Temporary home screen to test the login flow.
/// Will be replaced by the student / staff incident screens.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context, ref),
          ),
        ],
      ),
      body: Center(
        // AsyncValue handles the three states: loading, error and data.
        child: profile.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text('Could not load profile: $error'),
          data: (user) {
            if (user == null) {
              return const Text('Profile not found.');
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.accent,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: ClipOval(child: Image.asset(user.role.avatarPath)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome, ${user.fullName}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role.label,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
