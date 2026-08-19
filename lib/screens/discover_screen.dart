import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import 'marketplace_feed.dart';
import 'discover_downloads_screen.dart';
import 'discover_saved_resources_screen.dart';
import '../global_state.dart';
import 'discover_admin_screen.dart';
import '../widgets/ambient_background.dart';

class DiscoverScreen extends StatelessWidget {
  final GlobalState globalState;

  const DiscoverScreen({super.key, required this.globalState});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = ((screenWidth - 1320.0) / 2).clamp(
      16.0,
      double.infinity,
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              18,
              horizontalPadding,
              110,
            ),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Discover',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "What's happening across SanSphere",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (DiscoverAdminScreen.isAdmin(
                    FirebaseAuth.instance.currentUser,
                  ))
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DiscoverAdminScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.borderStrong.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.admin_panel_settings_rounded,
                                size: 18,
                                color: AppColors.textPrimary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Manage',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              const _BannerSection(),

              const SizedBox(height: 24),

              _SectionTitle(
                title: 'Quick Access',
                subtitle: 'Jump directly to what you need',
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.search_rounded,
                      title: 'Search',
                      subtitle: 'Resources',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MarketplaceFeedScreen(globalState: globalState),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.bookmark_rounded,
                      title: 'Saved',
                      subtitle: 'Resources',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DiscoverSavedResourcesScreen(
                              globalState: globalState,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.download_rounded,
                      title: 'Downloads',
                      subtitle: 'Your files',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DiscoverDownloadsScreen(
                              globalState: globalState,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              _SectionTitle(
                title: "What's Happening",
                subtitle: 'Important things happening on SanSphere',
              ),
              const SizedBox(height: 12),

              _DiscoverCollection(
                collection: 'discover_announcements',
                emptyIcon: Icons.campaign_outlined,
                emptyTitle: 'No announcements yet',
                emptySubtitle:
                    'Important SanSphere announcements will appear here.',
              ),

              const SizedBox(height: 10),

              _DiscoverCollection(
                collection: 'discover_opportunities',
                emptyIcon: Icons.emoji_events_outlined,
                emptyTitle: 'No opportunities yet',
                emptySubtitle:
                    'Events, competitions and opportunities will appear here.',
              ),

              const SizedBox(height: 28),

              _SectionTitle(
                title: 'Featured SanSphere',
                subtitle: 'Special content selected for the community',
              ),
              const SizedBox(height: 12),

              _DiscoverCollection(
                collection: 'discover_featured',
                emptyIcon: Icons.auto_awesome_outlined,
                emptyTitle: 'Featured content coming soon',
                emptySubtitle: 'Featured SanSphere content will appear here.',
                featured: true,
              ),

              const SizedBox(height: 28),

              _SectionTitle(
                title: 'Community',
                subtitle: 'People and activity worth discovering',
              ),
              const SizedBox(height: 12),

              _CommunityCard(),

              const SizedBox(height: 28),

              _SectionTitle(
                title: 'SanSphere Updates',
                subtitle: "What's new in the application",
              ),
              const SizedBox(height: 12),

              _DiscoverCollection(
                collection: 'discover_updates',
                emptyIcon: Icons.new_releases_outlined,
                emptyTitle: 'No new updates',
                emptySubtitle:
                    'New SanSphere features and improvements will appear here.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.35,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.borderStrong.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF60A5FA)),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdBadge extends StatelessWidget {
  const _AdBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: const Text(
        'FEATURED',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _BannerSection extends StatelessWidget {
  const _BannerSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('discover_banners')
          .where('active', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _DefaultBanner();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const _DefaultBanner();
        }

        final docs = [...snapshot.data!.docs];

        docs.sort((a, b) {
          final aPriority = (a.data()['priority'] as num?)?.toInt() ?? 0;
          final bPriority = (b.data()['priority'] as num?)?.toInt() ?? 0;

          if (aPriority != bPriority) {
            return bPriority.compareTo(aPriority);
          }

          return 0;
        });

        return Column(
          children: [
            for (final doc in docs.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BannerCard(data: doc.data()),
              ),
          ],
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _BannerCard({required this.data});

  Future<void> _openDestination(
    BuildContext context,
    String destinationUrl,
  ) async {
    if (destinationUrl.isEmpty) return;

    final uri = Uri.tryParse(destinationUrl);

    if (uri == null ||
        !uri.hasScheme ||
        !(uri.scheme == 'http' || uri.scheme == 'https')) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid destination URL.')));
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this destination.')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this destination.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] ?? 'SanSphere').toString().trim();
    final subtitle = (data['subtitle'] ?? '').toString().trim();
    final description = (data['description'] ?? '').toString().trim();
    final imageUrl = (data['imageUrl'] ?? '').toString().trim();
    final destinationUrl = (data['destinationUrl'] ?? '').toString().trim();

    final secondaryText = subtitle.isNotEmpty
        ? subtitle
        : description.isNotEmpty
        ? description
        : 'Discover something new on SanSphere.';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: destinationUrl.isEmpty
            ? null
            : () => _openDestination(context, destinationUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: AspectRatio(
            aspectRatio: 4 / 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Uploaded banners are normalized to 4:1 by the
                // admin crop editor, so this image fills the banner.
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),

                if (imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;

                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF172554),
                              Color(0xFF312E81),
                              Color(0xFF1E1B4B),
                            ],
                          ),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF172554),
                              Color(0xFF312E81),
                              Color(0xFF1E1B4B),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.textSecondary,
                          size: 42,
                        ),
                      );
                    },
                  )
                else
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF172554),
                          Color(0xFF312E81),
                          Color(0xFF1E1B4B),
                        ],
                      ),
                    ),
                  ),

                // Readability overlay.
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black12, Colors.black26, Colors.black87],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(21),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Text(
                              'FEATURED',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (destinationUrl.isNotEmpty)
                            const Icon(
                              Icons.open_in_new_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        title.isEmpty ? 'SanSphere' : title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 23,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        secondaryText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DefaultBanner extends StatelessWidget {
  const _DefaultBanner();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 1,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF172554), Color(0xFF312E81), Color(0xFF1E1B4B)],
          ),
          border: Border.all(
            color: AppColors.borderStrong.withValues(alpha: 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -35,
              top: -35,
              child: Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(21),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AdBadge(),
                  Spacer(),
                  Text(
                    'SanSphere',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Featured announcements & promotions',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverCollection extends StatelessWidget {
  final String collection;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final bool featured;

  const _DiscoverCollection({
    required this.collection,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where(
            collection == 'discover_banners' ? 'active' : 'published',
            isEqualTo: true,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return _EmptyDiscoverCard(
            icon: emptyIcon,
            title: emptyTitle,
            subtitle: emptySubtitle,
          );
        }

        final docs = [...snapshot.data!.docs];

        docs.sort((a, b) {
          final aPriority = (a.data()['priority'] as num?)?.toInt() ?? 0;
          final bPriority = (b.data()['priority'] as num?)?.toInt() ?? 0;

          if (aPriority != bPriority) {
            return bPriority.compareTo(aPriority);
          }

          final aCreated = a.data()['createdAt'];
          final bCreated = b.data()['createdAt'];

          if (aCreated is Timestamp && bCreated is Timestamp) {
            return bCreated.compareTo(aCreated);
          }

          return 0;
        });

        return Column(
          children: [
            for (final doc in docs)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DiscoverContentCard(
                  data: doc.data(),
                  featured: featured,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DiscoverContentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool featured;

  const _DiscoverContentCard({required this.data, required this.featured});

  Future<void> _openDestination(
    BuildContext context,
    String destinationUrl,
  ) async {
    if (destinationUrl.isEmpty) return;

    final uri = Uri.tryParse(destinationUrl);

    if (uri == null ||
        !uri.hasScheme ||
        !(uri.scheme == 'http' || uri.scheme == 'https')) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid destination URL.')));
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this destination.')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this destination.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final title = (data['title'] ?? 'SanSphere').toString().trim();

    final description =
        (data['description'] ??
                data['subtitle'] ??
                'Discover something new on SanSphere.')
            .toString()
            .trim();

    final imageUrl = (data['imageUrl'] ?? '').toString().trim();
    final destinationUrl = (data['destinationUrl'] ?? '').toString().trim();
    final ctaText = (data['ctaText'] ?? 'Open').toString().trim();

    final radius = featured ? 22.0 : 19.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: destinationUrl.isEmpty
            ? null
            : () => _openDestination(context, destinationUrl),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: AppColors.borderStrong.withValues(alpha: 0.55),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _iconBox();
                        },
                      )
                    : _iconBox(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'SanSphere' : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description.isEmpty
                          ? 'Discover something new on SanSphere.'
                          : description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (destinationUrl.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    ctaText.isEmpty ? 'Open' : ctaText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: onSurface.withValues(alpha: 0.35),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBox() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        _iconFor((data['icon'] ?? '').toString()),
        color: const Color(0xFF2563EB),
      ),
    );
  }

  static IconData _iconFor(String value) {
    switch (value) {
      case 'event':
        return Icons.event_rounded;
      case 'campaign':
        return Icons.campaign_rounded;
      case 'opportunity':
      case 'emoji_events':
        return Icons.emoji_events_rounded;
      case 'update':
      case 'new_releases':
        return Icons.new_releases_rounded;
      case 'community':
        return Icons.groups_rounded;
      case 'auto_awesome':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }
}

class _EmptyDiscoverCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyDiscoverCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: AppColors.borderStrong.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: AppColors.borderStrong.withValues(alpha: 0.55),
        ),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: Color(0xFF2563EB),
            child: Icon(Icons.people_alt_rounded, color: Colors.white),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Highlights',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Featured creators and community highlights will appear here.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
