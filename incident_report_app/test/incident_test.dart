import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incident_report_app/models/incident.dart';
import 'package:incident_report_app/utils/date_format.dart';
import 'package:incident_report_app/utils/incident_filters.dart';

Incident makeIncident({
  String id = '1',
  IncidentType type = IncidentType.water,
  String? otherType,
  CampusLocation location = CampusLocation.foodCourt,
  String? otherLocation,
  IncidentStatus status = IncidentStatus.pending,
  String description = 'Leaking tap near the entrance',
}) {
  return Incident(
    id: id,
    code: 'INC-$id',
    type: type,
    otherType: otherType,
    description: description,
    location: location,
    otherLocation: otherLocation,
    status: status,
    reporterId: 'u1',
    reporterName: 'Eelaf Adam',
    reporterEmail: 'e.adam@alustudent.com',
    createdAt: DateTime(2026, 11, 7),
  );
}

void main() {
  group('Incident labels', () {
    test('title combines type and location', () {
      expect(makeIncident().title, 'Water · Food Court');
    });

    test('"Others" uses the text the student typed', () {
      final incident = makeIncident(
        type: IncidentType.others,
        otherType: 'Broken window',
        location: CampusLocation.others,
        otherLocation: 'Library, 2nd floor',
      );
      expect(incident.title, 'Broken window · Library, 2nd floor');
    });

    test('only pending reports are editable', () {
      expect(makeIncident().isEditable, isTrue);
      expect(
        makeIncident(status: IncidentStatus.inProgress).isEditable,
        isFalse,
      );
    });

    test('unknown saved values fall back safely', () {
      final incident = Incident.fromMap('x', {
        'type': 'not-a-type',
        'location': 'nowhere',
        'status': 'weird',
      });
      expect(incident.type, IncidentType.others);
      expect(incident.location, CampusLocation.others);
      expect(incident.status, IncidentStatus.pending);
    });
  });

  group('filterIncidents', () {
    final incidents = [
      makeIncident(id: '1'),
      makeIncident(
        id: '2',
        type: IncidentType.electricity,
        location: CampusLocation.learningCommons,
        status: IncidentStatus.resolved,
        description: 'Lights flickering',
      ),
    ];

    test('empty search returns everything', () {
      expect(filterIncidents(incidents), hasLength(2));
    });

    test('search ignores letter case and matches location', () {
      final result = filterIncidents(incidents, query: 'LEARNING');
      expect(result.single.id, '2');
    });

    test('search matches description text', () {
      expect(filterIncidents(incidents, query: 'tap').single.id, '1');
    });

    test('status filter keeps only that status', () {
      final result = filterIncidents(incidents, filter: ReportFilter.resolved);
      expect(result.single.id, '2');
    });

    test('"Today" keeps only reports submitted on the same day', () {
      final result = filterIncidents(
        incidents,
        filter: ReportFilter.today,
        now: DateTime(2026, 11, 7, 18),
      );
      expect(result, hasLength(2));

      final nextDay = filterIncidents(
        incidents,
        filter: ReportFilter.today,
        now: DateTime(2026, 11, 8, 9),
      );
      expect(nextDay, isEmpty);
    });

    test('every status has a matching filter', () {
      for (final status in IncidentStatus.values) {
        expect(ReportFilter.forStatus(status).status, status);
      }
    });
  });

  group('timeline history', () {
    test('history is read from Firestore data, oldest first', () {
      final incident = Incident.fromMap('x', {
        'status': 'inProgress',
        'history': [
          {
            'status': 'inProgress',
            'byName': 'Staff Member',
            'note': 'Plumber assigned',
            'at': Timestamp.fromDate(DateTime(2026, 11, 7, 12)),
          },
          {
            'status': 'pending',
            'byName': 'Eelaf Adam',
            'at': Timestamp.fromDate(DateTime(2026, 11, 7, 9)),
          },
        ],
      });

      expect(incident.history.map((u) => u.status), [
        IncidentStatus.pending,
        IncidentStatus.inProgress,
      ]);
      expect(incident.history.last.hasNote, isTrue);
      expect(incident.history.first.hasNote, isFalse);
    });

    test('a blank note is saved as no note', () {
      final map = StatusUpdate.toNewMap(
        status: IncidentStatus.underReview,
        byId: 's1',
        byName: 'Staff',
        note: '   ',
      );
      expect(map['note'], isNull);
    });
  });

  group('timeAgo', () {
    final now = DateTime(2026, 11, 7, 15, 0);

    test('formats recent times', () {
      expect(timeAgo(now.subtract(const Duration(seconds: 20)), now: now),
          'Just now');
      expect(timeAgo(now.subtract(const Duration(minutes: 5)), now: now),
          '5 min ago');
      expect(timeAgo(now.subtract(const Duration(hours: 2)), now: now),
          '2h ago');
      expect(timeAgo(now.subtract(const Duration(days: 1)), now: now),
          'Yesterday');
      expect(timeAgo(now.subtract(const Duration(days: 3)), now: now),
          '3 days ago');
    });

    test('shows the date for anything older than a week', () {
      expect(timeAgo(DateTime(2026, 10, 1), now: now), '1 Oct 2026');
    });
  });
}
