import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../global_state.dart';

import 'public_profile_screen.dart';
import '../services/social_profile_service.dart';

class FollowingScreen extends StatelessWidget {
  final String userId;
  final GlobalState globalState;

  const FollowingScreen({
    super.key,
    required this.userId,
    required this.globalState,
  });

  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(
    app: FirebaseAuth.instance.app,
    databaseId: 'sansphere',
  );

  Future<List<Map<String, dynamic>>> _loadUsers() async {
    final relationSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .orderBy('createdAt', descending: true)
        .get();

    final ids = relationSnap.docs
        .map((doc) => (doc.data()['userId'] ?? doc.id).toString())
        .where((id) => id.isNotEmpty)
        .toList();

    if (ids.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final socialUsers = await SocialProfileService.instance.getSocialUsers(ids);

    final byUid = <String, Map<String, dynamic>>{
      for (final user in socialUsers)
        if ((user['uid'] ?? '').toString().isNotEmpty)
          user['uid'].toString(): user,
    };

    return [
      for (final id in ids)
        if (byUid.containsKey(id)) byUid[id]!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Following',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const _FollowingMessage(
              icon: Icons.error_outline_rounded,
              message: 'Unable to load following.',
            );
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const _FollowingMessage(
              icon: Icons.person_add_alt_1_rounded,
              message: 'You are not following anyone yet.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = users[index];

              return _FollowingUserTile(
                uid: data['uid'].toString(),
                name: _displayName(data),
                username: (data['username'] ?? '').toString().trim(),
                photoUrl: (data['profilePhotoUrl'] ?? '').toString().trim(),
                globalState: globalState,
              );
            },
          );
        },
      ),
    );
  }

  static String _displayName(Map<String, dynamic> data) {
    final name = (data['fullName'] ?? '').toString().trim();
    return name.isEmpty ? 'SansSphere User' : name;
  }
}

class _FollowingUserTile extends StatelessWidget {
  final String uid;
  final String name;
  final String username;
  final String photoUrl;
  final GlobalState globalState;

  const _FollowingUserTile({
    required this.uid,
    required this.name,
    required this.username,
    required this.photoUrl,
    required this.globalState,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PublicProfileScreen(
                userId: uid,
                globalState: globalState,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFEFF6FF),
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2563EB),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        '@$username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowingMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _FollowingMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: Colors.grey),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
