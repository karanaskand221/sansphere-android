import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'followers_screen.dart';
import 'following_screen.dart';
import 'profile_reviews_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global_state.dart';
import '../models/academic_resource.dart';
import '../services/sancoin_service.dart';
import '../services/saved_resource_service.dart';
import '../services/social_profile_service.dart';
import 'resource_detail_screen.dart';
import 'support_screen.dart';
import 'auth/login_screen.dart';
import 'privacy_settings_screen.dart';
import 'wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  final GlobalState globalState;

  const ProfileScreen({super.key, required this.globalState});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _vaultFirestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'sanvault',
  );

  final SanCoinService _sanCoinService = SanCoinService.instance;
  final SavedResourceService _savedResourceService =
      SavedResourceService.instance;

  final SocialProfileService _socialProfileService =
      SocialProfileService.instance;

  bool _isEditing = false;
  bool _isSaving = false;
  Map<String, dynamic>? userData;

  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _specController = TextEditingController();
  final _collegeController = TextEditingController();
  final _branchController = TextEditingController();
  final _yearController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _showPhoneNumber = false;

  bool _checkingUsername = false;
  bool? _usernameAvailable;
  String _usernameAvailabilityMessage = '';

  bool _isUploadingProfilePhoto = false;

  Future<Map<String, dynamic>>? _profileFuture;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      _profileFuture = _socialProfileService.getPublicProfile(uid);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _specController.dispose();
    _collegeController.dispose();
    _branchController.dispose();
    _yearController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadIntoControllers(Map<String, dynamic> data) {
    _usernameController.text = (data['username'] ?? '').toString().trim();
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

  Future<void> _changeProfilePhoto() async {
    if (_isUploadingProfilePhoto) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to change your profile photo.'),
        ),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Profile Photo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose how you want to add your photo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  title: const Text(
                    'Take a photo',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  title: const Text(
                    'Choose from gallery',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null || !mounted) return;

    setState(() {
      _isUploadingProfilePhoto = true;
    });

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        if (mounted) {
          setState(() {
            _isUploadingProfilePhoto = false;
          });
        }
        return;
      }

      final bytes = await pickedFile.readAsBytes();

      const maxSize = 5 * 1024 * 1024;

      if (bytes.isEmpty) {
        throw Exception('The selected image is empty.');
      }

      if (bytes.length > maxSize) {
        throw Exception('Profile photo must be 5 MB or smaller.');
      }

      final mimeType = pickedFile.mimeType?.toLowerCase() ?? '';

      if (mimeType.isNotEmpty && !mimeType.startsWith('image/')) {
        throw Exception('Please select a valid image file.');
      }

      final storage = FirebaseStorage.instanceFor(
        app: Firebase.app(),
        bucket: 'gen-lang-client-0227443307.firebasestorage.app',
      );

      final storagePath = 'profile_photos/${user.uid}/profile.jpg';

      final storageRef = storage.ref().child(storagePath);

      final metadata = SettableMetadata(
        contentType: mimeType.startsWith('image/') ? mimeType : 'image/jpeg',
        customMetadata: {'ownerUid': user.uid, 'purpose': 'profile_photo'},
      );

      await user.getIdToken(true);

      final uploadTask = storageRef.putData(bytes, metadata);

      await uploadTask;

      final functions = FirebaseFunctions.instanceFor(
        app: Firebase.app(),
        region: 'us-central1',
      );

      final result = await functions.httpsCallable('setProfilePhoto').call();

      final data = result.data;

      if (data is! Map ||
          data['success'] != true ||
          data['profilePhotoUrl'] == null) {
        throw Exception('Profile photo could not be saved.');
      }

      if (!mounted) return;

      setState(() {
        _isUploadingProfilePhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'PROFILE PHOTO FUNCTION ERROR: '
        '${e.code}: ${e.message}',
      );

      if (!mounted) return;

      setState(() {
        _isUploadingProfilePhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Could not save your profile photo.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'PROFILE PHOTO STORAGE ERROR: '
        '${e.code}: ${e.message}',
      );

      if (!mounted) return;

      setState(() {
        _isUploadingProfilePhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Could not upload your profile photo.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      debugPrint('PROFILE PHOTO ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isUploadingProfilePhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _checkUsernameAvailability() async {
    final username = _usernameController.text.trim().toLowerCase();

    if (username.isEmpty) {
      if (!mounted) return;

      setState(() {
        _usernameAvailable = null;
        _usernameAvailabilityMessage = '';
      });
      return;
    }

    setState(() {
      _checkingUsername = true;
      _usernameAvailable = null;
      _usernameAvailabilityMessage = '';
    });

    try {
      final result = await _socialProfileService.checkUsernameAvailability(
        username,
      );

      if (!mounted) return;

      final available = result['available'] == true;
      final reason = (result['reason'] ?? '').toString().trim();

      setState(() {
        _usernameAvailable = available;
        _usernameAvailabilityMessage = available
            ? 'Username is available.'
            : (reason.isEmpty ? 'That username is already taken.' : reason);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _usernameAvailable = null;
        _usernameAvailabilityMessage = 'Could not check username right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _checkingUsername = false;
        });
      }
    }
  }

  Future<void> _saveProfileChanges(String uid, {bool payToEdit = false}) async {
    final username = _usernameController.text.trim().toLowerCase();

    if (username.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Username is required.')));
      return;
    }

    if (_usernameAvailable == false) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose an available username.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final result = await _sanCoinService.updateProfile(
        username: username,
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
      final cost = result['cost'] is num ? (result['cost'] as num).toInt() : 0;

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
          message = e.message ?? "Profile editing is currently unavailable.";
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
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _socialProfileService.getVisibleProfileResources(
        targetUid: uid,
        resourceType: 'purchased',
      ),
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

        final resources = snapshot.data ?? <Map<String, dynamic>>[];

        if (resources.isEmpty) {
          return _emptySectionMessage(
            Icons.shopping_bag_outlined,
            'You have no purchases yet.',
          );
        }

        return Column(
          children: resources.map((resourceData) {
            final resourceId =
                resourceData['resourceId']?.toString().trim() ?? '';

            if (resourceId.isEmpty) {
              return const SizedBox.shrink();
            }

            final normalizedData = Map<String, dynamic>.from(resourceData);

            normalizedData['id'] = resourceId;

            try {
              final resource = AcademicResource.fromMap(
                normalizedData,
                resourceId,
              );

              return _buildResourceCard(resource: resource, purchased: true);
            } catch (_) {
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
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ],
                ),
              );
            }
          }).toList(),
        );
      },
    );
  }

  Widget _buildSavedResourcesSection() {
    try {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _savedResourceService.streamSavedResources(),
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
              'Could not load your saved resources.',
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _emptySectionMessage(
              Icons.bookmark_border_rounded,
              'You have no saved resources yet.',
            );
          }

          return Column(
            children: docs.map((savedDoc) {
              final data = savedDoc.data();
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
                          Text('Loading saved resource...'),
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
                              'This saved resource is no longer available.',
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove',
                            onPressed: () async {
                              try {
                                await _savedResourceService.removeSavedResource(
                                  resourceId,
                                );
                              } catch (_) {}
                            },
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

                  return _buildSavedResourceCard(resource);
                },
              );
            }).toList(),
          );
        },
      );
    } catch (e) {
      return _emptySectionMessage(
        Icons.error_outline,
        'Could not load your saved resources.',
      );
    }
  }

  Widget _buildSavedResourceCard(AcademicResource resource) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResourceDetailScreen(
                      resource: resource,
                      globalState: widget.globalState,
                    ),
                  ),
                );
              },
              child: _buildResourceCard(resource: resource, purchased: false),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: IconButton(
                tooltip: 'Remove from Saved',
                onPressed: () async {
                  try {
                    await _savedResourceService.removeSavedResource(
                      resource.id,
                    );
                  } catch (e) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not remove saved resource: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                icon: const Icon(
                  Icons.bookmark_rounded,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ),
        ],
      ),
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
                icon: Icons.bookmark_rounded,
                color: Colors.indigo,
                title: "Saved Resources",
                subtitle: "View resources you've bookmarked",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        backgroundColor: const Color(0xFFF8FAFC),
                        appBar: AppBar(
                          title: const Text("Saved Resources"),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                        ),
                        body: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: _buildSavedResourcesSection(),
                        ),
                      ),
                    ),
                  );
                },
              ),

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
                Icon(Icons.lock_clock_rounded, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Expanded(child: Text("Profile editing locked")),
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
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return _buildEditProfileDialog(dialogContext, uid, payToEdit: true);
        },
      );

      return;
    }

    _loadIntoControllers(data);

    if (mounted) {
      setState(() {
        _isEditing = true;
      });
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _buildEditProfileDialog(dialogContext, uid, payToEdit: false);
      },
    );
  }

  void _showProfileDetailsDialog() {
    final data = userData ?? {};

    final bio = (data['bio'] ?? '').toString().trim();
    final specification = (data['specification'] ?? '').toString().trim();
    final college = (data['college'] ?? '').toString().trim();
    final branch = (data['branch'] ?? '').toString().trim();
    final year = (data['year'] ?? '').toString().trim();
    final phone = (data['phoneNumber'] ?? '').toString().trim();
    final showPhone = data['showPhoneNumber'] == true;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
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
                  Icons.badge_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Profile Details",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: "Close",
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileDetailRow(
                    Icons.info_outline_rounded,
                    "Bio",
                    bio.isEmpty ? "Not set" : bio,
                  ),
                  _buildProfileDetailRow(
                    Icons.school_rounded,
                    "Specification",
                    specification.isEmpty ? "Not set" : specification,
                  ),
                  _buildProfileDetailRow(
                    Icons.account_balance_rounded,
                    "College",
                    college.isEmpty ? "Not set" : college,
                  ),
                  _buildProfileDetailRow(
                    Icons.category_rounded,
                    "Branch",
                    branch.isEmpty ? "Not set" : branch,
                  ),
                  _buildProfileDetailRow(
                    Icons.calendar_month_rounded,
                    "Year",
                    year.isEmpty ? "Not set" : year,
                  ),
                  _buildProfileDetailRow(
                    Icons.phone_rounded,
                    "Phone",
                    phone.isEmpty
                        ? "Not set"
                        : showPhone
                        ? "$phone (visible to chat contacts)"
                        : "Hidden from others",
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                child: const Icon(Icons.edit_rounded, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  payToEdit ? "Edit Profile • 17 SanCoins" : "Edit Profile",
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
                    controller: _usernameController,
                    maxLength: 30,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_usernameAvailable != null ||
                          _usernameAvailabilityMessage.isNotEmpty) {
                        setState(() {
                          _usernameAvailable = null;
                          _usernameAvailabilityMessage = '';
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: "Username",
                      hintText: "your_username",
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                      prefixText: "@",
                      filled: true,
                      suffixIcon: _checkingUsername
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              tooltip: "Check username",
                              onPressed: _checkUsernameAvailability,
                              icon: Icon(
                                _usernameAvailable == true
                                    ? Icons.check_circle_rounded
                                    : _usernameAvailable == false
                                    ? Icons.cancel_rounded
                                    : Icons.search_rounded,
                                color: _usernameAvailable == true
                                    ? Colors.green
                                    : _usernameAvailable == false
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            ),
                      fillColor: Colors.white,
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (_usernameAvailabilityMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        top: 6,
                        bottom: 4,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _usernameAvailabilityMessage,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _usernameAvailable == true
                                ? Colors.green
                                : _usernameAvailable == false
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
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
                      await _saveProfileChanges(uid, payToEdit: payToEdit);

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
                      child: CircularProgressIndicator(strokeWidth: 2),
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

  Widget _buildProfileStat(
    String value,
    String label, {
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (sheetContext) {
                  return SafeArea(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Settings',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ListTile(
                            leading: const Icon(Icons.edit_rounded),
                            title: const Text('Edit Profile'),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _showEditProfileDialog(uid);
                            },
                          ),

                          ListTile(
                            leading: const Icon(Icons.lock_outline_rounded),
                            title: const Text('Privacy'),
                            subtitle: const Text(
                              'Control your profile and activity visibility',
                            ),
                            onTap: () {
                              Navigator.pop(sheetContext);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PrivacySettingsScreen(),
                                ),
                              );
                            },
                          ),

                          ListTile(
                            leading: const Icon(Icons.card_giftcard_rounded),
                            title: const Text('Refer and Earn'),
                            subtitle: Text(
                              'Code: ${userData?['referralCode'] ?? '...'}',
                            ),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _shareReferralCode();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.support_agent_rounded),
                            title: const Text('Contact Support'),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SupportScreen(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.logout_rounded,
                              color: Colors.redAccent,
                            ),
                            title: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _handleLogout();
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load profile.\\n\\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Profile not found."));
          }

          userData = snapshot.data!;

          if (!_isEditing) {
            _loadIntoControllers(userData!);
          }

          final fullName = (userData!['fullName'] ?? '').toString().trim();
          final username = (userData!['username'] ?? '').toString().trim();
          final bio = (userData!['bio'] ?? '').toString().trim();
          final college = (userData!['college'] ?? '').toString().trim();
          final branch = (userData!['branch'] ?? '').toString().trim();
          final year = (userData!['year'] ?? '').toString().trim();
          final profilePhotoUrl = (userData!['profilePhotoUrl'] ?? '')
              .toString()
              .trim();

          final followersCount = (userData!['followersCount'] ?? 0).toString();
          final followingCount = (userData!['followingCount'] ?? 0).toString();
          final reviewsCount = (userData!['reviewsCount'] ?? 0).toString();

          final academicLine = [
            if (college.isNotEmpty) college,
            if (branch.isNotEmpty) branch,
            if (year.isNotEmpty) year,
          ].join(' • ');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: const Color(0xFFEFF6FF),
                            child: profilePhotoUrl.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      profilePhotoUrl,
                                      width: 104,
                                      height: 104,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Center(
                                              child: Text(
                                                fullName.isNotEmpty
                                                    ? fullName[0].toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  fontSize: 34,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF2563EB),
                                                ),
                                              ),
                                            );
                                          },
                                    ),
                                  )
                                : Text(
                                    fullName.isNotEmpty
                                        ? fullName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                          ),
                          Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: _isUploadingProfilePhoto
                                  ? null
                                  : _changeProfilePhoto,
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: _isUploadingProfilePhoto
                                    ? const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 18,
                                        color: Color(0xFF2563EB),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        fullName.isEmpty ? 'Your Name' : fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (username.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '@$username',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (academicLine.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          academicLine,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            bio,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    _buildProfileStat(
                      followersCount,
                      'Followers',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FollowersScreen(
                              userId: uid,
                              globalState: widget.globalState,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildProfileStat(
                      followingCount,
                      'Following',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FollowingScreen(
                              userId: uid,
                              globalState: widget.globalState,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildProfileStat(
                      reviewsCount,
                      'Reviews',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileReviewsScreen(
                              profileUid: uid,
                              profileName: fullName,
                              canReview: false,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditProfileDialog(uid),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text(
                      'Edit Profile',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

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
                    "Manage your saved, uploaded and purchased resources",
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                  ),
                  onTap: () => _openActivityPage(uid),
                ),

                const SizedBox(height: 28),

                const SizedBox(height: 28),

                // ==========================================================
                // WALLET
                // Everything related to SanCoins/payments lives inside
                // the dedicated Wallet screen.
                // ==========================================================
                ListTile(
                  tileColor: const Color(0xFF2563EB).withValues(alpha: 0.10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF60A5FA),
                    ),
                  ),
                  title: const Text(
                    "Wallet",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  subtitle: Text(
                    "${userData?['sanCoins'] ?? 0} SanCoins • Payments & transactions",
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WalletScreen()),
                    );
                  },
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
              ],
            ),
          );
        },
      ),
    );
  }
}
