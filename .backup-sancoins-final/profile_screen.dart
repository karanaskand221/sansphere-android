import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../global_state.dart';
import 'support_screen.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestore = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'sansphere');
  bool _isEditing = false;
  bool _isSaving = false;
  Map<String, dynamic>? userData;

  final _bioController = TextEditingController();
  final _specController = TextEditingController();
  final _collegeController = TextEditingController();
  final _branchController = TextEditingController();
  final _yearController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _showPhoneNumber = false;

  @override
  void dispose() {
    _bioController.dispose();
    _specController.dispose();
    _collegeController.dispose();
    _branchController.dispose();
    _yearController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadIntoControllers(Map<String, dynamic> data) {
    _bioController.text = data['bio'] ?? '';
    _specController.text = data['specification'] ?? '';
    _collegeController.text = data['college'] ?? '';
    _branchController.text = data['branch'] ?? '';
    _yearController.text = data['year'] ?? '';
    _phoneController.text = data['phoneNumber'] ?? '';
    _showPhoneNumber = data['showPhoneNumber'] == true;
  }

  bool _canEditNow(Map<String, dynamic> data) {
    final Timestamp? last = data['lastProfileUpdate'];
    if (last == null) return true;
    final daysSince = DateTime.now().difference(last.toDate()).inDays;
    return daysSince >= 30;
  }

  Future<void> _saveProfileChanges(String uid) async {
    setState(() => _isSaving = true);
    try {
      await _firestore.collection('users').doc(uid).update({
        'bio': _bioController.text.trim(),
        'specification': _specController.text.trim(),
        'college': _collegeController.text.trim(),
        'branch': _branchController.text.trim(),
        'year': _yearController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'showPhoneNumber': _showPhoneNumber,
        'lastProfileUpdate': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareReferralCode() async {
    final code = userData?['referralCode'] ?? '';
    if (code.isEmpty) return;
    await Share.share(
      "Join me on SANSPHERE — the campus resource-sharing app! "
      "Use my referral code $code when you sign up and I'll get 100 SanCoins. 🎓",
    );
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildWalletCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Please log in.")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout)],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Profile not found."));
          }

          userData = snapshot.data!.data() as Map<String, dynamic>;
          if (!_isEditing) _loadIntoControllers(userData!);

          final canEdit = _canEditNow(userData!);
          final myEarnings = (GlobalState.creatorEarnings[uid] ?? 0.0);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        child: Text(
                          (userData!['fullName'] ?? '?').toString().isNotEmpty
                              ? userData!['fullName'][0].toString().toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(userData!['fullName'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(userData!['email'] ?? '', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _buildWalletCard("Available Cash", "₹${GlobalState.currentUserWallet.toStringAsFixed(2)}", Icons.account_balance_wallet, Colors.teal),
                    _buildWalletCard("SanCoins", "${(userData?['sanCoins'] ?? 0)}", Icons.stars_rounded, Colors.amber),
                    _buildWalletCard("My Document Sales", "₹${myEarnings.toStringAsFixed(2)}", Icons.monetization_on, Colors.purple),
                    _buildWalletCard("Platform Processing Pool", "₹${GlobalState.platformProcessingPool.toStringAsFixed(2)}", Icons.admin_panel_settings, Colors.blueGrey),
                  ],
                ),
                const SizedBox(height: 20),

                ListTile(
                  tileColor: Colors.blueAccent.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.card_giftcard, color: Colors.blueAccent),
                  title: const Text("Refer and Earn", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("Your code: ${userData?['referralCode'] ?? '...'} • Earn 100 SanCoins per signup"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: _shareReferralCode,
                ),
                const SizedBox(height: 12),
                ListTile(
                  tileColor: Colors.grey.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.support_agent, color: Colors.black87),
                  title: const Text("Contact Support", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Report an issue or send a suggestion"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
                  },
                ),

                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Profile Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (!_isEditing)
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(canEdit ? "Edit" : "Locked (30-day cooldown)"),
                        onPressed: canEdit ? () => setState(() => _isEditing = true) : null,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                _isEditing
                    ? Column(
                        children: [
                          TextFormField(controller: _bioController, decoration: const InputDecoration(labelText: "Bio")),
                          const SizedBox(height: 12),
                          TextFormField(controller: _specController, decoration: const InputDecoration(labelText: "Specification")),
                          const SizedBox(height: 12),
                          TextFormField(controller: _collegeController, decoration: const InputDecoration(labelText: "College")),
                          const SizedBox(height: 12),
                          TextFormField(controller: _branchController, decoration: const InputDecoration(labelText: "Branch")),
                          const SizedBox(height: 12),
                          TextFormField(controller: _yearController, decoration: const InputDecoration(labelText: "Year")),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: "Phone Number"),
                          ),
                          const SizedBox(height: 4),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Show my phone number to people I chat with", style: TextStyle(fontSize: 13)),
                            value: _showPhoneNumber,
                            onChanged: (v) => setState(() => _showPhoneNumber = v),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => setState(() => _isEditing = false),
                                  child: const Text("Cancel"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : () => _saveProfileChanges(uid),
                                  child: _isSaving
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Text("Save"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Bio: ${userData!['bio'] ?? ''}"),
                          const SizedBox(height: 6),
                          Text("Specification: ${userData!['specification'] ?? ''}"),
                          const SizedBox(height: 6),
                          Text("College: ${userData!['college'] ?? ''}"),
                          const SizedBox(height: 6),
                          Text("Branch: ${userData!['branch'] ?? ''}"),
                          const SizedBox(height: 6),
                          Text("Year: ${userData!['year'] ?? ''}"),
                          const SizedBox(height: 6),
                          Text(
                            _showPhoneNumber && (userData!['phoneNumber'] ?? '').toString().isNotEmpty
                                ? "Phone: ${userData!['phoneNumber']} (visible to chat contacts)"
                                : "Phone: ${(userData!['phoneNumber'] ?? '').toString().isEmpty ? 'not set' : 'hidden from others'}",
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
