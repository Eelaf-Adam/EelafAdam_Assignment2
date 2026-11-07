import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/user_role.dart';
import '../providers/auth_providers.dart';
import '../providers/incident_providers.dart';
import '../theme/app_theme.dart';
import '../utils/incident_filters.dart';
import '../utils/sign_out.dart';
import 'home_tab.dart';
import 'incident_list_tab.dart';
import 'profile_tab.dart';
import 'report_form_screen.dart';

/// Students: Home, Reports, Add, Profile. Staff: Home, Portal, Profile.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  // 0 = Home, 1 = Reports/Portal, 2 = Profile
  int _pageIndex = 0;

  void _openReports([ReportFilter filter = ReportFilter.all]) {
    ref.read(reportFilterProvider.notifier).select(filter);
    setState(() => _pageIndex = 1);
  }

  Future<void> _openReportForm(AppUser profile) async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ReportFormScreen(profile: profile)),
    );
    if (submitted == true && mounted) _openReports();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    // Keeps the selected filter alive while signed in.
    ref.watch(reportFilterProvider);

    return profileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          _ProfileProblem(message: 'Could not load your profile.\n$error'),
      data: (profile) {
        if (profile == null) {
          return const _ProfileProblem(
            message: 'Your profile was not found. Please sign in again.',
          );
        }
        return _buildShell(profile);
      },
    );
  }

  Widget _buildShell(AppUser profile) {
    final isStaff = profile.role == UserRole.staff;

    final pages = [
      HomeTab(profile: profile, onOpenReports: _openReports),
      IncidentListTab(profile: profile),
      ProfileTab(profile: profile),
    ];

    // For students "Add" opens the form rather than a page,
    // so the bar and page indexes differ.
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      isStaff
          ? const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Portal',
            )
          : const NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description),
              label: 'Reports',
            ),
      if (!isStaff) const NavigationDestination(icon: _AddIcon(), label: 'Add'),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];

    final selectedBarIndex = (!isStaff && _pageIndex == 2) ? 3 : _pageIndex;

    return Scaffold(
      body: IndexedStack(index: _pageIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedBarIndex,
        destinations: destinations,
        onDestinationSelected: (barIndex) {
          if (!isStaff && barIndex == 2) {
            _openReportForm(profile);
            return;
          }
          setState(() {
            _pageIndex = (!isStaff && barIndex == 3) ? 2 : barIndex;
          });
        },
      ),
    );
  }
}

class _AddIcon extends StatelessWidget {
  const _AddIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 22),
    );
  }
}

class _ProfileProblem extends ConsumerWidget {
  const _ProfileProblem({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => signOutToStart(context, ref),
                child: const Text('Back to sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
