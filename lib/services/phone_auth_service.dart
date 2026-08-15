import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PhoneAuthService {
  PhoneAuthService._();

  static final PhoneAuthService instance = PhoneAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<ConfirmationResult> sendOtpWeb(String phoneNumber) async {
    debugPrint('==========================================');
    debugPrint('SANSPHERE: START PHONE REGISTRATION');
    debugPrint('Platform: WEB');
    debugPrint('Phone: $phoneNumber');
    debugPrint('Firebase project: ${_auth.app.options.projectId}');
    debugPrint('==========================================');

    try {
      /*
       * Firebase FlutterFire Web handles the reCAPTCHA verifier internally
       * for signInWithPhoneNumber().
       *
       * IMPORTANT:
       * Do not use signInWithCredential() before OTP confirmation.
       * The ConfirmationResult must remain alive until the user enters OTP.
       */

      final confirmationResult = await _auth.signInWithPhoneNumber(phoneNumber);

      debugPrint('==========================================');
      debugPrint('SANSPHERE: FIREBASE ACCEPTED OTP REQUEST');
      debugPrint('ConfirmationResult created successfully.');
      debugPrint('Firebase should now send the SMS.');
      debugPrint('==========================================');

      return confirmationResult;
    } on FirebaseAuthException catch (e) {
      debugPrint('==========================================');
      debugPrint('SANSPHERE: FIREBASE PHONE AUTH FAILED');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('==========================================');

      rethrow;
    } catch (e, stackTrace) {
      debugPrint('==========================================');
      debugPrint('SANSPHERE: PHONE AUTH UNKNOWN ERROR');
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stackTrace');
      debugPrint('==========================================');

      rethrow;
    }
  }

  Future<String> sendOtpNative(
    String phoneNumber, {
    int? forceResendingToken,
  }) async {
    final completer = Completer<String>();

    debugPrint('==========================================');
    debugPrint('SANSPHERE: START NATIVE PHONE REGISTRATION');
    debugPrint('Phone: $phoneNumber');
    debugPrint('==========================================');

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),

      verificationCompleted: (PhoneAuthCredential credential) {
        debugPrint(
          'SANSPHERE: Firebase automatic phone verification completed.',
        );
      },

      verificationFailed: (FirebaseAuthException error) {
        debugPrint('==========================================');
        debugPrint('SANSPHERE: NATIVE PHONE AUTH FAILED');
        debugPrint('CODE: ${error.code}');
        debugPrint('MESSAGE: ${error.message}');
        debugPrint('==========================================');

        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },

      codeSent: (String verificationId, int? resendToken) {
        debugPrint('SANSPHERE: Firebase SMS codeSent callback received.');

        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('SANSPHERE: Firebase auto retrieval timeout.');

        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },

      forceResendingToken: forceResendingToken,
    );

    return completer.future;
  }

  Future<UserCredential> verifyNativeOtp({
    required String verificationId,
    required String otp,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> verifyWebOtp({
    required ConfirmationResult confirmationResult,
    required String otp,
  }) async {
    return confirmationResult.confirm(otp);
  }
}
