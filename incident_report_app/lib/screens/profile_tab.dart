import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/user_role.dart';
import '../providers/incident_providers.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../utils/sign_out.dart';
import '../widgets/user_avatar.dart';

/// Profile tab: who is signed in, a few account details, and sign out.
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key, required this.profile});

  final AppUser profile;

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to use Rapport.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await signOutToStart(context, ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStaff = profile.role == UserRole.staff;
    final reportCount = ref.watch(visibleIncidentsProvider).value?.length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text(
            'Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 28),
          Center(child: UserAvatar(role: profile.role, size: 96)),
          const SizedBox(height: 16),
          Text(
            profile.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Center(child: RoleBadge(role: profile.role)),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: profile.email,
                ),
                const _RowDivider(),
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Role',
                  value: profile.role.label,
                ),
                const _RowDivider(),
                _InfoRow(
                  icon: Icons.description_outlined,
                  label: isStaff ? 'Total campus reports' : 'Reports submitted',
                  value: reportCount?.toString() ?? '...',
                ),
                if (profile.createdAt != null) ...[
                  const _RowDivider(),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Member since',
                    value: formatDate(profile.createdAt!),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context, ref),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 52,
      color: AppColors.textSecondary.withValues(alpha: 0.15),
    );
  }
}
