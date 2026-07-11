import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showErrorSnackBar("Please fill out all fields.");
      return;
    }

    if (password != confirmPassword) {
      _showErrorSnackBar("Passwords do not match.");
      return;
    }

    if (password.length < 6) {
      _showErrorSnackBar("Password must be at least 6 characters long.");
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Authenticate and create user configuration via Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );

      final User? user = userCredential.user;

      if (user != null) {
        // 2. Set complete structural user record profile data directly in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': name,
          'email': email,
          'walletBalance': 500.0, // Default signup initialization pool value
          'platformProcessingPool': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(e.message ?? "An authentication error occurred.");
    } catch (e) {
      // FIXED: Displays the precise runtime exception message so you can debug instantly
      _showErrorSnackBar("Registration Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    // Clear out any stale visible snackbars instantly
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF1E293B), // Premium charcoal dark mode styling
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16), // Prevents clipping at the base of the viewport layout
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Create Account", style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(45),
                    child: Image.asset(
                      'assets/images/S.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return CircleAvatar(
                          backgroundColor: Colors.blueAccent.withOpacity(0.1),
                          child: const Icon(Icons.school, size: 45, color: Colors.blueAccent),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "SANSPHERE",
                style: TextStyle(
                  fontSize: 34, 
                  fontWeight: FontWeight.w900, 
                  color: Colors.blueAccent,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Join your college community gateway", 
                style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 35),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    _buildCustomTextField(
                      controller: _fullNameController,
                      label: "Full Name",
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 18),
                    _buildCustomTextField(
                      controller: _emailController,
                      label: "College Email ID",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 18),
                    _buildCustomTextField(
                      controller: _passwordController,
                      label: "Password",
                      icon: Icons.lock_outlined,
                      obscureText: true,
                    ),
                    const SizedBox(height: 18),
                    _buildCustomTextField(
                      controller: _confirmPasswordController,
                      label: "Confirm Password",
                      icon: Icons.lock_clock_outlined,
                      obscureText: true,
                    ),
                    const SizedBox(height: 30),
                    isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: CircularProgressIndicator(),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Colors.blueAccent, Colors.lightBlue],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: _register,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 54),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                "Sign Up", 
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.blueAccent.withOpacity(0.7)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
      ),
    );
  }
}