import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global_state.dart';
import '../models/academic_resource.dart';
import '../services/sancoin_service.dart';
import '../services/saved_resource_service.dart';
import 'support_screen.dart';
import 'auth/login_screen.dart';
import 'resource_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final GlobalState globalState;

  const ProfileScreen({super.key, required this.globalState});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'sansphere',
  );

  final _vaultFirestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'sanvault',
  );

  final SanCoinService _sanCoinService = SanCoinService.instance;
  final SavedResourceService _savedResourceService =
      SavedResourceService.instance;

  bool _isEditing = false;
  bool _showProfileDetails = false;
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

  Future<void> _saveProfileChanges(
    String uid, {
    bool payToEdit = false,
  }) async {
    setState(() => _isSaving = true);

    try {
      final result = await _sanCoinService.updateProfile(
        bio: _bioController.text,
        specification: _specController.text,
        college: _collegeController.text,
        branch: _branchController.text,
        year: _yearController.text,
        phoneNumber: _phoneController.text,
        showPhoneNumber: _showPhoneNumber,
        payToEdit: payToEdit,
      );

      if (!mounted) return;

      setState(() => _isEditing = false);

      final paidEdit = result['paidEdit'] == true;
      final cost = result['cost'] is num
          ? (result['cost'] as num).toInt()
          : 0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            paidEdit
                ? "Profile updated. $cost SanCoins used."
                : "Profile updated!",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'failed-precondition':
          message = e.message ??
              "Profile editing is currently unavailable.";
          break;
        case 'unauthenticated':
          message = "Please log in again.";
          break;
        case 'not-found':
          message = "Profile not found.";
          break;
        default:
          message = e.message ?? "Profile update failed.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Profile update failed: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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

  Widget _buildWalletCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  String _resourcePrice(AcademicResource resource) {
    if (resource.price <= 0) {
      return 'FREE';
    }

    return '${resource.price.toInt()} SanCoins';
  }

  Future<void> _openPurchasedResource(AcademicResource resource) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preparing your file...')));

      final url = await _sanCoinService.getPurchasedFileUrl(
        resource.id.isNotEmpty ? resource.id : resource.customDocId,
      );

      final uri = Uri.tryParse(url);

      if (uri == null) {
        throw Exception('Invalid download URL.');
      }

      final launched = kIsWeb
          ? await launchUrl(uri, webOnlyWindowName: '_self')
          : await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!launched) {
        throw Exception('Could not open the file.');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Could not open the purchased file. Please try again.',
          ),
          backgroundColor: Colors.redAccent,
          action: SnackBarAction(
            label: 'DETAILS',
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(e.toString())));
            },
          ),
        ),
      );
    }
  }

  Future<void> _deletePurchase(AcademicResource resource) async {
    final resourceId = resource.id.isNotEmpty
        ? resource.id
        : resource.customDocId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove from Purchases?'),
          content: const Text(
            'This will remove this resource from your Purchases list. '
            'The original resource will not be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _sanCoinService.deletePurchase(resourceId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from Your Purchases.'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not remove purchase: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _deleteUploadedResource(AcademicResource resource) async {
    final resourceId = resource.id.isNotEmpty
        ? resource.id
        : resource.customDocId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Upload Permanently?'),
          content: const Text(
            'This will permanently delete this upload from SanSphere, '
            'including the file, resource listing, and all purchase records '
            'associated with it.\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete Everywhere'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _sanCoinService.deleteUploadedResource(resourceId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload deleted everywhere successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete upload: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildResourceCard({
    required AcademicResource resource,
    required bool purchased,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: purchased
                      ? Colors.green.withValues(alpha: 0.10)
                      : Colors.blue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  purchased
                      ? Icons.library_books_rounded
                      : Icons.upload_file_rounded,
                  color: purchased ? Colors.green : Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.title.isEmpty
                          ? 'Untitled Resource'
                          : resource.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resource.subject.isEmpty
                          ? resource.category.displayName
                          : resource.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _smallChip(resource.category.displayName),
                        _smallChip(_resourcePrice(resource)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (purchased)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openPurchasedResource(resource),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Open / Download'),
                  ),
                )
              else
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteUploadedResource(resource),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete Upload'),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: purchased ? 'Remove from Purchases' : 'Delete Upload',
                onPressed: purchased
                    ? () => _deletePurchase(resource)
                    : () => _deleteUploadedResource(resource),
                color: Colors.red,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildPurchasesSection(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('purchases')
          .where('buyerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _emptySectionMessage(
            Icons.error_outline,
            'Could not load your purchases.',
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _emptySectionMessage(
            Icons.shopping_bag_outlined,
            'You have no purchases yet.',
          );
        }

        return Column(
          children: docs.map((purchaseDoc) {
            final data = purchaseDoc.data() as Map<String, dynamic>? ?? {};

            final resourceId = data['resourceId']?.toString() ?? '';

            if (resourceId.isEmpty) {
              return const SizedBox.shrink();
            }

            return FutureBuilder<DocumentSnapshot>(
              future: _vaultFirestore
                  .collection('academic_vault')
                  .doc(resourceId)
                  .get(),
              builder: (context, resourceSnapshot) {
                if (resourceSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Loading purchased resource...'),
                      ],
                    ),
                  );
                }

                if (!resourceSnapshot.hasData ||
                    !resourceSnapshot.data!.exists) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'This purchased resource is no longer available.',
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _deletePurchase(AcademicResource(id: resourceId)),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final resourceData =
                    resourceSnapshot.data!.data() as Map<String, dynamic>;

                resourceData['id'] = resourceSnapshot.data!.id;

                final resource = AcademicResource.fromMap(
                  resourceData,
                  resourceSnapshot.data!.id,
                );

                return _buildResourceCard(resource: resource, purchased: true);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildUploadsSection(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _vaultFirestore
          .collection('academic_vault')
          .where('uploaderId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _emptySectionMessage(
            Icons.error_outline,
            'Could not load your uploads.',
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _emptySectionMessage(
            Icons.cloud_upload_outlined,
            'You have not uploaded any resources yet.',
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            data['id'] = doc.id;

            final resource = AcademicResource.fromMap(data, doc.id);

            return _buildResourceCard(resource: resource, purchased: false);
          }).toList(),
        );
      },
    );
  }

  Widget _emptySectionMessage(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 15,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  void _openActivityPage(String uid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text("Your Activity"),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                "Your Activity",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                "Manage everything you've uploaded or purchased.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),

              _buildActivityOption(
                icon: Icons.cloud_upload_rounded,
                color: Colors.blue,
                title: "Your Uploads",
                subtitle: "View and manage resources you've uploaded",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        backgroundColor: const Color(0xFFF8FAFC),
                        appBar: AppBar(
                          title: const Text("Your Uploads"),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                        ),
                        body: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: _buildUploadsSection(uid),
                        ),
                      ),
                    ),
                  );
                },
              ),

              _buildActivityOption(
                icon: Icons.shopping_bag_rounded,
                color: Colors.green,
                title: "Your Purchases",
                subtitle: "View and access your purchased resources",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        backgroundColor: const Color(0xFFF8FAFC),
                        appBar: AppBar(
                          title: const Text("Your Purchases"),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                        ),
                        body: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: _buildPurchasesSection(uid),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditProfileDialog(String uid) async {
    final data = userData ?? {};
    final canEditFree = _canEditNow(data);

    if (!canEditFree) {
      if (!mounted) return;

      final coins = data['sanCoins'] is num
          ? (data['sanCoins'] as num).toInt()
          : 0;

      final shouldPay = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.lock_clock_rounded,
                  color: Color(0xFF2563EB),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text("Profile editing locked"),
                ),
              ],
            ),
            content: Text(
              "Your profile can normally be edited again after "
              "the 30-day cooldown.\n\n"
              "You can edit it now for 17 SanCoins.\n\n"
              "Current balance: $coins SanCoins",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton.icon(
                onPressed: coins < 17
                    ? null
                    : () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.stars_rounded, size: 18),
                label: const Text("Edit for 17"),
              ),
            ],
          );
        },
      );

      if (shouldPay != true || !mounted) return;

      _loadIntoControllers(data);

      setState(() {
        _isEditing = true;
        _showProfileDetails = true;
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return _buildEditProfileDialog(
            dialogContext,
            uid,
            payToEdit: true,
          );
        },
      );

      return;
    }

    _loadIntoControllers(data);

    if (mounted) {
      setState(() {
        _isEditing = true;
        _showProfileDetails = true;
      });
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _buildEditProfileDialog(
          dialogContext,
          uid,
          payToEdit: false,
        );
      },
    );
  }

  Widget _buildEditProfileDialog(
    BuildContext dialogContext,
    String uid, {
    required bool payToEdit,
  }) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF8FAFC),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  payToEdit
                      ? "Edit Profile • 17 SanCoins"
                      : "Edit Profile",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: "Close",
                onPressed: _isSaving
                    ? null
                    : () {
                        _isEditing = false;
                        Navigator.pop(dialogContext);
                      },
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Bio",
                      prefixIcon: const Icon(Icons.info_outline_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _specController,
                    decoration: InputDecoration(
                      labelText: "Specification",
                      prefixIcon: const Icon(Icons.school_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _collegeController,
                    decoration: InputDecoration(
                      labelText: "College",
                      prefixIcon: const Icon(Icons.account_balance_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _branchController,
                    decoration: InputDecoration(
                      labelText: "Branch",
                      prefixIcon: const Icon(Icons.category_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _yearController,
                    decoration: InputDecoration(
                      labelText: "Year",
                      prefixIcon: const Icon(Icons.calendar_month_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      prefixIcon: const Icon(Icons.phone_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      title: const Text(
                        "Show my phone number",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        "Visible to people I chat with",
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _showPhoneNumber,
                      onChanged: (value) {
                        setDialogState(() {
                          _showPhoneNumber = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      _isEditing = false;
                      Navigator.pop(dialogContext);
                    },
              child: const Text("Cancel"),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isSaving
                  ? null
                  : () async {
                      setDialogState(() {});
                      await _saveProfileChanges(
                        uid,
                        payToEdit: payToEdit,
                      );

                      if (!dialogContext.mounted) return;

                      if (!_isSaving && !_isEditing) {
                        Navigator.pop(dialogContext);
                      }

                      setDialogState(() {});
                    },
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(
                _isSaving
                    ? "Saving..."
                    : payToEdit
                        ? "Pay 17 & Save"
                        : "Save Changes",
              ),
            ),
          ],
        );
      },
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
        actions: [
          PopupMenuButton<String>(
            tooltip: "Profile menu",
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                ),
              ),
              child: const Icon(
                Icons.more_horiz_rounded,
                color: Color(0xFF2563EB),
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            offset: const Offset(0, 48),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditProfileDialog(uid);
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      backgroundColor: const Color(0xFFF8FAFC),
                      appBar: AppBar(
                        title: const Text("Settings"),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                      ),
                      body: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Account Settings",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  "Manage your SanSphere account preferences.",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            leading: const Icon(
                              Icons.person_outline_rounded,
                              color: Color(0xFF2563EB),
                            ),
                            title: const Text(
                              "Edit Profile",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                              "Update your profile information",
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 15,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _showEditProfileDialog(uid);
                            },
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            leading: const Icon(
                              Icons.logout_rounded,
                              color: Colors.redAccent,
                            ),
                            title: const Text(
                              "Logout",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text("Sign out of your account"),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 15,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _handleLogout();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, color: Color(0xFF2563EB)),
                    SizedBox(width: 12),
                    Text("Edit Profile"),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_rounded, color: Colors.black87),
                    SizedBox(width: 12),
                    Text("Settings"),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.redAccent),
                    SizedBox(width: 12),
                    Text("Logout"),
                  ],
                ),
              ),
            ],
          ),
        ],
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

          if (!_isEditing) {
            _loadIntoControllers(userData!);
          }

          final myEarnings = GlobalState.creatorEarnings[uid] ?? 0.0;

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
                        backgroundColor: const Color(
                          0xFF2563EB,
                        ).withValues(alpha: 0.1),
                        child: Text(
                          (userData!['fullName'] ?? '?').toString().isNotEmpty
                              ? userData!['fullName'][0]
                                    .toString()
                                    .toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        userData!['fullName'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userData!['email'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const SizedBox(height: 24),

                ListTile(
                  tileColor: Colors.blue.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(
                    Icons.history_rounded,
                    color: Colors.blue,
                  ),
                  title: const Text(
                    "Your Activity",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: const Text(
                    "View your uploads and purchased resources",
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                  ),
                  onTap: () => _openActivityPage(uid),
                ),

                const SizedBox(height: 28),

                /* WALLET
             */
                const Text(
                  "SanCoins & Wallet",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _buildWalletCard(
                      "Available Cash",
                      "₹${GlobalState.currentUserWallet.toStringAsFixed(2)}",
                      Icons.account_balance_wallet,
                      Colors.teal,
                    ),
                    _buildWalletCard(
                      "SanCoins",
                      "${userData?['sanCoins'] ?? 0}",
                      Icons.stars_rounded,
                      Colors.amber,
                    ),
                    _buildWalletCard(
                      "My Document Sales",
                      "₹${myEarnings.toStringAsFixed(2)}",
                      Icons.monetization_on,
                      Colors.purple,
                    ),
                    _buildWalletCard(
                      "Platform Processing Pool",
                      "₹${GlobalState.platformProcessingPool.toStringAsFixed(2)}",
                      Icons.admin_panel_settings,
                      Colors.blueGrey,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                ListTile(
                  tileColor: Colors.blueAccent.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(
                    Icons.card_giftcard,
                    color: Colors.blueAccent,
                  ),
                  title: const Text(
                    "Refer and Earn",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    "Your code: ${userData?['referralCode'] ?? '...'} • "
                    "Earn 100 SanCoins per signup",
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: _shareReferralCode,
                ),

                const SizedBox(height: 12),

                ListTile(
                  tileColor: Colors.grey.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(
                    Icons.support_agent,
                    color: Colors.black87,
                  ),
                  title: const Text(
                    "Contact Support",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text("Report an issue or send a suggestion"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SupportScreen()),
                    );
                  },
                ),

                if (_showProfileDetails) ...[
                  const SizedBox(height: 28),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Profile Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Bio: ${userData!['bio'] ?? ''}"),
                      const SizedBox(height: 6),
                      Text(
                        "Specification: "
                        "${userData!['specification'] ?? ''}",
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "College: "
                        "${userData!['college'] ?? ''}",
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Branch: "
                        "${userData!['branch'] ?? ''}",
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Year: "
                        "${userData!['year'] ?? ''}",
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _showPhoneNumber &&
                                (userData!['phoneNumber'] ?? '')
                                    .toString()
                                    .isNotEmpty
                            ? "Phone: "
                                  "${userData!['phoneNumber']} "
                                  "(visible to chat contacts)"
                            : "Phone: "
                                  "${(userData!['phoneNumber'] ?? '').toString().isEmpty ? 'not set' : 'hidden from others'}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
