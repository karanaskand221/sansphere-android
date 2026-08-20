import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

  Future<bool> phoneAuthAccountExists(String phoneNumber) async {
    final normalizedPhone = phoneNumber.trim();

    if (normalizedPhone.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_functions',
        code: 'invalid-argument',
        message: 'Phone number is required.',
      );
    }

    final callable = FirebaseFunctions.instance.httpsCallable(
      'checkPhoneAuthAccount',
    );

    final result = await callable.call({'phoneNumber': normalizedPhone});

    final data = result.data;

    if (data is Map) {
      return data['exists'] == true;
    }

    throw FirebaseException(
      plugin: 'cloud_functions',
      code: 'invalid-response',
      message: 'Invalid response from phone account check.',
    );
  }

  Future<bool> accountExistsByUid(String uid) async {
    final currentUid = _auth.currentUser?.uid;

    debugPrint('PROFILE CHECK: authUid=$currentUid requestedUid=$uid');

    if (currentUid == null || currentUid.isEmpty) {
      debugPrint('PROFILE CHECK FAILED: Firebase Auth has no current user.');
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unauthenticated',
        message: 'Firebase Auth user is missing after successful login.',
      );
    }

    final requestedUid = uid.trim();

    if (requestedUid.isEmpty || requestedUid != currentUid) {
      debugPrint(
        'PROFILE CHECK FAILED: UID mismatch. '
        'authUid=$currentUid requestedUid=$requestedUid',
      );
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'uid-mismatch',
        message: 'Authenticated user ID does not match the requested profile.',
      );
    }

    try {
      debugPrint(
        'PROFILE CHECK: reading users/$currentUid '
        'from Firestore database "sansphere"...',
      );

      final doc = await _firestore
          .collection('users')
          .doc(currentUid)
          .get()
          .timeout(const Duration(seconds: 8));

      debugPrint(
        'PROFILE CHECK RESULT: exists=${doc.exists} '
        'path=${doc.reference.path}',
      );

      if (doc.exists) {
        debugPrint('PROFILE CHECK SUCCESS: profile found for $currentUid.');
      } else {
        debugPrint('PROFILE CHECK FAILED: users/$currentUid does not exist.');
      }

      return doc.exists;
    } on FirebaseException catch (e) {
      debugPrint(
        'PROFILE CHECK FIRESTORE ERROR: '
        'code=${e.code} message=${e.message}',
      );
      rethrow;
    } on TimeoutException {
      debugPrint(
        'PROFILE CHECK TIMEOUT: Firestore did not respond within 8 seconds.',
      );
      rethrow;
    } catch (e) {
      debugPrint(
        'PROFILE CHECK UNKNOWN ERROR: '
        'type=${e.runtimeType} error=$e',
      );
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth
          .signInWithEmailAndPassword(email: email.trim(), password: password)
          .timeout(const Duration(seconds: 15));
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'login-timeout-or-network-error',
        message: 'Firebase sign-in could not complete: $e',
      );
    }
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
      'profileVisibility': 'public',
      'uploadedResourcesVisibility': 'public',
      'purchasedResourcesVisibility': 'private',
      'showActivity': true,
      'allowMessages': true,
      'profilePhotoUrl': '',
      'username': 'user_${user.uid.substring(0, 8).toLowerCase()}',
      'followersCount': 0,
      'followingCount': 0,
      'reviewsCount': 0,
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
      'profileVisibility': 'public',
      'uploadedResourcesVisibility': 'public',
      'purchasedResourcesVisibility': 'private',
      'showActivity': true,
      'allowMessages': true,
      'profilePhotoUrl': '',
      'username': 'user_${user.uid.substring(0, 8).toLowerCase()}',
      'followersCount': 0,
      'followingCount': 0,
      'reviewsCount': 0,
    });
  }
}
