import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incident_report_app/models/app_user.dart';
import 'package:incident_report_app/models/incident.dart';
import 'package:incident_report_app/models/user_role.dart';
import 'package:incident_report_app/screens/report_form_screen.dart';
import 'package:incident_report_app/theme/app_theme.dart';
import 'package:incident_report_app/widgets/app_text_field.dart';
import 'package:incident_report_app/widgets/highlighted_text.dart';
import 'package:incident_report_app/widgets/incident_card.dart';
import 'package:incident_report_app/widgets/loading_button.dart';
import 'package:incident_report_app/widgets/status_timeline.dart';

// AppTheme isn't used here because it downloads the Poppins font.
Widget wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

const student = AppUser(
  uid: 'u1',
  fullName: 'Eelaf Adam',
  email: 'e.adam@alustudent.com',
  role: UserRole.student,
);

Incident sampleIncident({
  IncidentStatus status = IncidentStatus.pending,
  List<StatusUpdate> history = const [],
}) {
  return Incident(
    id: '1',
    code: 'INC-ABC123',
    type: IncidentType.water,
    description: 'No water in the Learning Commons',
    location: CampusLocation.learningCommons,
    status: status,
    reporterId: 'u1',
    reporterName: 'Eelaf Adam',
    reporterEmail: 'e.adam@alustudent.com',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    history: history,
  );
}

void main() {
  group('ReportFormScreen', () {
    Future<void> pumpForm(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ReportFormScreen(profile: student)),
        ),
      );
    }

    testWidgets('shows validation errors when submitted empty', (tester) async {
      await pumpForm(tester);

      await tester.tap(find.text('Submit Report'));
      await tester.pump();

      expect(find.text('Please choose an incident type'), findsOneWidget);
      expect(find.text('Please describe the incident'), findsOneWidget);
      expect(find.text('Please choose a location'), findsOneWidget);
    });

    testWidgets('rejects a description that is too short', (tester) async {
      await pumpForm(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Leak');
      await tester.tap(find.text('Submit Report'));
      await tester.pump();

      expect(
        find.text('Please add a bit more detail (10+ characters)'),
        findsOneWidget,
      );
    });

    testWidgets('choosing "Others" shows an extra text box', (tester) async {
      await pumpForm(tester);
      expect(find.text('What kind of incident?'), findsNothing);

      await tester.tap(find.text('Select incident type'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Others').last);
      await tester.pumpAndSettle();

      expect(find.text('What kind of incident?'), findsOneWidget);
    });
  });

  group('LoadingButton', () {
    testWidgets('shows a spinner and ignores taps while loading', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          LoadingButton(
            label: 'Save',
            isLoading: true,
            onPressed: () => taps++,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);

      await tester.tap(find.byType(ElevatedButton));
      expect(taps, 0);
    });
  });

  group('AppTextField', () {
    testWidgets('password field can be shown and hidden', (tester) async {
      await tester.pumpWidget(
        wrap(
          AppTextField(
            controller: TextEditingController(),
            label: 'Password',
            icon: Icons.lock,
            isPassword: true,
          ),
        ),
      );

      bool obscured() =>
          tester.widget<EditableText>(find.byType(EditableText)).obscureText;

      expect(obscured(), isTrue);
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();
      expect(obscured(), isFalse);
    });
  });

  group('HighlightedText', () {
    testWidgets('marks the searched word in the accent colour', (tester) async {
      await tester.pumpWidget(
        wrap(const HighlightedText('Water leak', highlight: 'leak')),
      );

      final rich = tester.widget<RichText>(find.byType(RichText).first);
      final spans = <TextSpan>[];
      rich.text.visitChildren((span) {
        if (span is TextSpan && span.text != null) spans.add(span);
        return true;
      });

      final match = spans.firstWhere((s) => s.text == 'leak');
      expect(match.style?.color, AppColors.accent);
      expect(
        spans.firstWhere((s) => s.text == 'Water ').style?.color,
        isNot(AppColors.accent),
      );
    });
  });

  group('IncidentCard', () {
    testWidgets('shows title, ID, time and status', (tester) async {
      await tester.pumpWidget(
        wrap(IncidentCard(incident: sampleIncident(), onTap: () {})),
      );

      expect(find.text('Water · Learning Commons'), findsOneWidget);
      expect(find.text('INC-ABC123'), findsOneWidget);
      expect(find.text('2h ago'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('staff see who reported it', (tester) async {
      await tester.pumpWidget(
        wrap(
          IncidentCard(
            incident: sampleIncident(),
            showReporter: true,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('INC-ABC123 · Eelaf Adam'), findsOneWidget);
    });
  });

  group('StatusTimeline', () {
    testWidgets('ticks every step up to the current status', (tester) async {
      await tester.pumpWidget(
        wrap(
          SingleChildScrollView(
            child: StatusTimeline(
              incident: sampleIncident(status: IncidentStatus.inProgress),
            ),
          ),
        ),
      );

      // Submitted, Under Review and In Progress are done; Resolved is not.
      expect(find.byIcon(Icons.check), findsNWidgets(3));
    });

    testWidgets('shows staff notes to the student', (tester) async {
      await tester.pumpWidget(
        wrap(
          SingleChildScrollView(
            child: StatusTimeline(
              incident: sampleIncident(
                status: IncidentStatus.underReview,
                history: [
                  StatusUpdate(
                    status: IncidentStatus.underReview,
                    byName: 'Campus Staff',
                    at: DateTime.now(),
                    note: 'Plumber assigned for tomorrow',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Plumber assigned for tomorrow'), findsOneWidget);
      expect(find.text('Campus Staff'), findsOneWidget);
    });
  });
}
