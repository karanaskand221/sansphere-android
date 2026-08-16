import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../main.dart';
import '../../services/auth_service.dart';
import '../../services/phone_auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  final _phoneController = TextEditingController();

  final _otpController = TextEditingController();

  final _authService = AuthService.instance;
  final _phoneAuthService = PhoneAuthService.instance;

  ConfirmationResult? _webConfirmationResult;
  String? _nativeVerificationId;

  bool _isLoading = false;
  bool _otpSent = false;
  bool _obscurePassword = true;

  // choice -> initial authentication selection screen
  // email  -> email/password login screen
  // phone  -> phone/OTP login screen
  String _loginMethod = 'choice';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _phone() {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    return '+91$digits';
  }

  Future<void> _emailLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Authenticate with Firebase Auth first.
      // Do NOT query Firestore before authentication because
      // Firestore rules require request.auth != null.
      final result = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      final user = result.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'login-failed',
          message: 'Unable to sign in.',
        );
      }

      // Now the user is authenticated, so reading users/{uid}
      // is permitted by the Firestore rules.
      final profileExists = await _authService.accountExistsByUid(user.uid);

      if (!profileExists) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        await _showAccountNotFoundDialog(
          message:
              'Your Firebase account exists, but no SANSPHERE profile '
              'was found. Please create your SANSPHERE account first.',
        );

        return;
      }

      _openApp();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        await _showAccountNotFoundDialog(
          message: 'No SANSPHERE account was found for this email address.',
        );
        return;
      }

      _showError(_friendlyAuthError(e));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showError('Unable to sign in. Please check your details and try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _googleLogin() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signInWithGoogle();
      final user = result.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'google-login-failed',
          message: 'Google sign-in failed.',
        );
      }

      // Firebase Auth succeeded. Now check whether SANSPHERE
      // has a profile for this authenticated UID.
      final profileExists = await _authService.accountExistsByUid(user.uid);

      if (!profileExists) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        await _showAccountNotFoundDialog(
          message: 'No SANSPHERE account was found for this Google account.',
        );

        return;
      }

      _openApp();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (e.code == 'google-sign-in-cancelled') {
        return;
      }

      _showError(_friendlyAuthError(e));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showError('Unable to continue with Google. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendPhoneOtp() async {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 10) {
      _showError('Enter exactly 10 digits.');
      return;
    }

    if (_isLoading) {
      return;
    }

    final phone = '+91$digits';

    setState(() {
      _isLoading = true;
      _otpSent = false;
      _nativeVerificationId = null;
      _webConfirmationResult = null;
      _otpController.clear();
    });

    try {
      /*
       * PHONE LOGIN
       *
       * First check Firebase Authentication itself.
       * Do NOT query Firestore here because the user is not
       * authenticated yet.
       *
       * Existing Firebase phone account:
       *   check → true → send OTP
       *
       * No Firebase phone account:
       *   check → false → Account Not Found dialog
       */
      final exists = await _authService.phoneAuthAccountExists(phone);

      if (!exists) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        await _showAccountNotFoundDialog(
          message:
              'No SANSPHERE account exists with this phone number. '
              'Would you like to create a new account?',
        );

        return;
      }

      if (kIsWeb) {
        _webConfirmationResult = await _phoneAuthService.sendOtpWeb(phone);
      } else {
        _nativeVerificationId = await _phoneAuthService.sendOtpNative(phone);
      }

      if (!mounted) return;

      setState(() {
        _otpSent = true;
      });

      _showMessage(
        'OTP sent to +91 ${digits.substring(0, 5)} ${digits.substring(5)}.',
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      setState(() {
        _otpSent = false;
        _nativeVerificationId = null;
        _webConfirmationResult = null;
        _isLoading = false;
      });

      _showError(e.message ?? 'Unable to check this phone number.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _otpSent = false;
        _nativeVerificationId = null;
        _webConfirmationResult = null;
      });

      _showError(_friendlyAuthError(e));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _otpSent = false;
        _nativeVerificationId = null;
        _webConfirmationResult = null;
      });

      _showError('Unable to check this phone number. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyPhoneOtp() async {
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
      UserCredential result;

      if (_webConfirmationResult != null) {
        result = await _phoneAuthService.verifyWebOtp(
          confirmationResult: _webConfirmationResult!,
          otp: otp,
        );
      } else if (_nativeVerificationId != null) {
        result = await _phoneAuthService.verifyNativeOtp(
          verificationId: _nativeVerificationId!,
          otp: otp,
        );
      } else {
        throw FirebaseAuthException(
          code: 'otp-session-missing',
          message: 'Please request a new OTP.',
        );
      }

      final user = result.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'phone-login-failed',
          message: 'Phone verification succeeded but no user was returned.',
        );
      }

      // NOW we are authenticated, so Firestore access is permitted.
      final profileExists = await _authService.accountExistsByUid(user.uid);

      if (!profileExists) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        setState(() {
          _otpSent = false;
          _isLoading = false;
          _otpController.clear();
          _nativeVerificationId = null;
          _webConfirmationResult = null;
        });

        await _showAccountNotFoundDialog(
          message:
              'This phone number is verified by Firebase, but no '
              'SANSPHERE account was found for it. Please create your '
              'SANSPHERE account first.',
        );

        return;
      }

      _openApp();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (e.code == 'invalid-verification-code' ||
          e.code == 'invalid-verification-id' ||
          e.code == 'code-expired' ||
          e.code == 'session-expired') {
        _showError(
          'The OTP is incorrect or expired. Please request a new OTP.',
        );
        return;
      }

      _showError(_friendlyAuthError(e));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showError('Unable to verify the OTP. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAccountNotFoundDialog({required String message}) async {
    if (!mounted) return;

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
              Icon(Icons.person_search_outlined, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Expanded(child: Text('Account not found')),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Account'),
            ),
          ],
        );
      },
    );
  }

  void _openApp() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigationScreen(isGuestMode: false),
      ),
    );
  }

  void _guestLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigationScreen(isGuestMode: true),
      ),
    );
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
        return 'Incorrect email or password.';

      case 'user-not-found':
        return 'No account found with this email.';

      case 'invalid-email':
        return 'Enter a valid email address.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'invalid-phone-number':
        return 'Enter a valid Indian mobile number.';

      case 'quota-exceeded':
        return 'SMS limit reached. Please try again later.';

      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Please try again.';

      case 'network-request-failed':
        return 'Network error. Check your internet connection.';

      case 'session-expired':
        return 'OTP expired. Please request a new OTP.';

      case 'invalid-verification-code':
        return 'Incorrect OTP.';

      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green.shade700),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showEmailLogin() {
    setState(() {
      _loginMethod = 'email';
    });
  }

  void _showPhoneLogin() {
    setState(() {
      _loginMethod = 'phone';
      _otpSent = false;
      _otpController.clear();
    });
  }

  void _backToLoginChoices() {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _loginMethod = 'choice';
      _otpSent = false;
      _otpController.clear();
    });
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
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 10,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                  child: _loginMethod == 'choice'
                      ? _buildLoginChoices()
                      : _loginMethod == 'email'
                      ? _buildEmailLogin()
                      : _buildPhoneLogin(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INITIAL LOGIN METHOD SELECTION
  // ============================================================

  Widget _buildLoginChoices() {
    return Column(
      children: [
        const Text(
          'SANSPHERE',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2563EB),
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'Welcome back 👋',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 7),

        const Text(
          'Sign in to continue to your campus network',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),

        const SizedBox(height: 30),

        // EMAIL
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _showEmailLogin,
            icon: const Icon(Icons.email_outlined),
            label: const Text(
              'Continue with Email',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // PHONE
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _showPhoneLogin,
            icon: const Icon(Icons.phone_outlined),
            label: const Text(
              'Continue with Phone',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),

        const SizedBox(height: 24),

        // GOOGLE — DIRECT LOGIN
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _googleLogin,
            icon: const Icon(Icons.account_circle_outlined, size: 24),
            label: const Text(
              'Continue with Google',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: const BorderSide(color: Colors.grey, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _guestLogin,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Browse as Guest',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),

        const SizedBox(height: 14),

        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
          child: const Text(
            "Don't have an account? Create account",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMAIL LOGIN
  // ============================================================

  Widget _buildEmailLogin() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _backButton(),

          const SizedBox(height: 12),

          const Center(
            child: Icon(
              Icons.email_outlined,
              size: 42,
              color: Color(0xFF2563EB),
            ),
          ),

          const SizedBox(height: 14),

          const Center(
            child: Text(
              'Sign in with Email',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 7),

          const Center(
            child: Text(
              'Use your SANSPHERE email and password',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),

          const SizedBox(height: 28),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _decoration('Email address', Icons.email_outlined),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter your email';
              }

              if (!value.contains('@')) {
                return 'Enter a valid email address';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!_isLoading) {
                _emailLogin();
              }
            },
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
              if (value == null || value.isEmpty) {
                return 'Enter your password';
              }

              return null;
            },
          ),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      final email = _emailController.text.trim();

                      if (email.isEmpty) {
                        _showError('Enter your email first.');
                        return;
                      }

                      try {
                        await _authService.sendPasswordResetEmail(email);
                        _showMessage('Password reset email sent.');
                      } on FirebaseAuthException catch (e) {
                        _showError(_friendlyAuthError(e));
                      }
                    },
              child: const Text('Forgot Password?'),
            ),
          ),

          const SizedBox(height: 6),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _emailLogin,
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
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 18),

          Center(
            child: TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
              child: const Text(
                "Don't have an account? Create account",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PHONE LOGIN
  // ============================================================

  Widget _buildPhoneLogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _backButton(),

        const SizedBox(height: 12),

        const Center(
          child: Icon(
            Icons.phone_android_outlined,
            size: 44,
            color: Color(0xFF2563EB),
          ),
        ),

        const SizedBox(height: 14),

        Center(
          child: Text(
            _otpSent ? 'Verify your number' : 'Sign in with Phone',
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 8),

        Center(
          child: Text(
            _otpSent
                ? 'Enter the 6-digit code sent to\n${_phone()}'
                : 'We will send a verification code\nto your mobile number.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: 28),

        TextField(
          controller: _phoneController,
          enabled: !_otpSent && !_isLoading,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          textInputAction: TextInputAction.done,
          decoration: _decoration('Mobile number', Icons.phone_outlined)
              .copyWith(
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14, right: 8),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      '🇮🇳  +91',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                hintText: '10-digit mobile number',
                counterText: '',
              ),
        ),

        if (_otpSent) ...[
          const SizedBox(height: 16),

          TextField(
            controller: _otpController,
            enabled: !_isLoading,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textInputAction: TextInputAction.done,
            decoration: _decoration(
              '6-digit OTP',
              Icons.verified_outlined,
            ).copyWith(hintText: 'Enter OTP', counterText: ''),
          ),
        ],

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : (_otpSent ? _verifyPhoneOtp : _sendPhoneOtp),
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
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _otpSent ? 'Verify & Continue' : 'Send OTP',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),

        if (_otpSent) ...[
          const SizedBox(height: 8),

          Center(
            child: TextButton(
              onPressed: _isLoading ? null : _sendPhoneOtp,
              child: const Text('Resend OTP'),
            ),
          ),
        ],

        const SizedBox(height: 14),

        Center(
          child: TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
            child: const Text(
              "Don't have an account? Create account",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BACK BUTTON
  // ============================================================

  Widget _backButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _isLoading ? null : _backToLoginChoices,
        icon: const Icon(Icons.arrow_back),
        label: const Text('Back'),
      ),
    );
  }
}
