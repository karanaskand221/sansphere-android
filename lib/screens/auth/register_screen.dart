import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../main.dart';
import 'login_screen.dart';
import '../../services/phone_auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final String? prefilledEmail;

  const RegisterScreen({super.key, this.prefilledEmail});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'sansphere',
  );

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _collegeController = TextEditingController();
  final _branchController = TextEditingController();
  final _yearController = TextEditingController();
  final _referralController = TextEditingController();

  final _phoneAuthService = PhoneAuthService.instance;

  String _registrationMethod = 'choice';

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _phoneOtpSent = false;
  bool _emailVerificationSent = false;

  String? _nativeVerificationId;
  ConfirmationResult? _webConfirmationResult;

  @override
  void initState() {
    super.initState();

    if (widget.prefilledEmail != null &&
        widget.prefilledEmail!.trim().isNotEmpty) {
      _emailController.text = widget.prefilledEmail!.trim();
      _registrationMethod = 'email';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _collegeController.dispose();
    _branchController.dispose();
    _yearController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  String _normalizePhone() {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 10) {
      throw FirebaseAuthException(
        code: 'invalid-phone-number',
        message: 'Enter exactly 10 digits after +91.',
      );
    }

    return '+91$digits';
  }

  String _phoneDisplay() {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 10) {
      return '+91';
    }

    return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
  }

  String _friendlyPhoneAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'The phone number is invalid. Please enter a valid 10-digit Indian mobile number.';

      case 'missing-phone-number':
        return 'Please enter your phone number.';

      case 'operation-not-allowed':
        return 'Phone authentication is disabled in Firebase. Enable Phone provider in Firebase Authentication.';

      case 'unauthorized-domain':
        return 'This website is not authorized for Firebase Phone Authentication. Add the current website domain to Firebase Authentication → Settings → Authorized domains.';

      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Please refresh the page and try again.';

      case 'quota-exceeded':
        return 'Firebase SMS quota has been exceeded. Please try again later.';

      case 'too-many-requests':
        return 'Too many phone verification attempts. Please wait and try again later.';

      case 'app-not-authorized':
        return 'This app is not authorized for Firebase Phone Authentication. Check the Firebase project configuration.';

      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';

      case 'web-storage-unsupported':
        return 'Browser storage is unavailable. Please use a normal browser window and try again.';

      case 'internal-error':
        return 'Firebase returned an internal error while sending the OTP. Please refresh the page and try again.';

      case 'invalid-verification-code':
        return 'The OTP is incorrect. Please check the 6-digit code and try again.';

      case 'code-expired':
        return 'This OTP has expired. Please request a new OTP.';

      case 'session-expired':
        return 'The phone verification session expired. Please request a new OTP.';

      default:
        final message = e.message?.trim();

        if (message != null && message.isNotEmpty) {
          return 'Firebase: $message';
        }

        return 'Phone verification failed (${e.code}). Please try again.';
    }
  }

  Future<void> _sendPhoneOtp() async {
    String phone;

    try {
      phone = _normalizePhone();
    } on FirebaseAuthException catch (e) {
      _showError(_friendlyPhoneAuthError(e));
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _phoneOtpSent = false;
      _nativeVerificationId = null;
      _webConfirmationResult = null;
    });

    try {
      /*
       * PHONE REGISTRATION FLOW
       *
       * New account:
       *   phone number
       *        ↓
       *   Firebase OTP
       *        ↓
       *   user enters OTP
       *        ↓
       *   Firebase creates/signs in phone user
       *        ↓
       *   _completePhoneRegistration()
       *        ↓
       *   SANSPHERE Firestore profile
       *
       * Do NOT check Firestore before sending the OTP.
       * Firebase Phone Auth itself is responsible for verifying
       * whether the phone authentication request is valid.
       */

      if (kIsWeb) {
        _webConfirmationResult = await _phoneAuthService.sendOtpWeb(phone);
      } else {
        _nativeVerificationId = await _phoneAuthService.sendOtpNative(phone);
      }

      if (!mounted) return;

      setState(() {
        _phoneOtpSent = true;
      });

      _showMessage(
        'OTP sent to ${_phoneDisplay()}. Please enter the 6-digit code.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _phoneOtpSent = false;
        _nativeVerificationId = null;
        _webConfirmationResult = null;
      });

      _showError(_friendlyPhoneAuthError(e));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _phoneOtpSent = false;
        _nativeVerificationId = null;
        _webConfirmationResult = null;
      });

      _showError(
        'Unable to send OTP. Please check your phone number, '
        'internet connection, and try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<UserCredential> _verifyPhoneOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      throw FirebaseAuthException(
        code: 'invalid-verification-code',
        message: 'Enter the 6-digit OTP.',
      );
    }

    if (_webConfirmationResult != null) {
      return _phoneAuthService.verifyWebOtp(
        confirmationResult: _webConfirmationResult!,
        otp: otp,
      );
    }

    final verificationId = _nativeVerificationId;

    if (verificationId == null || verificationId.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-verification-id',
        message: 'Please request a new OTP.',
      );
    }

    return _phoneAuthService.verifyNativeOtp(
      verificationId: verificationId,
      otp: otp,
    );
  }

  Future<void> _completePhoneRegistration() async {
    final otp = _otpController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _showError('Enter the 6-digit OTP.');
      return;
    }

    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('SANSPHERE: Starting phone OTP verification.');

      final credential = await _verifyPhoneOtp();

      debugPrint('SANSPHERE: Phone OTP verification succeeded.');

      final user = credential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'phone-user-missing',
          message: 'Firebase verified the OTP but returned no user.',
        );
      }

      debugPrint('SANSPHERE: Firebase phone user created. UID=${user.uid}');

      final phone = _normalizePhone();

      await _createUserProfile(
        user: user,
        email: user.email ?? '',
        phoneNumber: phone,
      );

      debugPrint(
        'SANSPHERE: Firestore SANSPHERE profile created successfully.',
      );

      await _applyReferral();

      debugPrint('SANSPHERE: Phone registration completed.');

      // Registration is complete.
      // Sign the newly created user out so the next screen is Login.
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Color(0xFF16A34A)),
                SizedBox(width: 10),
                Expanded(child: Text('Account created successfully')),
              ],
            ),
            content: const Text(
              'Your phone number has been verified and your SANSPHERE '
              'account has been created. Please sign in to continue.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continue to Login'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('SANSPHERE PHONE REGISTRATION ERROR');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('STACK: $stackTrace');
      debugPrint('========================================');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showError(_friendlyPhoneAuthError(e));
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('SANSPHERE PHONE REGISTRATION UNKNOWN ERROR');
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stackTrace');
      debugPrint('========================================');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showError('Account creation failed. Please try the OTP again.');
    }
  }

  Future<void> _startEmailRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      final user = credential.user;

      if (user == null) {
        throw Exception('Unable to create Firebase account.');
      }

      await user.sendEmailVerification();

      if (!mounted) return;

      setState(() {
        _emailVerificationSent = true;
      });

      _showMessage('Verification email sent. Check your inbox.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showError('This email is already registered. Please sign in instead.');
      } else {
        _showError(e.message ?? 'Unable to create account.');
      }
    } catch (e) {
      _showError('Registration failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _finishEmailRegistration() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showError('Your registration session has expired.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await user.reload();

      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser == null) {
        throw Exception('Unable to reload account.');
      }

      if (!refreshedUser.emailVerified) {
        _showError(
          'Please verify your email first, then tap "I Have Verified".',
        );
        return;
      }

      await _createUserProfile(
        user: refreshedUser,
        email: refreshedUser.email ?? _emailController.text.trim(),
        phoneNumber: '',
      );

      await _applyReferral();

      if (!mounted) return;

      _showMessage('Email verified. Account created successfully!');

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(isGuestMode: false),
        ),
        (route) => false,
      );
    } catch (e) {
      _showError('Unable to complete registration.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createUserProfile({
    required User user,
    required String email,
    required String phoneNumber,
  }) async {
    final myReferralCode = user.uid.substring(0, 8).toUpperCase();

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'fullName': _nameController.text.trim(),
      'email': email,
      'college': _collegeController.text.trim(),
      'branch': _branchController.text.trim(),
      'year': _yearController.text.trim(),
      'bio': 'Welcome to my Sansphere profile!',
      'specification': 'Not Specified Yet',
      'createdAt': FieldValue.serverTimestamp(),
      'lastProfileUpdate': null,
      'referralCode': myReferralCode,
      'referralRewardClaimed': false,
      'phoneNumber': phoneNumber,
      'showPhoneNumber': false,
    });
  }

  Future<void> _applyReferral() async {
    final enteredCode = _referralController.text.trim().toUpperCase();

    final user = FirebaseAuth.instance.currentUser;

    if (user == null || enteredCode.isEmpty) {
      return;
    }

    final myReferralCode = user.uid.substring(0, 8).toUpperCase();

    if (enteredCode == myReferralCode) {
      return;
    }

    try {
      await FirebaseFunctions.instance.httpsCallable('applyReferral').call({
        'code': enteredCode,
      });
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'Referral could not be applied: '
        '${e.code}: ${e.message}',
      );
    }
  }

  void _selectEmail() {
    setState(() {
      _registrationMethod = 'email';
      _phoneOtpSent = false;
      _emailVerificationSent = false;
    });
  }

  void _selectPhone() {
    setState(() {
      _registrationMethod = 'phone';
      _phoneOtpSent = false;
      _emailVerificationSent = false;
    });
  }

  void _back() {
    if (_isLoading) return;

    setState(() {
      _registrationMethod = 'choice';
      _phoneOtpSent = false;
      _emailVerificationSent = false;
      _otpController.clear();
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2563EB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: _registrationMethod == 'choice'
                      ? _buildChoice()
                      : _buildRegistrationForm(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoice() {
    return Column(
      children: [
        const Text(
          'SANSPHERE',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2563EB),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Create your account',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose how you want to create your SANSPHERE account.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 30),
        _choiceButton(
          icon: Icons.email_outlined,
          title: 'Register with Email',
          subtitle: 'Email + password verification',
          onPressed: _selectEmail,
        ),
        const SizedBox(height: 14),
        _choiceButton(
          icon: Icons.phone_outlined,
          title: 'Register with Phone',
          subtitle: 'Mobile number + SMS OTP',
          onPressed: _selectPhone,
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Already have an account? Sign in',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _choiceButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          side: const BorderSide(color: Color(0xFF2563EB)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    final isEmail = _registrationMethod == 'email';

    if (isEmail && _emailVerificationSent) {
      return _buildEmailVerification();
    }

    if (!isEmail && _phoneOtpSent) {
      return _buildPhoneVerification();
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: _back,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
          const SizedBox(height: 8),
          Center(
            child: Icon(
              isEmail ? Icons.email_outlined : Icons.phone_android_outlined,
              size: 44,
              color: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              isEmail ? 'Register with Email' : 'Register with Phone',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              isEmail
                  ? 'Create your account using email verification.'
                  : 'Create your account using SMS OTP verification.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          const SizedBox(height: 26),
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: _decoration('Full Name', Icons.badge_outlined),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          if (isEmail) ...[
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _decoration('Email Address', Icons.email_outlined),
              validator: (value) {
                final email = value?.trim() ?? '';

                if (email.isEmpty || !email.contains('@')) {
                  return 'Enter a valid email address.';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: _decoration('Password', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Password must be at least 6 characters.';
                }
                return null;
              },
            ),
          ] else ...[
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: _decoration('Mobile Number', Icons.phone_outlined)
                  .copyWith(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14, right: 8),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          '🇮🇳 +91',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    hintText: '10-digit mobile number',
                    counterText: '',
                  ),
              validator: (value) {
                final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';

                if (digits.length != 10) {
                  return 'Enter exactly 10 digits.';
                }

                return null;
              },
            ),
          ],
          const SizedBox(height: 14),
          TextFormField(
            controller: _collegeController,
            decoration: _decoration(
              'College / Institution',
              Icons.school_outlined,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter your college/institution.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _branchController,
            decoration: _decoration('Academic Branch', Icons.school_outlined),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter your academic branch.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _yearController,
            decoration: _decoration(
              'Current Year',
              Icons.calendar_today_outlined,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter your current year.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _referralController,
            decoration: _decoration(
              'Referral Code (optional)',
              Icons.card_giftcard_outlined,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : isEmail
                  ? _startEmailRegistration
                  : _sendPhoneOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      isEmail ? 'Create Account & Verify Email' : 'Send OTP',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailVerification() {
    return Column(
      children: [
        TextButton.icon(
          onPressed: _isLoading ? null : _back,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back'),
        ),
        const SizedBox(height: 20),
        const Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: Color(0xFF2563EB),
        ),
        const SizedBox(height: 20),
        const Text(
          'Verify your email',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'We sent a verification email to\n'
          '${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, height: 1.5),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _finishEmailRegistration,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'I Have Verified My Email',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _isLoading
              ? null
              : () async {
                  final user = FirebaseAuth.instance.currentUser;

                  if (user == null) return;

                  try {
                    await user.sendEmailVerification();
                    _showMessage('Verification email resent.');
                  } catch (e) {
                    _showError('Unable to resend verification email.');
                  }
                },
          child: const Text('Resend Verification Email'),
        ),
      ],
    );
  }

  Widget _buildPhoneVerification() {
    return Column(
      children: [
        TextButton.icon(
          onPressed: _isLoading ? null : _back,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back'),
        ),
        const SizedBox(height: 20),
        const Icon(Icons.sms_outlined, size: 64, color: Color(0xFF2563EB)),
        const SizedBox(height: 20),
        const Text(
          'Verify your phone',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter the 6-digit OTP sent to\n${_phoneDisplay()}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, height: 1.5),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            labelText: '6-Digit OTP',
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _completePhoneRegistration,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Verify & Create Account',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _isLoading ? null : _sendPhoneOtp,
          child: const Text('Resend OTP'),
        ),
      ],
    );
  }
}
