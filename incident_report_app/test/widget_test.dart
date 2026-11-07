import 'package:flutter_test/flutter_test.dart';
import 'package:incident_report_app/models/user_role.dart';

void main() {
  test('each role is linked to the correct ALU email domain', () {
    expect(UserRole.student.emailDomain, 'alustudent.com');
    expect(UserRole.staff.emailDomain, 'alueducation.com');
  });

  test('there are exactly two roles: student and staff', () {
    expect(UserRole.values, [UserRole.student, UserRole.staff]);
  });
}
