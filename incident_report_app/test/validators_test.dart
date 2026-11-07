import 'package:flutter_test/flutter_test.dart';
import 'package:incident_report_app/models/user_role.dart';
import 'package:incident_report_app/utils/validators.dart';

void main() {
  group('emailForRole', () {
    test('accepts a student email for the student role', () {
      expect(
        Validators.emailForRole('jane@alustudent.com', UserRole.student),
        isNull,
      );
    });

    test('accepts a staff email for the staff role (any letter case)', () {
      expect(
        Validators.emailForRole('John@ALUeducation.com', UserRole.staff),
        isNull,
      );
    });

    test('rejects a student email for the staff role', () {
      expect(
        Validators.emailForRole('jane@alustudent.com', UserRole.staff),
        isNotNull,
      );
    });

    test('rejects a non-ALU email', () {
      expect(
        Validators.emailForRole('jane@gmail.com', UserRole.student),
        isNotNull,
      );
    });

    test('rejects a look-alike domain', () {
      expect(
        Validators.emailForRole('jane@fakealustudent.com', UserRole.student),
        isNotNull,
      );
    });
  });

  group('password', () {
    test('rejects fewer than 6 characters', () {
      expect(Validators.password('12345'), isNotNull);
    });

    test('accepts 6 or more characters', () {
      expect(Validators.password('123456'), isNull);
    });
  });
}
