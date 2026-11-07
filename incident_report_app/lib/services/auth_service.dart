import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/user_role.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

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
      // Without a profile there's no role, so roll the account back.
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

  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final verified = _auth.currentUser?.emailVerified ?? false;

    // The rules read email_verified from the token, so refresh it.
    if (verified) await _auth.currentUser?.getIdToken(true);
    return verified;
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    return AppUser.fromMap(doc.id, data);
  }

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
