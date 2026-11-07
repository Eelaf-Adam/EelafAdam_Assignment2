import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/incident.dart';

/// All Firestore reads and writes for incident reports (the CRUD).
class IncidentService {
  IncidentService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _firestore.collection('incidents');

  // ---------- Read ----------

  /// A student's own reports, newest first. Updates live.
  Stream<List<Incident>> watchMyIncidents(String uid) {
    return _incidents
        .where('reporterId', isEqualTo: uid)
        .snapshots()
        .map(_toSortedList);
  }

  /// Every report (staff only, enforced by security rules), newest first.
  Stream<List<Incident>> watchAllIncidents() {
    return _incidents.snapshots().map(_toSortedList);
  }

  /// A single report, or null once it has been deleted.
  Stream<Incident?> watchIncident(String id) {
    return _incidents.doc(id).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : Incident.fromMap(doc.id, data);
    });
  }

  // Sorting here instead of with orderBy() avoids needing a Firestore
  // composite index for the "where reporterId + order by date" query.
  List<Incident> _toSortedList(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final list = snapshot.docs
        .map((doc) => Incident.fromMap(doc.id, doc.data()))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // ---------- Create ----------

  /// Saves a new report and returns its short code, e.g. "INC-4F7K2A".
  Future<String> createIncident({
    required AppUser reporter,
    required IncidentType type,
    String? otherType,
    required String description,
    required CampusLocation location,
    String? otherLocation,
    String? photoUrl,
  }) async {
    // Create the document reference first so we know its random ID
    // and can build the short code from it.
    final doc = _incidents.doc();
    final code = 'INC-${doc.id.substring(0, 6).toUpperCase()}';

    await doc.set({
      'code': code,
      'type': type.name,
      'otherType': type == IncidentType.others ? otherType?.trim() : null,
      'description': description.trim(),
      'location': location.name,
      'otherLocation':
          location == CampusLocation.others ? otherLocation?.trim() : null,
      'photoUrl': photoUrl,
      'status': IncidentStatus.pending.name,
      'reporterId': reporter.uid,
      'reporterName': reporter.fullName,
      'reporterEmail': reporter.email,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
      // First timeline step: "Submitted".
      'history': [
        StatusUpdate.toNewMap(
          status: IncidentStatus.pending,
          byId: reporter.uid,
          byName: reporter.fullName,
        ),
      ],
    });

    return code;
  }

  // ---------- Update ----------

  /// Student edit (only allowed while the report is still pending).
  Future<void> updateIncident(
    String id, {
    required IncidentType type,
    String? otherType,
    required String description,
    required CampusLocation location,
    String? otherLocation,
    String? photoUrl,
  }) {
    return _incidents.doc(id).update({
      'type': type.name,
      'otherType': type == IncidentType.others ? otherType?.trim() : null,
      'description': description.trim(),
      'location': location.name,
      'otherLocation':
          location == CampusLocation.others ? otherLocation?.trim() : null,
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Staff-only: change the status and/or add a note.
  /// Each update is added to the report's history for the timeline.
  Future<void> updateStatus(
    String id, {
    required IncidentStatus status,
    required AppUser staff,
    String? note,
  }) {
    return _incidents.doc(id).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'history': FieldValue.arrayUnion([
        StatusUpdate.toNewMap(
          status: status,
          byId: staff.uid,
          byName: staff.fullName,
          note: note,
        ),
      ]),
    });
  }

  // ---------- Delete ----------

  Future<void> deleteIncident(String id) => _incidents.doc(id).delete();
}
