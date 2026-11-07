import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../models/user_role.dart';
import '../providers/incident_providers.dart';
import '../theme/app_theme.dart';
import '../utils/incident_filters.dart';
import '../widgets/empty_state.dart';
import '../widgets/incident_card.dart';
import '../widgets/user_avatar.dart';
import 'incident_details_screen.dart';

/// Home tab (same design for both roles): greeting, summary cards,
/// search bar and the most recent reports.
class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({
    super.key,
    required this.profile,
    required this.onOpenReports,
  });

  final AppUser profile;

  /// Opens the Reports / Portal tab with the given filter selected.
  final ValueChanged<ReportFilter> onOpenReports;

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  static const _recentCount = 5;

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isStaff => widget.profile.role == UserRole.staff;

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(visibleIncidentsProvider);
    final firstName = widget.profile.fullName.split(' ').first;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // ---- Greeting ----
          Row(
            children: [
              UserAvatar(role: widget.profile.role, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, $firstName',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _isStaff
                          ? 'Manage campus incidents'
                          : 'Track your campus reports',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              RoleBadge(role: widget.profile.role),
            ],
          ),
          const SizedBox(height: 24),

          ...incidentsAsync.when(
            loading: () => const [
              Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (error, _) => [
              EmptyState(
                icon: Icons.error_outline,
                title: 'Could not load reports',
                message: '$error',
              ),
            ],
            data: _buildContent,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContent(List<Incident> incidents) {
    final isSearching = _query.trim().isNotEmpty;
    final results = filterIncidents(incidents, query: _query);
    final shown = isSearching ? results : results.take(_recentCount).toList();
    final now = DateTime.now();

    int countFor(ReportFilter filter) =>
        incidents.where((i) => filter.matches(i, now)).length;

    // Two rows of three summary cards. Tapping one opens that list.
    final stats = <_StatInfo>[
      _StatInfo(
        filter: ReportFilter.today,
        label: _isStaff ? 'Received today' : 'Submitted today',
        icon: Icons.today,
        color: AppColors.accent,
        count: countFor(ReportFilter.today),
      ),
      _StatInfo(
        filter: ReportFilter.all,
        label: _isStaff ? 'All reports' : 'My reports',
        icon: Icons.folder_open,
        color: AppColors.textPrimary,
        count: incidents.length,
      ),
      for (final status in IncidentStatus.values)
        _StatInfo(
          filter: ReportFilter.forStatus(status),
          label: status.label,
          icon: status.icon,
          color: status.color,
          count: countFor(ReportFilter.forStatus(status)),
        ),
    ];

    return [
      // ---- Overview ----
      _SectionHeader(
        title: 'Overview',
        onSeeAll: () => widget.onOpenReports(ReportFilter.all),
      ),
      const SizedBox(height: 8),
      for (var row = 0; row < stats.length; row += 3) ...[
        if (row > 0) const SizedBox(height: 10),
        Row(
          children: [
            for (var i = row; i < row + 3; i++) ...[
              if (i > row) const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  info: stats[i],
                  onTap: () => widget.onOpenReports(stats[i].filter),
                ),
              ),
            ],
          ],
        ),
      ],
      const SizedBox(height: 24),

      // ---- Search ----
      TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search by type, location, ID...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: isSearching
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
        ),
      ),
      const SizedBox(height: 24),

      // ---- Recent reports / search results ----
      _SectionHeader(
        title: isSearching ? 'Results (${results.length})' : 'Recent reports',
        onSeeAll: (isSearching || incidents.isEmpty)
            ? null
            : () => widget.onOpenReports(ReportFilter.all),
      ),
      const SizedBox(height: 8),
      if (shown.isEmpty)
        isSearching
            ? const EmptyState(
                icon: Icons.search_off,
                title: 'No matching reports',
                message: 'Try a different word, like "water" or "Food Court".',
              )
            : EmptyState(
                icon: Icons.inbox_outlined,
                title: 'No reports yet',
                message: _isStaff
                    ? 'New incident reports from students will appear here.'
                    : 'Tap the + button below to report an incident.',
              )
      else
        for (final incident in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IncidentCard(
              incident: incident,
              showReporter: _isStaff,
              highlight: _query,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => IncidentDetailsScreen(
                    incidentId: incident.id,
                    profile: widget.profile,
                  ),
                ),
              ),
            ),
          ),
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text('See all')),
      ],
    );
  }
}

class _StatInfo {
  const _StatInfo({
    required this.filter,
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
  });

  final ReportFilter filter;
  final String label;
  final IconData icon;
  final Color color;
  final int count;
}

/// Summary card: a count with its label. Tapping opens the matching list.
class _StatCard extends StatelessWidget {
  const _StatCard({required this.info, required this.onTap});

  final _StatInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(info.icon, color: info.color, size: 20),
              const SizedBox(height: 8),
              Text(
                '${info.count}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                info.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
