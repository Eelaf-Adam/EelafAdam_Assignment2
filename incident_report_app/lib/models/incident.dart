import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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

/// In order. Only staff can change it.
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

  final String timelineTitle;
  final String timelineSubtitle;
}

/// A status change and/or staff note shown on the timeline.
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

  /// Server timestamps aren't allowed inside arrays, so device time is used.
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

/// Stored in Firestore at `incidents/{id}`.
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

  /// Only used when [type] is Others.
  final String? otherType;
  final String description;
  final CampusLocation location;

  /// Only used when [location] is Others.
  final String? otherLocation;
  final String? photoUrl;
  final IncidentStatus status;
  final String reporterId;
  final String reporterName;
  final String reporterEmail;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Oldest first.
  final List<StatusUpdate> history;

  String get typeLabel =>
      _labelOrOther(type.label, type == IncidentType.others, otherType);

  String get locationLabel => _labelOrOther(
    location.label,
    location == CampusLocation.others,
    otherLocation,
  );

  /// Reports have no title field, so type + location is used instead.
  String get title => '$typeLabel · $locationLabel';

  /// Cloudinary resizes the image on the fly from the URL parameters.
  String? get thumbnailUrl {
    final url = photoUrl;
    if (url == null) return null;
    return url.replaceFirst('/upload/', '/upload/c_fill,w_200,h_200,q_auto/');
  }

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
      // Null until the server confirms a new write.
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      history: [
        for (final entry in (data['history'] as List<dynamic>? ?? const []))
          if (entry is Map<String, dynamic>) StatusUpdate.fromMap(entry),
      ]..sort((a, b) => a.at.compareTo(b.at)),
    );
  }

  /// Falls back instead of crashing on missing or unknown values.
  static T _byName<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
