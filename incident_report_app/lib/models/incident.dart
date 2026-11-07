import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// What kind of problem is being reported. Each has a label and an icon.
enum IncidentType {
  facilities('Facilities', Icons.apartment),
  water('Water', Icons.water_drop),
  electricity('Electricity', Icons.bolt),
  furniture('Furniture', Icons.chair),
  sanitation('Sanitation', Icons.cleaning_services),
  safety('Safety', Icons.shield),
  others('Others', Icons.more_horiz);

  const IncidentType(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Where on campus the incident happened.
enum CampusLocation {
  socialCommons('Social Commons'),
  enterpriseCommons('Enterprise Commons'),
  learningCommons('Learning Commons'),
  foodCourt('Food Court'),
  leadershipCenter('Leadership Center'),
  others('Others');

  const CampusLocation(this.label);

  final String label;
}

/// The progress of a report, in order. Only staff can change it.
enum IncidentStatus {
  pending(
    'Pending',
    Color(0xFFF5A623),
    Icons.schedule,
    timelineTitle: 'Submitted',
    timelineSubtitle: 'Report received from the student',
  ),
  underReview(
    'Under Review',
    Color(0xFFA78BFA),
    Icons.manage_search,
    timelineTitle: 'Under Review',
    timelineSubtitle: 'Staff are assessing the report',
  ),
  inProgress(
    'In Progress',
    AppColors.accent,
    Icons.autorenew,
    timelineTitle: 'In Progress',
    timelineSubtitle: 'Someone is working on the issue',
  ),
  resolved(
    'Resolved',
    Color(0xFF34C759),
    Icons.check_circle,
    timelineTitle: 'Resolved',
    timelineSubtitle: 'Issue fixed and case closed',
  );

  const IncidentStatus(
    this.label,
    this.color,
    this.icon, {
    required this.timelineTitle,
    required this.timelineSubtitle,
  });

  final String label;
  final Color color;
  final IconData icon;

  /// Wording used on the incident tracker timeline.
  final String timelineTitle;
  final String timelineSubtitle;
}

/// One entry in a report's history: a status change and/or a staff note.
class StatusUpdate {
  const StatusUpdate({
    required this.status,
    required this.byName,
    required this.at,
    this.note,
  });

  final IncidentStatus status;
  final String byName;
  final DateTime at;
  final String? note;

  bool get hasNote => note != null && note!.trim().isNotEmpty;

  factory StatusUpdate.fromMap(Map<String, dynamic> data) {
    return StatusUpdate(
      status: Incident._byName(
        IncidentStatus.values,
        data['status'],
        IncidentStatus.pending,
      ),
      byName: data['byName'] as String? ?? '',
      at: (data['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] as String?,
    );
  }

  /// Uses the phone's time (Timestamp.now) because Firestore does not
  /// allow server timestamps inside lists.
  static Map<String, dynamic> toNewMap({
    required IncidentStatus status,
    required String byId,
    required String byName,
    String? note,
  }) {
    final trimmed = note?.trim();
    return {
      'status': status.name,
      'byId': byId,
      'byName': byName,
      'note': (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      'at': Timestamp.now(),
    };
  }
}

/// One incident report, stored in Firestore at `incidents/{id}`.
class Incident {
  const Incident({
    required this.id,
    required this.code,
    required this.type,
    this.otherType,
    required this.description,
    required this.location,
    this.otherLocation,
    this.photoUrl,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    required this.reporterEmail,
    required this.createdAt,
    this.updatedAt,
    this.history = const [],
  });

  final String id;

  /// Short ID shown to users, e.g. "INC-4F7K2A".
  final String code;
  final IncidentType type;

  /// Filled in only when [type] is "Others".
  final String? otherType;
  final String description;
  final CampusLocation location;

  /// Filled in only when [location] is "Others".
  final String? otherLocation;
  final String? photoUrl;
  final IncidentStatus status;
  final String reporterId;
  final String reporterName;
  final String reporterEmail;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Status changes and staff notes, oldest first (for the timeline).
  final List<StatusUpdate> history;

  /// The typed-in text for "Others", otherwise the normal label.
  String get typeLabel => _labelOrOther(type.label, type == IncidentType.others, otherType);

  String get locationLabel =>
      _labelOrOther(location.label, location == CampusLocation.others, otherLocation);

  /// Used as the heading, since reports have no title field.
  String get title => '$typeLabel · $locationLabel';

  /// A small square version of the photo for lists. Cloudinary resizes
  /// it on their server when "c_fill,w_200,h_200" is added to the URL.
  String? get thumbnailUrl {
    final url = photoUrl;
    if (url == null) return null;
    return url.replaceFirst('/upload/', '/upload/c_fill,w_200,h_200,q_auto/');
  }

  /// Students can only edit or delete a report that staff haven't started.
  bool get isEditable => status == IncidentStatus.pending;

  static String _labelOrOther(String label, bool isOther, String? custom) {
    if (isOther && custom != null && custom.trim().isNotEmpty) {
      return custom.trim();
    }
    return label;
  }

  factory Incident.fromMap(String id, Map<String, dynamic> data) {
    return Incident(
      id: id,
      code: data['code'] as String? ?? 'INC-??????',
      type: _byName(IncidentType.values, data['type'], IncidentType.others),
      otherType: data['otherType'] as String?,
      description: data['description'] as String? ?? '',
      location: _byName(
        CampusLocation.values,
        data['location'],
        CampusLocation.others,
      ),
      otherLocation: data['otherLocation'] as String?,
      photoUrl: data['photoUrl'] as String?,
      status: _byName(
        IncidentStatus.values,
        data['status'],
        IncidentStatus.pending,
      ),
      reporterId: data['reporterId'] as String? ?? '',
      reporterName: data['reporterName'] as String? ?? 'Unknown',
      reporterEmail: data['reporterEmail'] as String? ?? '',
      // A brand-new report has no server time yet while it is being saved,
      // so fall back to "now" for that moment.
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      history: [
        for (final entry in (data['history'] as List<dynamic>? ?? const []))
          if (entry is Map<String, dynamic>) StatusUpdate.fromMap(entry),
      ]..sort((a, b) => a.at.compareTo(b.at)),
    );
  }

  /// Finds an enum value by its saved name, or uses [fallback]
  /// if the data is missing or unknown (so old data never crashes the app).
  static T _byName<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
