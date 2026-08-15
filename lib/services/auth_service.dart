import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'sansphere',
  );

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<bool> accountExistsByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      return false;
    }

    // Primary lookup using normalized email.
    final normalizedSnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (normalizedSnapshot.docs.isNotEmpty) {
      return true;
    }

    // Fallback for older profiles that may have stored the original casing.
    final rawEmail = email.trim();

    if (rawEmail != normalizedEmail) {
      final rawSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: rawEmail)
          .limit(1)
          .get();

      return rawSnapshot.docs.isNotEmpty;
    }

    return false;
  }

  Future<bool> accountExistsByPhone(String phoneNumber) async {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return false;
    }

    final normalizedPhone = digits.startsWith('91') ? '+$digits' : '+91$digits';

    final snapshot = await _firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: normalizedPhone)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<bool> accountExistsByUid(String uid) async {
    if (uid.trim().isEmpty) {
      return false;
    }

    final doc = await _firestore.collection('users').doc(uid.trim()).get();

    return doc.exists;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> createEmailAccount({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user.',
      );
    }

    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();

      final credential = await _auth.signInWithPopup(provider);

      return credential;
    }

    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: <String>['email', 'profile'],
    );

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    return userCredential;
  }

  Future<void> ensureUserProfile(
    User user, {
    String providerName = 'unknown',
    String phoneNumber = '',
  }) async {
    final userRef = _firestore.collection('users').doc(user.uid);

    final existing = await userRef.get();

    if (existing.exists) {
      return;
    }

    final email = user.email ?? '';
    final displayName = user.displayName?.trim();

    final fallbackName = email.contains('@')
        ? email.split('@').first
        : 'Sansphere User';

    final fullName = (displayName == null || displayName.isEmpty)
        ? fallbackName
        : displayName;

    final generatedReferralCode = 'SP${user.uid.substring(0, 6).toUpperCase()}';

    await userRef.set({
      'uid': user.uid,
      'fullName': fullName,
      'email': email,
      'college': '',
      'branch': '',
      'year': '',
      'bio': 'Welcome to my Sansphere profile!',
      'specification': 'Not Specified Yet',
      'createdAt': FieldValue.serverTimestamp(),
      'lastProfileUpdate': null,
      'referralCode': generatedReferralCode,
      'referralRewardClaimed': false,
      'phoneNumber': phoneNumber.isNotEmpty
          ? phoneNumber
          : (user.phoneNumber ?? ''),
      'showPhoneNumber': false,
    });
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      }
    } catch (_) {}

    await _auth.signOut();
  }

  Future<void> createUserProfile({
    required User user,
    required String fullName,
    required String college,
    required String branch,
    required String year,
    required String referralCode,
    String phoneNumber = '',
  }) async {
    final userRef = _firestore.collection('users').doc(user.uid);

    await userRef.set({
      'uid': user.uid,
      'fullName': fullName.trim(),
      'email': user.email ?? '',
      'college': college.trim(),
      'branch': branch.trim(),
      'year': year.trim(),
      'bio': 'Welcome to my Sansphere profile!',
      'specification': 'Not Specified Yet',
      'createdAt': FieldValue.serverTimestamp(),
      'lastProfileUpdate': null,
      'referralCode': referralCode,
      'referralRewardClaimed': false,
      'phoneNumber': phoneNumber,
      'showPhoneNumber': false,
    });
  }
}
