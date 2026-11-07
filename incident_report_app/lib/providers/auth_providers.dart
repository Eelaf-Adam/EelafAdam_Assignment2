import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

/// One shared AuthService for the whole app.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance, FirebaseFirestore.instance);
});

/// The current Firebase user (null when signed out). Updates automatically.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

/// The signed-in user's Firestore profile (name, email, role).
///
/// autoDispose: the profile is thrown away when no screen is using it
/// (e.g. after sign-out), so the next user never sees the previous
/// user's cached profile.
final currentUserProfileProvider =
    FutureProvider.autoDispose<AppUser?>((ref) async {
  // Rebuild whenever someone signs in or out...
  ref.watch(authStateProvider);

  // ...but always read the user from FirebaseAuth itself, which is
  // updated immediately, instead of a value that might be out of date.
  final auth = ref.read(authServiceProvider);
  final user = auth.currentUser;
  if (user == null) return null;
  return auth.getUserProfile(user.uid);
});
