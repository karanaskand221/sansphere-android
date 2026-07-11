import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../global_state.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isGuestMode;
  const ProfileScreen({super.key, this.isGuestMode = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Configures the local view database layout targets explicitly to 'sansphere' database
  final _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(), 
    databaseId: 'sansphere'
  );
  
  final _currentUser = FirebaseAuth.instance.currentUser;

  bool _isEditing = false;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _collegeController = TextEditingController();
  final _emailController = TextEditingController();
  final _branchController = TextEditingController();
  final _yearController = TextEditingController();
  final _specController = TextEditingController();
  final _bioController = TextEditingController();

  Map<String, dynamic>? userData;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _profileStream;

  @override
  void initState() {
    super.initState();
    if (!widget.isGuestMode && _currentUser != null) {
      _profileStream = _firestore.collection('users').doc(_currentUser.uid).snapshots();
    }
  }

  void _initializeControllersIfNeeded(Map<String, dynamic>? newData) {
    if (_isEditing || _isSaving || newData == null) return;
    
    if (userData == null || 
        userData!['fullName'] != newData['fullName'] ||
        userData!['college'] != newData['college'] ||
        userData!['email'] != newData['email'] ||
        userData!['branch'] != newData['branch'] ||
        userData!['year'] != newData['year'] ||
        userData!['specification'] != newData['specification'] ||
        userData!['bio'] != newData['bio']) {
      
      _nameController.text = newData['fullName'] ?? '';
      _collegeController.text = newData['college'] ?? '';
      _emailController.text = newData['email'] ?? '';
      _branchController.text = newData['branch'] ?? '';
      _yearController.text = newData['year'] ?? '';
      _specController.text = newData['specification'] ?? '';
      _bioController.text = newData['bio'] ?? '';
    }
  }

  Future<void> _saveProfileUpdates() async {
    if (_currentUser == null) return;

    if (userData?['lastProfileUpdate'] != null) {
      Timestamp lastUpdateTs = userData?['lastProfileUpdate'];
      DateTime lastUpdate = lastUpdateTs.toDate();
      DateTime now = DateTime.now();
      
      if (now.difference(lastUpdate).inDays < 30) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile modification locked! You can only update parameters once a month."), backgroundColor: Colors.redAccent),
        );
        setState(() => _isEditing = false);
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      await _firestore.collection('users').doc(_currentUser.uid).update({
        'fullName': _nameController.text.trim(),
        'college': _collegeController.text.trim(),
        'email': _emailController.text.trim(),
        'branch': _branchController.text.trim(),
        'year': _yearController.text.trim(),
        'specification': _specController.text.trim(),
        'bio': _bioController.text.trim(),
        'lastProfileUpdate': FieldValue.serverTimestamp(),
      });

      setState(() => _isEditing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile metrics synchronized successfully!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update Failed: ${e.toString()}")),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _triggerReferralMock() {
    final rand = Random();
    int reward = 10 + rand.nextInt(41);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Referral System"),
        content: Text("Link Generated! In the next update, sharing this link will credit ₹$reward to your dynamic wallet pool interface."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Awesome"))],
      ),
    );
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()), (Route<dynamic> route) => false
    );
  }

  void _redirectToAuth() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()), (Route<dynamic> route) => false
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _collegeController.dispose();
    _emailController.dispose();
    _branchController.dispose();
    _yearController.dispose();
    _specController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isGuestMode || _currentUser == null || _profileStream == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text("SANSPHERE Account", style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.withOpacity(0.1),
                  child: const Icon(Icons.person_search_rounded, size: 54, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Profile Session Locked", 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Please login or re-authenticate to display your structural synchronization portfolios, metrics configurations, and wallet balances.", 
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, height: 1.4, fontSize: 14),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.login_rounded),
                    label: const Text("Go to Login Screen", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    onPressed: _redirectToAuth,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _profileStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Data Sync Error: ${snapshot.error}")),
          );
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          final freshData = snapshot.data!.data();
          _initializeControllersIfNeeded(freshData);
          userData = freshData;
        }

        // FALLBACK FOR EMPTY INTERFACES
        if (userData == null) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
            );
          } else {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("No profile data found in 'sansphere' database collection."),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _handleLogout,
                      child: const Text("Sign Out & Try Again"),
                    )
                  ],
                ),
              ),
            );
          }
        }

        double myEarnings = GlobalState.creatorEarnings["User"] ?? 0.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text("SANSPHERE Account", style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: Icon(_isEditing ? Icons.save : Icons.edit_note, color: Colors.blueAccent),
                onPressed: _isSaving ? null : () {
                  if (_isEditing) {
                    _saveProfileUpdates();
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
              )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.blueAccent)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_nameController.text.isNotEmpty ? _nameController.text : "Active Member", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(_collegeController.text.isNotEmpty ? _collegeController.text : "Campus Node ID", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                if (_isSaving) const LinearProgressIndicator(),

                const Text("User Portfolio Specifications", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildProfileField("Full Name", _nameController, Icons.badge_outlined),
                _buildProfileField("College Domain", _collegeController, Icons.school_outlined),
                _buildProfileField("University Email", _emailController, Icons.alternate_email_outlined, enabled: false),
                _buildProfileField("Academic Branch", _branchController, Icons.engineering_outlined),
                _buildProfileField("Current Stream Year", _yearController, Icons.calendar_today_outlined),
                _buildProfileField("Specializations Focus", _specController, Icons.workspace_premium_outlined),
                _buildProfileField("Bio / Description", _bioController, Icons.description_outlined, maxLines: 3),
                
                const SizedBox(height: 24),
                const Text("SANSPHERE Financial Split Engine (Next Update)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.4,
                  children: [
                    _buildWalletCard("Available Cash", "₹${GlobalState.currentUserWallet.toStringAsFixed(2)}", Icons.account_balance_wallet, Colors.teal),
                    _buildWalletCard("My Document Sales", "₹${myEarnings.toStringAsFixed(2)}", Icons.monetization_on, Colors.purple),
                    _buildWalletCard("Platform Processing Pool", "₹${GlobalState.platformProcessingPool.toStringAsFixed(2)}", Icons.admin_panel_settings, Colors.blueGrey),
                    _buildWalletCard("Pending Processing", "Coming Soon", Icons.hourglass_top, Colors.grey),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                ListTile(
                  tileColor: Colors.blueAccent.withOpacity(0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.card_giftcard, color: Colors.blueAccent),
                  title: const Text("Refer and Earn Framework", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Earn ₹10 to ₹50 randomly per unique node referral signup."),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: _triggerReferralMock,
                ),
                const SizedBox(height: 10),

                ListTile(
                  tileColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.support_agent, color: Colors.blueGrey),
                  title: const Text("Customer Support Helpdesk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Open communication channels."),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Support ticketing channel initializing in upcoming patch update Routine.")));
                  },
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: const BorderSide(color: Colors.blueAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: _handleLogout, 
                        icon: const Icon(Icons.switch_account_outlined, size: 18),
                        label: const Text("Switch Account"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text("Log Out"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileField(String label, TextEditingController controller, IconData icon, {bool enabled = true, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing && enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: !_isEditing || !enabled,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildWalletCard(String label, String balance, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(icon, color: color, size: 24),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(balance, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}