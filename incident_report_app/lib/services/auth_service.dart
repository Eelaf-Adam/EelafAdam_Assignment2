import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/user_role.dart';

/// An error with a message that is safe to show to the user.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// All Firebase Authentication and user-profile logic lives here,
/// so the screens never talk to Firebase directly.
class AuthService {
  AuthService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Emits the signed-in user (or null) whenever the login state changes.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Creates the account, saves the profile and sends the verification email.
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }

    final user = credential.user!;
    final profile = AppUser(
      uid: user.uid,
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      role: role,
    );

    try {
      await _users.doc(user.uid).set(profile.toMap());
    } catch (_) {
      // Without a profile the app can't know the user's role, so undo
      // the account creation instead of leaving a half-made account.
      await user.delete();
      throw const AuthException(
        'Could not save your profile. Please try again.',
      );
    }

    await user.updateDisplayName(fullName.trim());
    await sendVerificationEmail();
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  /// Refreshes the user from Firebase and returns whether the email
  /// has been verified (the local copy doesn't update by itself).
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Loads the profile saved at sign-up, or null if it doesn't exist.
  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    return AppUser.fromMap(doc.id, data);
  }

  /// Turns Firebase error codes into friendly messages.
  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in instead.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
