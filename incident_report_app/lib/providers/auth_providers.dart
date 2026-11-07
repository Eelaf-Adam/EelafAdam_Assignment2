import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance, FirebaseFirestore.instance);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

/// autoDispose so a previous user's profile is never reused after sign-out.
final currentUserProfileProvider = FutureProvider.autoDispose<AppUser?>((
  ref,
) async {
  ref.watch(authStateProvider);

  // Read from FirebaseAuth directly; the stream value can lag behind.
  final auth = ref.read(authServiceProvider);
  final user = auth.currentUser;
  if (user == null) return null;
  return auth.getUserProfile(user.uid);
});
