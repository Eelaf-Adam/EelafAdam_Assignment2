import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

/// Stored in Firestore at `users/{uid}`.
class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    this.createdAt,
  });

  final String uid;
  final String fullName;
  final String email;
  final UserRole role;
  final DateTime? createdAt;

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: UserRole.values.byName(data['role'] as String),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// createdAt is set by the server clock.
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'role': role.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
