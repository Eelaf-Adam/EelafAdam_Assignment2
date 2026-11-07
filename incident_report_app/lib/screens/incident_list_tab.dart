import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../models/user_role.dart';
import '../providers/incident_providers.dart';
import '../theme/app_theme.dart';
import '../utils/incident_filters.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_pill.dart';
import '../widgets/incident_card.dart';
import 'incident_details_screen.dart';

/// The full list of reports with search and filter pills.
/// Students see this as "My Reports", staff as the "Report Portal".
class IncidentListTab extends ConsumerStatefulWidget {
  const IncidentListTab({super.key, required this.profile});

  final AppUser profile;

  @override
  ConsumerState<IncidentListTab> createState() => _IncidentListTabState();
}

class _IncidentListTabState extends ConsumerState<IncidentListTab> {
  final _searchController = TextEditingController();
  String _query = '';

  bool get _isStaff => widget.profile.role == UserRole.staff;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(visibleIncidentsProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isStaff ? 'Report Portal' : 'My Reports',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _isStaff
                      ? 'Review reports and update their status.'
                      : 'Tap a report to see its details and progress.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: _isStaff
                        ? 'Search by type, location, student...'
                        : 'Search by type, location, ID...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty
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
              ],
            ),
          ),
          Expanded(
            child: incidentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Could not load reports',
                message: '$error',
              ),
              data: _buildList,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Incident> incidents) {
    final filter = ref.watch(reportFilterProvider);
    final filtered =
        filterIncidents(incidents, query: _query, filter: filter);
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---- Filter pills (scroll sideways on small screens) ----
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              for (final option in ReportFilter.values) ...[
                if (option != ReportFilter.values.first)
                  const SizedBox(width: 8),
                FilterPill(
                  label:
                      '${option.label} (${incidents.where((i) => option.matches(i, now)).length})',
                  isSelected: filter == option,
                  onTap: () =>
                      ref.read(reportFilterProvider.notifier).select(option),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? SingleChildScrollView(
                  child: EmptyState(
                    icon: _query.isNotEmpty
                        ? Icons.search_off
                        : Icons.inbox_outlined,
                    title: _query.isNotEmpty
                        ? 'No matching reports'
                        : filter == ReportFilter.all
                            ? 'No reports yet'
                            : 'No reports in "${filter.label}"',
                    message: _isStaff
                        ? 'Reports matching this filter will appear here.'
                        : 'Reports you submit will appear here.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final incident = filtered[index];
                    return IncidentCard(
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
                    );
                  },
                ),
        ),
      ],
    );
  }
}
