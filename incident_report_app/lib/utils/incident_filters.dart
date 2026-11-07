import '../models/incident.dart';

/// The filters shown as pills on the Reports / Portal tab,
/// and opened by tapping the summary cards on Home.
enum ReportFilter {
  all('All'),
  today('Today'),
  pending('Pending', IncidentStatus.pending),
  underReview('Under Review', IncidentStatus.underReview),
  inProgress('In Progress', IncidentStatus.inProgress),
  resolved('Resolved', IncidentStatus.resolved);

  const ReportFilter(this.label, [this.status]);

  final String label;

  /// The status this filter keeps, or null for "All" / "Today".
  final IncidentStatus? status;

  static ReportFilter forStatus(IncidentStatus status) =>
      values.firstWhere((f) => f.status == status);

  bool matches(Incident incident, DateTime now) {
    switch (this) {
      case ReportFilter.all:
        return true;
      case ReportFilter.today:
        return isSameDay(incident.createdAt, now);
      default:
        return incident.status == status;
    }
  }
}

bool isSameDay(DateTime a, DateTime b) {
  final x = a.toLocal();
  final y = b.toLocal();
  return x.year == y.year && x.month == y.month && x.day == y.day;
}

/// Filters reports by a [filter] and a search [query].
/// The query matches type, location, description, ID, reporter or status,
/// ignoring upper/lower case.
List<Incident> filterIncidents(
  List<Incident> incidents, {
  String query = '',
  ReportFilter filter = ReportFilter.all,
  DateTime? now,
}) {
  final q = query.trim().toLowerCase();
  final today = now ?? DateTime.now();

  return incidents.where((incident) {
    if (!filter.matches(incident, today)) return false;
    if (q.isEmpty) return true;

    final searchable = [
      incident.typeLabel,
      incident.locationLabel,
      incident.description,
      incident.code,
      incident.reporterName,
      incident.status.label,
    ];
    return searchable.any((field) => field.toLowerCase().contains(q));
  }).toList();
}
