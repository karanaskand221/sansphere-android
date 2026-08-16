import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../services/privacy_settings_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'sansphere',
  );

  String _profileVisibility = 'public';
  String _uploadedResourcesVisibility = 'public';
  String _purchasedResourcesVisibility = 'private';

  bool _showActivity = true;
  bool _allowMessages = true;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();

      final data = snapshot.data() ?? {};

      if (!mounted) return;

      setState(() {
        _profileVisibility = _profileValue(data['profileVisibility']);

        _uploadedResourcesVisibility = _resourceValue(
          data['uploadedResourcesVisibility'],
          'public',
        );

        _purchasedResourcesVisibility = _resourceValue(
          data['purchasedResourcesVisibility'],
          'private',
        );

        _showActivity = data['showActivity'] != false;

        _allowMessages = data['allowMessages'] != false;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load privacy settings: $e')),
      );
    }
  }

  String _profileValue(dynamic value) {
    return value == 'private' ? 'private' : 'public';
  }

  String _resourceValue(dynamic value, String fallback) {
    if (value == 'public' || value == 'followers' || value == 'private') {
      return value;
    }

    return fallback;
  }

  Future<void> _saveSettings() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      await PrivacySettingsService.instance.updatePrivacySettings(
        profileVisibility: _profileVisibility,
        uploadedResourcesVisibility: _uploadedResourcesVisibility,
        purchasedResourcesVisibility: _purchasedResourcesVisibility,
        showActivity: _showActivity,
        allowMessages: _allowMessages,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Privacy settings updated.')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save privacy settings: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 22, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _choiceCard({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final selected = value == groupValue;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: const Color(0xFF2563EB),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: const Color(0xFF2563EB)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        value: value,
        activeThumbColor: const Color(0xFF2563EB),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Privacy',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      'Profile Visibility',
                      'Control who can view your profile.',
                    ),

                    _choiceCard(
                      title: 'Public',
                      subtitle: 'Anyone can view your public profile.',
                      value: 'public',
                      groupValue: _profileVisibility,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _profileVisibility = value;
                        });
                      },
                    ),

                    _choiceCard(
                      title: 'Private',
                      subtitle: 'Only basic profile information is shown.',
                      value: 'private',
                      groupValue: _profileVisibility,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _profileVisibility = value;
                        });
                      },
                    ),

                    _sectionTitle(
                      'Uploaded Resources',
                      'Control who can see resources you upload.',
                    ),

                    _choiceCard(
                      title: 'Everyone',
                      subtitle: 'Everyone can see your shared resources.',
                      value: 'public',
                      groupValue: _uploadedResourcesVisibility,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _uploadedResourcesVisibility = value;
                        });
                      },
                    ),

                    _choiceCard(
                      title: 'Followers',
                      subtitle: 'Only users who follow you can see them.',
                      value: 'followers',
                      groupValue: _uploadedResourcesVisibility,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _uploadedResourcesVisibility = value;
                        });
                      },
                    ),

                    _choiceCard(
                      title: 'Only me',
                      subtitle: 'Hide your uploaded resources from others.',
                      value: 'private',
                      groupValue: _uploadedResourcesVisibility,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _uploadedResourcesVisibility = value;
                        });
                      },
                    ),

                    _sectionTitle(
                      'Purchased Resources',
                      'Control who can see your purchased resources.',
                    ),

                    _choiceCard(
                      title: 'Everyone',
                      subtitle:
                          'Everyone can see your purchased-resource activity.',
                      value: 'public',
                      groupValue: _purchasedResourcesVisibility,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _purchasedResourcesVisibility = value;
                        });
                      },
                    ),

                    _choiceCard(
                      title: 'Followers',
                      subtitle: 'Only your followers can see it.',
                      value: 'followers',
                      groupValue: _purchasedResourcesVisibility,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _purchasedResourcesVisibility = value;
                        });
                      },
                    ),

                    _choiceCard(
                      title: 'Only me',
                      subtitle: 'Keep your purchases private.',
                      value: 'private',
                      groupValue: _purchasedResourcesVisibility,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _purchasedResourcesVisibility = value;
                        });
                      },
                    ),

                    _sectionTitle(
                      'Activity',
                      'Control whether your profile activity is visible.',
                    ),

                    _switchTile(
                      icon: Icons.visibility_outlined,
                      title: 'Show my activity',
                      subtitle:
                          'Allow others to see eligible profile activity.',
                      value: _showActivity,
                      onChanged: (value) {
                        setState(() {
                          _showActivity = value;
                        });
                      },
                    ),

                    _sectionTitle(
                      'Messages',
                      'Control whether other users can start a chat with you.',
                    ),

                    _switchTile(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Allow messages',
                      subtitle: 'Allow other users to message you.',
                      value: _allowMessages,
                      onChanged: (value) {
                        setState(() {
                          _allowMessages = value;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Privacy Settings',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
