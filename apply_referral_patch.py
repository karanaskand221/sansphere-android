import re, sys

def patch(path, replacements):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    changed = False
    for old, new, label in replacements:
        if new in content:
            print(f"  [skip] {label} — already applied")
            continue
        if old not in content:
            print(f"  [WARN] {label} — anchor text not found, skipped (check manually)")
            continue
        content = content.replace(old, new, 1)
        changed = True
        print(f"  [ok]   {label}")
    if changed:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)

# ---------------- pubspec.yaml ----------------
print("pubspec.yaml:")
patch("pubspec.yaml", [
    ("  cupertino_icons: ^1.0.8\n",
     "  cupertino_icons: ^1.0.8\n  share_plus: ^10.1.4\n",
     "add share_plus dependency"),
])

# ---------------- register_screen.dart ----------------
print("\nlib/screens/auth/register_screen.dart:")
patch("lib/screens/auth/register_screen.dart", [
    (
        "  final _yearController = TextEditingController();\n\n  bool _isLoading = false;",
        "  final _yearController = TextEditingController();\n  final _referralController = TextEditingController();\n\n  bool _isLoading = false;",
        "add _referralController field"
    ),
    (
        "    _yearController.dispose();\n    super.dispose();",
        "    _yearController.dispose();\n    _referralController.dispose();\n    super.dispose();",
        "dispose _referralController"
    ),
    (
        "                  validator: (val) => val == null || val.trim().isEmpty ? \"Provide your current enrollment class status\" : null,\n"
        "                ),\n"
        "                const SizedBox(height: 32),\n\n"
        "                // Submission Handler Button",
        "                  validator: (val) => val == null || val.trim().isEmpty ? \"Provide your current enrollment class status\" : null,\n"
        "                ),\n"
        "                const SizedBox(height: 16),\n"
        "                TextFormField(\n"
        "                  controller: _referralController,\n"
        "                  decoration: InputDecoration(\n"
        "                    labelText: \"Referral Code (optional)\",\n"
        "                    prefixIcon: const Icon(Icons.card_giftcard_outlined),\n"
        "                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),\n"
        "                  ),\n"
        "                ),\n"
        "                const SizedBox(height: 32),\n\n"
        "                // Submission Handler Button",
        "add referral code form field"
    ),
    (
        "      if (user != null) {\n"
        "        // 2. CONNECT TO FIRESTORE: Write initial profile documents matching User UID\n"
        "        await _firestore.collection('users').doc(user.uid).set({\n"
        "          'uid': user.uid,\n"
        "          'fullName': _nameController.text.trim(),\n"
        "          'email': _emailController.text.trim(),\n"
        "          'college': _collegeController.text.trim(),\n"
        "          'branch': _branchController.text.trim(),\n"
        "          'year': _yearController.text.trim(),\n"
        "          'bio': 'Welcome to my Sansphere profile!',\n"
        "          'specification': 'Not Specified Yet',\n"
        "          'createdAt': FieldValue.serverTimestamp(),\n"
        "          'lastProfileUpdate': null,\n"
        "        });\n\n"
        "        if (!mounted) return;",
        "      if (user != null) {\n"
        "        // 2. CONNECT TO FIRESTORE: Write initial profile documents matching User UID\n"
        "        final String myReferralCode = user.uid.substring(0, 8).toUpperCase();\n\n"
        "        await _firestore.collection('users').doc(user.uid).set({\n"
        "          'uid': user.uid,\n"
        "          'fullName': _nameController.text.trim(),\n"
        "          'email': _emailController.text.trim(),\n"
        "          'college': _collegeController.text.trim(),\n"
        "          'branch': _branchController.text.trim(),\n"
        "          'year': _yearController.text.trim(),\n"
        "          'bio': 'Welcome to my Sansphere profile!',\n"
        "          'specification': 'Not Specified Yet',\n"
        "          'createdAt': FieldValue.serverTimestamp(),\n"
        "          'lastProfileUpdate': null,\n"
        "          'sanCoins': 0,\n"
        "          'referralCode': myReferralCode,\n"
        "        });\n\n"
        "        final String enteredCode = _referralController.text.trim().toUpperCase();\n"
        "        if (enteredCode.isNotEmpty && enteredCode != myReferralCode) {\n"
        "          final referrerQuery = await _firestore\n"
        "              .collection('users')\n"
        "              .where('referralCode', isEqualTo: enteredCode)\n"
        "              .limit(1)\n"
        "              .get();\n\n"
        "          if (referrerQuery.docs.isNotEmpty) {\n"
        "            final referrerDoc = referrerQuery.docs.first;\n"
        "            await _firestore.collection('users').doc(referrerDoc.id).update({\n"
        "              'sanCoins': FieldValue.increment(100),\n"
        "            });\n"
        "            await _firestore.collection('referrals').add({\n"
        "              'referrerUid': referrerDoc.id,\n"
        "              'newUserUid': user.uid,\n"
        "              'coinsAwarded': 100,\n"
        "              'createdAt': FieldValue.serverTimestamp(),\n"
        "            });\n"
        "          }\n"
        "        }\n\n"
        "        if (!mounted) return;",
        "award referrer 100 SanCoins on signup"
    ),
])

# ---------------- profile_screen.dart ----------------
print("\nlib/screens/profile_screen.dart:")

with open("lib/screens/profile_screen.dart", "r", encoding="utf-8") as f:
    profile_content = f.read()

if "share_plus/share_plus.dart" not in profile_content:
    profile_content = profile_content.replace(
        "import '../global_state.dart';",
        "import '../global_state.dart';\nimport 'package:share_plus/share_plus.dart';",
        1
    )
    print("  [ok]   add share_plus import")
else:
    print("  [skip] share_plus import — already present")

with open("lib/screens/profile_screen.dart", "w", encoding="utf-8") as f:
    f.write(profile_content)

patch("lib/screens/profile_screen.dart", [
    (
        "  void _triggerReferralMock() {\n"
        "    final rand = Random();\n"
        "    int reward = 10 + rand.nextInt(41);\n"
        "    showDialog(\n"
        "      context: context,\n"
        "      builder: (_) => AlertDialog(\n"
        "        title: const Text(\"Referral System\"),\n"
        "        content: Text(\"Link Generated! In the next update, sharing this link will credit ₹$reward to your dynamic wallet pool interface.\"),\n"
        "        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text(\"Awesome\"))],\n"
        "      ),\n"
        "    );\n"
        "  }",
        "  Future<void> _shareReferralCode() async {\n"
        "    final code = userData?['referralCode'] ?? '';\n"
        "    if (code.isEmpty) return;\n"
        "    await SharePlus.instance.share(\n"
        "      ShareParams(\n"
        "        text: \"Join me on SANSPHERE — the campus resource-sharing app! \"\n"
        "              \"Use my referral code $code when you sign up and I'll get 100 SanCoins. 🎓\",\n"
        "      ),\n"
        "    );\n"
        "  }",
        "replace mock referral method with real share flow"
    ),
    (
        "                ListTile(\n"
        "                  tileColor: Colors.blueAccent.withOpacity(0.08),\n"
        "                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),\n"
        "                  leading: const Icon(Icons.card_giftcard, color: Colors.blueAccent),\n"
        "                  title: const Text(\"Refer and Earn Framework\", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),\n"
        "                  subtitle: const Text(\"Earn ₹10 to ₹50 randomly per unique node referral signup.\"),\n"
        "                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),\n"
        "                  onTap: _triggerReferralMock,\n"
        "                ),",
        "                ListTile(\n"
        "                  tileColor: Colors.blueAccent.withValues(alpha: 0.08),\n"
        "                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),\n"
        "                  leading: const Icon(Icons.card_giftcard, color: Colors.blueAccent),\n"
        "                  title: const Text(\"Refer and Earn\", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),\n"
        "                  subtitle: Text(\"Your code: ${userData?['referralCode'] ?? '...'} • Earn 100 SanCoins per signup\"),\n"
        "                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),\n"
        "                  onTap: _shareReferralCode,\n"
        "                ),",
        "update referral ListTile (withOpacity variant)"
    ),
    (
        "                ListTile(\n"
        "                  tileColor: Colors.blueAccent.withValues(alpha: 0.08),\n"
        "                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),\n"
        "                  leading: const Icon(Icons.card_giftcard, color: Colors.blueAccent),\n"
        "                  title: const Text(\"Refer and Earn Framework\", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),\n"
        "                  subtitle: const Text(\"Earn ₹10 to ₹50 randomly per unique node referral signup.\"),\n"
        "                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),\n"
        "                  onTap: _triggerReferralMock,\n"
        "                ),",
        "                ListTile(\n"
        "                  tileColor: Colors.blueAccent.withValues(alpha: 0.08),\n"
        "                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),\n"
        "                  leading: const Icon(Icons.card_giftcard, color: Colors.blueAccent),\n"
        "                  title: const Text(\"Refer and Earn\", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),\n"
        "                  subtitle: Text(\"Your code: ${userData?['referralCode'] ?? '...'} • Earn 100 SanCoins per signup\"),\n"
        "                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),\n"
        "                  onTap: _shareReferralCode,\n"
        "                ),",
        "update referral ListTile (withValues variant)"
    ),
    (
        "                    _buildWalletCard(\"Available Cash\", \"₹${GlobalState.currentUserWallet.toStringAsFixed(2)}\", Icons.account_balance_wallet, Colors.teal),\n"
        "                    _buildWalletCard(\"My Document Sales\"",
        "                    _buildWalletCard(\"Available Cash\", \"₹${GlobalState.currentUserWallet.toStringAsFixed(2)}\", Icons.account_balance_wallet, Colors.teal),\n"
        "                    _buildWalletCard(\"SanCoins\", \"${(userData?['sanCoins'] ?? 0)}\", Icons.stars_rounded, Colors.amber),\n"
        "                    _buildWalletCard(\"My Document Sales\"",
        "add SanCoins wallet card"
    ),
])

print("\nDone.")
