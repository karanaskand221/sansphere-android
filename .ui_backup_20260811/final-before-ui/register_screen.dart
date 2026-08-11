import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../main.dart'; // FIXED: Stepped up two levels to find your root main.dart file

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Explicitly targeting the custom database named 'sansphere'
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'sansphere',
  );

  // Form Input Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _collegeController = TextEditingController();
  final _branchController = TextEditingController();
  final _yearController = TextEditingController();
  final _referralController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Unable to create Firebase account.');
      }

      final String myReferralCode = user.uid.substring(0, 8).toUpperCase();

      // IMPORTANT:
      // The client creates profile fields only.
      // SanCoin/economy fields are server-owned.
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'college': _collegeController.text.trim(),
        'branch': _branchController.text.trim(),
        'year': _yearController.text.trim(),
        'bio': 'Welcome to my Sansphere profile!',
        'specification': 'Not Specified Yet',
        'createdAt': FieldValue.serverTimestamp(),
        'lastProfileUpdate': null,

        // Referral identity only.
        'referralCode': myReferralCode,
        'referralRewardClaimed': false,

        'phoneNumber': '',
        'showPhoneNumber': false,
      });

      // Referral rewards are handled exclusively by Cloud Functions.
      final String enteredCode = _referralController.text.trim().toUpperCase();

      if (enteredCode.isNotEmpty && enteredCode != myReferralCode) {
        try {
          await FirebaseFunctions.instance.httpsCallable('applyReferral').call({
            'code': enteredCode,
          });
        } on FirebaseFunctionsException catch (e) {
          // Account creation should still succeed if the referral
          // code is invalid or the referral operation fails.
          debugPrint(
            'Referral could not be applied: '
            '${e.code}: ${e.message}',
          );
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account registered successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainNavigationScreen(isGuestMode: false),
        ),
        (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Authentication failed.';

      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        if (!mounted) return;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'This email is already registered. Please sign in instead.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'SIGN IN',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        );

        return;
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Please enter a valid email address.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _collegeController.dispose();
    _branchController.dispose();
    _yearController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Create SANSPHERE Account",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Join the Campus Network",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sign up to establish your academic synchronization profiles, records, and vault features.",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Full Name Input
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? "Please enter your name"
                      : null,
                ),
                const SizedBox(height: 16),

                // Email Input
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: const Icon(Icons.alternate_email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) => val == null || !val.contains('@')
                      ? "Please provide a valid email address"
                      : null,
                ),
                const SizedBox(height: 16),

                // Password Input
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Secure Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) => val == null || val.length < 6
                      ? "Password must exceed 5 characters"
                      : null,
                ),
                const SizedBox(height: 16),

                // College Field
                TextFormField(
                  controller: _collegeController,
                  decoration: InputDecoration(
                    labelText: "College / Institution",
                    prefixIcon: const Icon(Icons.school_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? "Please supply your institute name"
                      : null,
                ),
                const SizedBox(height: 16),

                // Branch Field
                TextFormField(
                  controller: _branchController,
                  decoration: InputDecoration(
                    labelText: "Academic Branch (e.g., Computer Engineering)",
                    prefixIcon: const Icon(Icons.engineering_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? "Specify your engineering department branch"
                      : null,
                ),
                const SizedBox(height: 16),

                // Current Year Field
                TextFormField(
                  controller: _yearController,
                  decoration: InputDecoration(
                    labelText: "Current Class Year (e.g., 2nd Year)",
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? "Provide your current enrollment class status"
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _referralController,
                  decoration: InputDecoration(
                    labelText: "Referral Code (optional)",
                    prefixIcon: const Icon(Icons.card_giftcard_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submission Handler Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _handleRegistration,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Complete Sign Up",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
