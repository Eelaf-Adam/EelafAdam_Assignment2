import '../models/incident.dart';

/// Filter pills on the Reports tab, also used by the Home summary cards.
enum ReportFilter {
  all('All'),
  today('Today'),
  pending('Pending', IncidentStatus.pending),
  underReview('Under Review', IncidentStatus.underReview),
  inProgress('In Progress', IncidentStatus.inProgress),
  resolved('Resolved', IncidentStatus.resolved);

  const ReportFilter(this.label, [this.status]);

  final String label;

  /// Null for All and Today.
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

/// Case-insensitive search over type, location, description,
/// ID, reporter and status.
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
