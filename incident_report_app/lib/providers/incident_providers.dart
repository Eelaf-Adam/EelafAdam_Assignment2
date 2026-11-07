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

/// The reports the signed-in user is allowed to see:
/// staff see every report, students see only their own.
final visibleIncidentsProvider =
    StreamProvider.autoDispose<List<Incident>>((ref) {
  final profile = ref.watch(currentUserProfileProvider).value;
  if (profile == null) return const Stream.empty();

  final service = ref.watch(incidentServiceProvider);
  return profile.role == UserRole.staff
      ? service.watchAllIncidents()
      : service.watchMyIncidents(profile.uid);
});

/// The filter selected on the Reports / Portal tab. Kept in a provider so
/// tapping a summary card on Home can open that tab already filtered.
class ReportFilterNotifier extends Notifier<ReportFilter> {
  @override
  ReportFilter build() => ReportFilter.all;

  void select(ReportFilter filter) => state = filter;
}

final reportFilterProvider =
    NotifierProvider.autoDispose<ReportFilterNotifier, ReportFilter>(
  ReportFilterNotifier.new,
);

/// One report by its Firestore ID, updating live (e.g. when staff
/// change its status while a student is looking at it).
final incidentProvider =
    StreamProvider.autoDispose.family<Incident?, String>((ref, id) {
  return ref.watch(incidentServiceProvider).watchIncident(id);
});
