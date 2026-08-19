import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../widgets/ambient_background.dart';

class DiscoverAdminScreen extends StatelessWidget {
  const DiscoverAdminScreen({super.key});

  static const String adminEmail = 'karanaskand222@gmail.com';

  static bool isAdmin(User? user) {
    return user?.email?.trim().toLowerCase() == adminEmail;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (!isAdmin(user)) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Access denied.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Manage Discover',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ManageVaultAdminScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.school_rounded, size: 18),
              label: const Text(
                'Manage Vault',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AmbientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
            children: [
              _header(),
              const SizedBox(height: 18),

              _AdminSectionCard(
                icon: Icons.view_carousel_rounded,
                title: 'Banners',
                subtitle:
                    'Large promotional banners shown at the top of Discover.',
                collection: 'discover_banners',
                color: const Color(0xFF2563EB),
                fields: DiscoverContentType.banner,
              ),

              _AdminSectionCard(
                icon: Icons.campaign_rounded,
                title: 'Announcements',
                subtitle: 'Important SanSphere notices and announcements.',
                collection: 'discover_announcements',
                color: const Color(0xFF7C3AED),
                fields: DiscoverContentType.announcement,
              ),

              _AdminSectionCard(
                icon: Icons.emoji_events_rounded,
                title: 'Opportunities',
                subtitle:
                    'Events, competitions, scholarships and opportunities.',
                collection: 'discover_opportunities',
                color: const Color(0xFFD97706),
                fields: DiscoverContentType.opportunity,
              ),

              _AdminSectionCard(
                icon: Icons.auto_awesome_rounded,
                title: 'Featured',
                subtitle: 'Special SanSphere content selected by the admin.',
                collection: 'discover_featured',
                color: const Color(0xFF059669),
                fields: DiscoverContentType.featured,
              ),

              _AdminSectionCard(
                icon: Icons.new_releases_rounded,
                title: 'SanSphere Updates',
                subtitle: 'New features, improvements and product updates.',
                collection: 'discover_updates',
                color: const Color(0xFFDB2777),
                fields: DiscoverContentType.update,
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.security_rounded, color: Color(0xFF2563EB)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Only the SanSphere admin account can create, '
                        'edit, publish, unpublish or delete Discover content.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF172554), Color(0xFF312E81)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.admin_panel_settings_rounded,
            color: Colors.white,
            size: 30,
          ),
          SizedBox(height: 12),
          Text(
            'Discover Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Control everything that appears in the Discover section.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

enum DiscoverContentType { banner, announcement, opportunity, featured, update }

class _AdminSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String collection;
  final Color color;
  final DiscoverContentType fields;

  const _AdminSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.collection,
    required this.color,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DiscoverCollectionAdminScreen(
                      collection: collection,
                      title: title,
                      contentType: fields,
                      accentColor: color,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(icon, color: color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class DiscoverCollectionAdminScreen extends StatelessWidget {
  final String collection;
  final String title;
  final DiscoverContentType contentType;
  final Color accentColor;

  const DiscoverCollectionAdminScreen({
    super.key,
    required this.collection,
    required this.title,
    required this.contentType,
    required this.accentColor,
  });

  bool get isBanner => contentType == DiscoverContentType.banner;

  String get statusField => isBanner ? 'active' : 'published';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Add content',
            onPressed: () => _openEditor(context),
            icon: const Icon(Icons.add_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'sample') {
                _addSample(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'sample',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Add sample content'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection(collection).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load $title.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs = [...(snapshot.data?.docs ?? [])];

          docs.sort((a, b) {
            final ap = (a.data()['priority'] as num?)?.toInt() ?? 0;
            final bp = (b.data()['priority'] as num?)?.toInt() ?? 0;

            if (ap != bp) {
              return bp.compareTo(ap);
            }

            final at = a.data()['updatedAt'];
            final bt = b.data()['updatedAt'];

            if (at is Timestamp && bt is Timestamp) {
              return bt.compareTo(at);
            }

            return 0;
          });

          if (docs.isEmpty) {
            return _EmptyAdminState(
              title: 'No $title yet',
              subtitle: 'Add your first item or use the sample option.',
              accentColor: accentColor,
              onAdd: () => _openEditor(context),
              onSample: () => _addSample(context),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];

              return _AdminContentCard(
                documentId: doc.id,
                data: doc.data(),
                contentType: contentType,
                accentColor: accentColor,
                onEdit: () => _openEditor(
                  context,
                  documentId: doc.id,
                  existing: doc.data(),
                ),
                onDelete: () => _delete(context, doc.id, doc.data()),
                onToggle: () => _toggleStatus(context, doc.id, doc.data()),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context, {
    String? documentId,
    Map<String, dynamic>? existing,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DiscoverEditorDialog(
        collection: collection,
        title: title,
        contentType: contentType,
        accentColor: accentColor,
        documentId: documentId,
        existing: existing,
      ),
    );
  }

  Future<void> _toggleStatus(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) async {
    final current = data[statusField] == true;

    try {
      await FirebaseFirestore.instance.collection(collection).doc(id).update({
        statusField: !current,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !current ? '$title item published.' : '$title item unpublished.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update item: $e')));
    }
  }

  Future<void> _delete(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) async {
    final itemTitle = (data['title'] ?? 'this item').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete content?'),
          content: Text('Delete "$itemTitle"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection(collection).doc(id).delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Content deleted.')));
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete content: $e')));
    }
  }

  Future<void> _addSample(BuildContext context) async {
    final now = FieldValue.serverTimestamp();

    final Map<String, dynamic> data;

    switch (contentType) {
      case DiscoverContentType.banner:
        data = {
          'title': 'Welcome to SanSphere',
          'subtitle':
              'Discover resources, opportunities and new SanSphere features.',
          'description': 'A featured SanSphere announcement for students.',
          'imageUrl': '',
          'destinationUrl': '',
          'ctaText': 'Explore',
          'active': true,
          'priority': 100,
          'createdAt': now,
          'updatedAt': now,
        };
        break;

      case DiscoverContentType.announcement:
        data = {
          'title': 'SanSphere is getting better',
          'description':
              'New improvements are being added to make your academic experience easier.',
          'icon': 'campaign',
          'imageUrl': '',
          'destinationUrl': '',
          'ctaText': 'Learn more',
          'published': true,
          'priority': 50,
          'createdAt': now,
          'updatedAt': now,
        };
        break;

      case DiscoverContentType.opportunity:
        data = {
          'title': 'Student Opportunity',
          'description':
              'Watch Discover for upcoming events, competitions and academic opportunities.',
          'icon': 'emoji_events',
          'imageUrl': '',
          'destinationUrl': '',
          'ctaText': 'View opportunity',
          'published': true,
          'priority': 40,
          'createdAt': now,
          'updatedAt': now,
        };
        break;

      case DiscoverContentType.featured:
        data = {
          'title': 'Featured on SanSphere',
          'description':
              'A special community highlight selected by the SanSphere team.',
          'icon': 'auto_awesome',
          'imageUrl': '',
          'destinationUrl': '',
          'ctaText': 'Explore',
          'published': true,
          'priority': 30,
          'createdAt': now,
          'updatedAt': now,
        };
        break;

      case DiscoverContentType.update:
        data = {
          'title': 'Discover is now live',
          'description':
              'SanSphere Discover brings announcements, opportunities and featured content together.',
          'icon': 'new_releases',
          'imageUrl': '',
          'destinationUrl': '',
          'ctaText': 'See what is new',
          'published': true,
          'priority': 20,
          'createdAt': now,
          'updatedAt': now,
        };
        break;
    }

    try {
      await FirebaseFirestore.instance.collection(collection).add(data);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sample content added successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not add sample: $e')));
    }
  }
}

class _AdminContentCard extends StatelessWidget {
  final String documentId;
  final Map<String, dynamic> data;
  final DiscoverContentType contentType;
  final Color accentColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _AdminContentCard({
    required this.documentId,
    required this.data,
    required this.contentType,
    required this.accentColor,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  bool get isBanner => contentType == DiscoverContentType.banner;

  bool get isPublished => data[isBanner ? 'active' : 'published'] == true;

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] ?? 'Untitled content').toString();
    final description = (data['description'] ?? data['subtitle'] ?? '')
        .toString();
    final destination = (data['destinationUrl'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _iconFor((data['icon'] ?? '').toString(), contentType),
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                  if (value == 'toggle') onToggle();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(isPublished ? 'Unpublish' : 'Publish'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: isPublished
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  isPublished ? 'PUBLISHED' : 'DRAFT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: isPublished
                        ? const Color(0xFF047857)
                        : const Color(0xFFC2410C),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Priority ${data['priority'] ?? 0}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
              const Spacer(),
              if (destination.isNotEmpty)
                const Icon(
                  Icons.link_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(String name, DiscoverContentType type) {
    switch (name) {
      case 'campaign':
        return Icons.campaign_rounded;
      case 'emoji_events':
        return Icons.emoji_events_rounded;
      case 'auto_awesome':
        return Icons.auto_awesome_rounded;
      case 'new_releases':
        return Icons.new_releases_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'groups':
        return Icons.groups_rounded;
      default:
        switch (type) {
          case DiscoverContentType.banner:
            return Icons.view_carousel_rounded;
          case DiscoverContentType.announcement:
            return Icons.campaign_rounded;
          case DiscoverContentType.opportunity:
            return Icons.emoji_events_rounded;
          case DiscoverContentType.featured:
            return Icons.auto_awesome_rounded;
          case DiscoverContentType.update:
            return Icons.new_releases_rounded;
        }
    }
  }
}

class _DiscoverEditorDialog extends StatefulWidget {
  final String collection;
  final String title;
  final DiscoverContentType contentType;
  final Color accentColor;
  final String? documentId;
  final Map<String, dynamic>? existing;

  const _DiscoverEditorDialog({
    required this.collection,
    required this.title,
    required this.contentType,
    required this.accentColor,
    this.documentId,
    this.existing,
  });

  @override
  State<_DiscoverEditorDialog> createState() => _DiscoverEditorDialogState();
}

class _DiscoverEditorDialogState extends State<_DiscoverEditorDialog> {
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _description;
  late final TextEditingController _imageUrl;
  late final TextEditingController _destinationUrl;
  late final TextEditingController _ctaText;
  late final TextEditingController _priority;
  late final TextEditingController _icon;

  bool _published = true;
  bool _saving = false;
  bool _uploadingImage = false;

  bool get isBanner => widget.contentType == DiscoverContentType.banner;

  @override
  void initState() {
    super.initState();

    final d = widget.existing ?? {};

    _title = TextEditingController(text: (d['title'] ?? '').toString());
    _subtitle = TextEditingController(text: (d['subtitle'] ?? '').toString());
    _description = TextEditingController(
      text: (d['description'] ?? '').toString(),
    );
    _imageUrl = TextEditingController(text: (d['imageUrl'] ?? '').toString());
    _destinationUrl = TextEditingController(
      text: (d['destinationUrl'] ?? '').toString(),
    );
    _ctaText = TextEditingController(
      text: (d['ctaText'] ?? 'Explore').toString(),
    );
    _priority = TextEditingController(text: (d['priority'] ?? 0).toString());
    _icon = TextEditingController(
      text: (d['icon'] ?? _defaultIcon()).toString(),
    );

    _published = d[isBanner ? 'active' : 'published'] != false;
  }

  String _defaultIcon() {
    switch (widget.contentType) {
      case DiscoverContentType.banner:
        return 'campaign';
      case DiscoverContentType.announcement:
        return 'campaign';
      case DiscoverContentType.opportunity:
        return 'emoji_events';
      case DiscoverContentType.featured:
        return 'auto_awesome';
      case DiscoverContentType.update:
        return 'new_releases';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _description.dispose();
    _imageUrl.dispose();
    _destinationUrl.dispose();
    _ctaText.dispose();
    _priority.dispose();
    _icon.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    if (_uploadingImage) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;

      if (file.bytes == null) {
        _error('Could not read the selected image.');
        return;
      }

      setState(() => _uploadingImage = true);

      final extension = (file.extension ?? 'jpg').toLowerCase();

      final documentId =
          widget.documentId ??
          FirebaseFirestore.instance.collection(widget.collection).doc().id;

      final storageRef =
          FirebaseStorage.instanceFor(
                bucket: 'gen-lang-client-0227443307.firebasestorage.app',
              )
              .ref()
              .child('discover')
              .child(widget.contentType.name)
              .child('$documentId.$extension');

      final metadata = SettableMetadata(
        contentType: 'image/$extension',
        cacheControl: 'public,max-age=3600',
      );

      final uploadTask = await storageRef.putData(file.bytes!, metadata);

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      if (!mounted) return;

      setState(() {
        _imageUrl.text = downloadUrl;
        _uploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully.')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() => _uploadingImage = false);

      debugPrint(
        'Discover image upload failed: '
        'code=${e.code}, message=${e.message}',
      );

      _error(
        e.message == null || e.message!.trim().isEmpty
            ? 'Image upload failed (${e.code}).'
            : 'Image upload failed: ${e.message}',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _uploadingImage = false);

      debugPrint('Discover image upload failed: $e');

      _error('Image upload failed. Please try again.');
    }
  }

  Future<void> _save() async {
    final title = _title.text.trim();

    if (title.isEmpty) {
      _error('Title is required.');
      return;
    }

    if (!isBanner && _description.text.trim().isEmpty) {
      _error('Description is required.');
      return;
    }

    final priority = int.tryParse(_priority.text.trim()) ?? 0;

    setState(() => _saving = true);

    final firestore = FirebaseFirestore.instance.collection(widget.collection);

    final data = <String, dynamic>{
      'title': title,
      'subtitle': _subtitle.text.trim(),
      'description': _description.text.trim(),
      'imageUrl': _imageUrl.text.trim(),
      'destinationUrl': _destinationUrl.text.trim(),
      'ctaText': _ctaText.text.trim().isEmpty
          ? 'Explore'
          : _ctaText.text.trim(),
      'icon': _icon.text.trim(),
      'priority': priority,
      isBanner ? 'active' : 'published': _published,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.documentId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();

        await firestore.add(data);
      } else {
        await firestore.doc(widget.documentId).update(data);
      }

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.documentId == null
                ? '${widget.title} created.'
                : '${widget.title} updated.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);
      _error('Could not save content: $e');
    }
  }

  void _error(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.documentId == null
            ? 'Add ${widget.title}'
            : 'Edit ${widget.title}',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_title, 'Title', Icons.title_rounded),

              if (isBanner) ...[
                _field(_subtitle, 'Subtitle', Icons.short_text_rounded),
              ],

              _field(
                _description,
                'Description',
                Icons.notes_rounded,
                maxLines: 4,
              ),

              if (isBanner)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.image_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Banner Image',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_imageUrl.text.trim().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _imageUrl.text.trim(),
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) {
                              return Container(
                                height: 130,
                                width: double.infinity,
                                alignment: Alignment.center,
                                color: Colors.white.withValues(alpha: 0.05),
                                child: const Text(
                                  'Image preview unavailable',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _uploadingImage
                              ? null
                              : _pickAndUploadImage,
                          icon: _uploadingImage
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_rounded),
                          label: Text(
                            _uploadingImage
                                ? 'Uploading...'
                                : 'Select Banner Image',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _imageUrl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Or use Image URL',
                          labelStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(
                            Icons.link_rounded,
                            color: Colors.white54,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                )
              else
                _field(_imageUrl, 'Image URL (optional)', Icons.image_outlined),

              _field(
                _destinationUrl,
                'Destination URL (optional)',
                Icons.link_rounded,
              ),

              _field(_ctaText, 'Button text', Icons.touch_app_rounded),

              if (!isBanner) _field(_icon, 'Icon', Icons.interests_rounded),

              _field(
                _priority,
                'Priority',
                Icons.low_priority_rounded,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 8),

              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _published,
                onChanged: _saving
                    ? null
                    : (value) {
                        setState(() {
                          _published = value;
                        });
                      },
                title: Text(
                  isBanner ? 'Active' : 'Published',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  isBanner
                      ? 'Active banners are visible to users.'
                      : 'Published content is visible to users.',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_rounded),
          label: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
    );
  }
}

class _EmptyAdminState extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onAdd;
  final VoidCallback onSample;

  const _EmptyAdminState({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onAdd,
    required this.onSample,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.dashboard_customize_rounded,
              size: 54,
              color: accentColor,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onSample,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Add Sample'),
                ),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ManageVaultAdminScreen extends StatelessWidget {
  const ManageVaultAdminScreen({super.key});

  static const String adminEmail = 'karanaskand222@gmail.com';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user?.email?.trim().toLowerCase() != adminEmail) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Access denied.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    final vaultDb = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'sanvault',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Manage Vault',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: vaultDb.collection('academic_vault').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load Vault resources.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFB91C1C)),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = [...(snapshot.data?.docs ?? [])];

          docs.sort((a, b) {
            final aData = a.data();
            final bData = b.data();

            final aCreated = aData['createdAt'];
            final bCreated = bData['createdAt'];

            if (aCreated is Timestamp && bCreated is Timestamp) {
              return bCreated.compareTo(aCreated);
            }

            return 0;
          });

          return RefreshIndicator(
            onRefresh: () async {
              await vaultDb.collection('academic_vault').get();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
              children: [
                _buildVaultHeader(docs.length),
                const SizedBox(height: 16),
                if (docs.isEmpty)
                  _buildEmptyVault()
                else
                  ...docs.map((doc) => _AdminVaultResourceCard(document: doc)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVaultHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF172554), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Academic Vault',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count resource${count == 1 ? '' : 's'} stored in SanVault',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyVault() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.folder_open_rounded, size: 54, color: Color(0xFF94A3B8)),
          SizedBox(height: 14),
          Text(
            'No Vault resources',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Resources uploaded by users will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _AdminVaultResourceCard extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> document;

  const _AdminVaultResourceCard({required this.document});

  @override
  State<_AdminVaultResourceCard> createState() =>
      _AdminVaultResourceCardState();
}

class _AdminVaultResourceCardState extends State<_AdminVaultResourceCard> {
  bool _deleting = false;

  String _textValue(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    return value.toString().trim();
  }

  Future<void> _deleteResource() async {
    if (_deleting) return;

    final data = widget.document.data();

    final title = _textValue(data['title'], 'Untitled resource');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
              SizedBox(width: 10),
              Expanded(child: Text('Delete Vault Resource?')),
            ],
          ),
          content: Text(
            'This will permanently delete "$title".\n\n'
            'The Storage file, Vault record, purchases, '
            'ratings and saved references will also be removed.\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _deleting = true;
    });

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'adminDeleteAcademicResource',
      );

      await callable.call({'resourceId': widget.document.id});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vault resource deleted successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Could not delete the Vault resource.'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _deleting = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete the Vault resource.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _deleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.document.data();

    final title = _textValue(data['title'], 'Untitled Resource');

    final subject = _textValue(data['subject']);

    final uploaderId = _textValue(data['uploaderId']);

    final department = _textValue(data['department']);

    final semester = _textValue(data['semester']);

    final category = _textValue(data['category']);

    final price = data['price'] is num ? (data['price'] as num).toInt() : 0;

    final storagePath = _textValue(data['storagePath']);

    final status = _textValue(data['status'], 'unknown');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'Untitled Resource' : title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (subject.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subject,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Delete resource',
                onPressed: _deleting ? null : _deleteResource,
                icon: _deleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFDC2626),
                      ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (department.isNotEmpty)
                _infoChip(Icons.account_balance_rounded, department),
              if (semester.isNotEmpty)
                _infoChip(Icons.school_rounded, 'Semester $semester'),
              if (category.isNotEmpty)
                _infoChip(Icons.category_rounded, category),
              _infoChip(
                Icons.monetization_on_rounded,
                price <= 0 ? 'FREE' : '$price SanCoins',
              ),
              _infoChip(Icons.circle, status),
            ],
          ),

          const SizedBox(height: 12),

          if (uploaderId.isNotEmpty) _detailRow('Uploader', uploaderId),

          if (storagePath.isNotEmpty) _detailRow('Storage', storagePath),

          const SizedBox(height: 4),

          Text(
            'Resource ID: ${widget.document.id}',
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF64748B)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 65,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }
}
