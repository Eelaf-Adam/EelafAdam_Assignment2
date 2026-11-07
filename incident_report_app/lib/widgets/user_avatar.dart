import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../theme/app_theme.dart';

/// The role avatar inside a cyan circle (same style as the role cards).
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.role, this.size = 48});

  final UserRole role;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.06),
      decoration: const BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
      child: ClipOval(child: Image.asset(role.avatarPath, fit: BoxFit.cover)),
    );
  }
}

/// A small cyan pill showing "Student" or "Staff".
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.label,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
