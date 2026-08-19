import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../global_state.dart';
import '../models/academic_resource.dart';
import '../services/social_profile_service.dart';
import '../theme/app_colors.dart';
import 'resource_detail_screen.dart';

class DiscoverDownloadsScreen extends StatelessWidget {
  final GlobalState globalState;

  const DiscoverDownloadsScreen({super.key, required this.globalState});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view your downloads.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Downloads',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: SocialProfileService.instance.getVisibleProfileResources(
          targetUid: uid,
          resourceType: 'purchased',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const _DownloadsEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Unable to load downloads',
              subtitle: 'Please try again in a moment.',
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const _DownloadsEmptyState(
              icon: Icons.download_for_offline_outlined,
              title: 'No downloads yet',
              subtitle:
                  'Purchased resources that are available to you will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = Map<String, dynamic>.from(items[index]);

              final resourceId =
                  (data['id'] ??
                          data['resourceId'] ??
                          data['customDocId'] ??
                          '')
                      .toString();

              if (resourceId.isEmpty) {
                return const SizedBox.shrink();
              }

              final resource = AcademicResource.fromMap(data, resourceId);

              return _DownloadCard(
                resource: resource,
                onOpen: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ResourceDetailScreen(
                        resource: resource,
                        globalState: globalState,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  final AcademicResource resource;
  final VoidCallback onOpen;

  const _DownloadCard({required this.resource, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.lock_rounded, color: Color(0xFF059669)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.title.isEmpty
                          ? 'Purchased Resource'
                          : resource.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Purchased • Secure access',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DownloadsEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.primary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
