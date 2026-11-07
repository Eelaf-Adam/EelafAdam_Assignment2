import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/incident.dart';

/// Thrown when a write didn't reach the server in time. Firestore keeps the
/// change on the device and syncs it once the connection is back.
class OfflineException implements Exception {
  const OfflineException({this.code});

  /// Set when a new report was queued, so the user still gets its ID.
  final String? code;
}

class IncidentService {
  IncidentService(this._firestore);

  final FirebaseFirestore _firestore;

  static const _writeTimeout = Duration(seconds: 15);

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _firestore.collection('incidents');

  Stream<List<Incident>> watchMyIncidents(String uid) {
    return _incidents
        .where('reporterId', isEqualTo: uid)
        .snapshots()
        .map(_toSortedList);
  }

  /// Staff only (enforced by the security rules).
  Stream<List<Incident>> watchAllIncidents() {
    return _incidents.snapshots().map(_toSortedList);
  }

  /// Emits null once the report is deleted.
  Stream<Incident?> watchIncident(String id) {
    return _incidents.doc(id).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : Incident.fromMap(doc.id, data);
    });
  }

  // Sorted here rather than with orderBy() so the student query
  // doesn't need a composite index.
  List<Incident> _toSortedList(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final list = snapshot.docs
        .map((doc) => Incident.fromMap(doc.id, doc.data()))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Returns the short report ID, e.g. "INC-4F7K2A".
  Future<String> createIncident({
    required AppUser reporter,
    required IncidentType type,
    String? otherType,
    required String description,
    required CampusLocation location,
    String? otherLocation,
    String? photoUrl,
  }) async {
    final doc = _incidents.doc();
    final code = 'INC-${doc.id.substring(0, 6).toUpperCase()}';

    await _write(
      doc.set({
        'code': code,
        'type': type.name,
        'otherType': type == IncidentType.others ? otherType?.trim() : null,
        'description': description.trim(),
        'location': location.name,
        'otherLocation': location == CampusLocation.others
            ? otherLocation?.trim()
            : null,
        'photoUrl': photoUrl,
        'status': IncidentStatus.pending.name,
        'reporterId': reporter.uid,
        'reporterName': reporter.fullName,
        'reporterEmail': reporter.email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
        'history': [
          StatusUpdate.toNewMap(
            status: IncidentStatus.pending,
            byId: reporter.uid,
            byName: reporter.fullName,
          ),
        ],
      }),
      queuedCode: code,
    );

    return code;
  }

  /// The rules only allow this while the report is pending.
  Future<void> updateIncident(
    String id, {
    required IncidentType type,
    String? otherType,
    required String description,
    required CampusLocation location,
    String? otherLocation,
    String? photoUrl,
  }) {
    return _write(
      _incidents.doc(id).update({
        'type': type.name,
        'otherType': type == IncidentType.others ? otherType?.trim() : null,
        'description': description.trim(),
        'location': location.name,
        'otherLocation': location == CampusLocation.others
            ? otherLocation?.trim()
            : null,
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  /// Staff only. Also appends to the timeline history.
  Future<void> updateStatus(
    String id, {
    required IncidentStatus status,
    required AppUser staff,
    String? note,
  }) {
    return _write(
      _incidents.doc(id).update({
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
      }),
    );
  }

  Future<void> deleteIncident(String id) => _write(_incidents.doc(id).delete());

  // Offline writes never complete until the device reconnects,
  // so give up waiting after a while and let the UI explain.
  Future<void> _write(Future<void> write, {String? queuedCode}) async {
    try {
      await write.timeout(_writeTimeout);
    } on TimeoutException {
      throw OfflineException(code: queuedCode);
    }
  }
}
