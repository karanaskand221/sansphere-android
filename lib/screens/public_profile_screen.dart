import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/social_profile_service.dart';
import 'public_profile_resources_screen.dart';
import 'profile_reviews_screen.dart';
import 'chat_list_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final SocialProfileService _socialProfileService =
      SocialProfileService.instance;

  bool _isFollowing = false;
  bool _isLoadingFollowState = true;
  bool _isFollowActionLoading = false;

  bool _isProfileLoading = true;
  String? _profileError;
  Map<String, dynamic>? _profileData;

  bool get _isOwnProfile =>
      FirebaseAuth.instance.currentUser?.uid == widget.userId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadFollowingState();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _socialProfileService.getPublicProfile(widget.userId);

      if (!mounted) return;

      setState(() {
        _profileData = data;
        _profileError = null;
        _isProfileLoading = false;
      });
    } catch (e) {
      debugPrint('Unable to load public profile: $e');

      if (!mounted) return;

      setState(() {
        _profileError = 'Unable to load profile.';
        _isProfileLoading = false;
      });
    }
  }

  Future<void> _loadFollowingState() async {
    if (_isOwnProfile) {
      if (mounted) {
        setState(() {
          _isLoadingFollowState = false;
        });
      }
      return;
    }

    try {
      final following = await _socialProfileService.isFollowing(widget.userId);

      if (!mounted) return;

      setState(() {
        _isFollowing = following;
        _isLoadingFollowState = false;
      });
    } catch (e) {
      debugPrint('Unable to load following state: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingFollowState = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_isOwnProfile || _isFollowActionLoading) {
      return;
    }

    setState(() {
      _isFollowActionLoading = true;
    });

    try {
      if (_isFollowing) {
        await _socialProfileService.unfollowUser(widget.userId);
      } else {
        await _socialProfileService.followUser(widget.userId);
      }

      if (!mounted) return;

      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update follow status.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFollowActionLoading = false;
        });
      }
    }
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
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
    );
  }

  Widget _buildMessageButton(String peerName) {
    if (_isOwnProfile) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: () {
          startChatWithUser(
            context,
            peerUid: widget.userId,
            peerName: peerName.isNotEmpty ? peerName : 'Sansphere User',
            docTitle: 'Profile',
            docId: 'profile_${widget.userId}',
          );
        },
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: const Text('Message'),
      ),
    );
  }

  Widget _buildProfileAction() {
    if (_isOwnProfile) {
      return const SizedBox.shrink();
    }

    if (_isLoadingFollowState) {
      return const SizedBox(
        height: 44,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: _isFollowActionLoading ? null : _toggleFollow,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _isFollowing
              ? Colors.white
              : const Color(0xFF2563EB),
          foregroundColor: _isFollowing
              ? const Color(0xFF0F172A)
              : Colors.white,
          side: _isFollowing
              ? const BorderSide(color: Color(0xFFE2E8F0))
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isFollowActionLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                _isFollowing ? 'Following' : 'Follow',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Widget _buildContentSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF2563EB)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: _isProfileLoading
          ? const Center(child: CircularProgressIndicator())
          : _profileError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_off_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(_profileError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isProfileLoading = true;
                          _profileError = null;
                        });
                        _loadProfile();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _profileData == null
          ? const Center(child: Text('Profile not found.'))
          : _buildProfileFromData(_profileData!),
    );
  }

  Widget _buildProfileFromData(Map<String, dynamic> data) {
    final fullName = (data['fullName'] ?? 'Sansphere User').toString();

    final username = (data['username'] ?? '').toString();

    final bio = (data['bio'] ?? '').toString();

    final college = (data['college'] ?? '').toString();

    final branch = (data['branch'] ?? '').toString();

    final year = (data['year'] ?? '').toString();

    final photoUrl = (data['profilePhotoUrl'] ?? '').toString();

    final followers = (data['followersCount'] ?? 0).toString();

    final following = (data['followingCount'] ?? 0).toString();

    final reviews = (data['reviewsCount'] ?? 0).toString();

    final canViewProfile = data['canViewProfile'] == true;

    final canViewUploadedResources = data['canViewUploadedResources'] == true;

    final canViewPurchasedResources = data['canViewPurchasedResources'] == true;

    final canViewActivity = data['canViewActivity'] == true;

    final allowMessages = data['allowMessages'] == true;

    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFFEFF6FF),
              backgroundImage: photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl.isEmpty
                  ? Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                      ),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 14),

          Center(
            child: Text(
              fullName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),

          if (username.isNotEmpty) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                '@$username',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          Row(
            children: [
              _buildStat(followers, 'Followers'),
              _buildStat(following, 'Following'),
              _buildStat(reviews, 'Reviews'),
            ],
          ),

          const SizedBox(height: 20),

          _buildProfileAction(),

          if (!_isOwnProfile && allowMessages) ...[
            const SizedBox(height: 10),
            _buildMessageButton(fullName),
          ],

          if (!canViewProfile && !_isOwnProfile) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: Colors.grey),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This profile is private.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (canViewProfile && bio.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(bio, style: const TextStyle(fontSize: 14, height: 1.4)),
          ],

          if (canViewProfile &&
              (college.isNotEmpty || branch.isNotEmpty || year.isNotEmpty)) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (college.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.school_outlined, size: 16),
                    label: Text(college),
                  ),
                if (branch.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.menu_book_outlined, size: 16),
                    label: Text(branch),
                  ),
                if (year.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(year),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),

          if (canViewUploadedResources)
            _buildContentSection(
              icon: Icons.upload_file_rounded,
              title: 'Resources Uploaded',
              subtitle: 'Resources shared by this profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicProfileResourcesScreen(
                      userId: widget.userId,
                      resourceType: 'uploaded',
                      title: 'Resources Uploaded',
                    ),
                  ),
                );
              },
            ),

          if (canViewPurchasedResources)
            _buildContentSection(
              icon: Icons.shopping_bag_outlined,
              title: 'Purchased Resources',
              subtitle: 'Resources purchased by this profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicProfileResourcesScreen(
                      userId: widget.userId,
                      resourceType: 'purchased',
                      title: 'Purchased Resources',
                    ),
                  ),
                );
              },
            ),

          if (canViewActivity)
            _buildContentSection(
              icon: Icons.star_outline_rounded,
              title: 'Reviews',
              subtitle: 'Reviews given to this profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileReviewsScreen(
                      profileUid: widget.userId,
                      profileName: fullName,
                      canReview: !_isOwnProfile,
                    ),
                  ),
                );
              },
            ),

          if (!canViewUploadedResources &&
              !canViewPurchasedResources &&
              !canViewActivity)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No public activity is available.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
