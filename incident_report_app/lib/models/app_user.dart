import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

/// A user's profile as stored in Firestore at `users/{uid}`.
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

  /// Builds an AppUser from a Firestore document.
  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      // Stored as 'student' or 'staff'.
      role: UserRole.values.byName(data['role'] as String),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts the profile to a map for saving in Firestore.
  /// createdAt is set by the server so every user gets a reliable time.
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'role': role.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
