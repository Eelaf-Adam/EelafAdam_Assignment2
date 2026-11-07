/// The two kinds of users in the app.
/// Each role is tied to an ALU email domain, which is checked at sign-up.
enum UserRole {
  student(
    label: 'Student',
    emailDomain: 'alustudent.com',
    avatarPath: 'assets/images/student.png',
  ),
  staff(
    label: 'Staff',
    emailDomain: 'alueducation.com',
    avatarPath: 'assets/images/staff.png',
  );

  const UserRole({
    required this.label,
    required this.emailDomain,
    required this.avatarPath,
  });

  final String label;
  final String emailDomain;
  final String avatarPath;
}
