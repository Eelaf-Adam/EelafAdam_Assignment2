import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../screens/role_selection_screen.dart';

Future<void> signOutToStart(BuildContext context, WidgetRef ref) async {
  await ref.read(authServiceProvider).signOut();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    (route) => false,
  );
}
