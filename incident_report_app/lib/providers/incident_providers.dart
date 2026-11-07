import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/incident.dart';
import '../models/user_role.dart';
import '../services/cloudinary_service.dart';
import '../services/incident_service.dart';
import '../utils/incident_filters.dart';
import 'auth_providers.dart';

final incidentServiceProvider = Provider<IncidentService>((ref) {
  return IncidentService(FirebaseFirestore.instance);
});

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

/// Staff see every report, students only their own.
final visibleIncidentsProvider = StreamProvider.autoDispose<List<Incident>>((
  ref,
) {
  final profile = ref.watch(currentUserProfileProvider).value;
  if (profile == null) return const Stream.empty();

  final service = ref.watch(incidentServiceProvider);
  return profile.role == UserRole.staff
      ? service.watchAllIncidents()
      : service.watchMyIncidents(profile.uid);
});

/// Shared so Home can open the Reports tab with a filter already selected.
class ReportFilterNotifier extends Notifier<ReportFilter> {
  @override
  ReportFilter build() => ReportFilter.all;

  void select(ReportFilter filter) => state = filter;
}

final reportFilterProvider =
    NotifierProvider.autoDispose<ReportFilterNotifier, ReportFilter>(
      ReportFilterNotifier.new,
    );

final incidentProvider = StreamProvider.autoDispose.family<Incident?, String>((
  ref,
  id,
) {
  return ref.watch(incidentServiceProvider).watchIncident(id);
});
