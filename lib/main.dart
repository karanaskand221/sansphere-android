import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'global_state.dart';
import 'models/academic_resource.dart';
import 'screens/marketplace_feed.dart';
import 'screens/upload_resource_screen.dart';
import 'screens/resource_detail_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/reels_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/profile_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'widgets/ambient_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SanSphereApp());
}

class SanSphereApp extends StatelessWidget {
  const SanSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SanSphere',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            ),
          );
        }
        if (snapshot.hasData) {
          return const MainNavigationScreen(isGuestMode: false);
        }
        return const LoginScreen();
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final bool isGuestMode;

  const MainNavigationScreen({super.key, required this.isGuestMode});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final GlobalState _globalState = GlobalState();

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      MarketplaceFeedScreen(globalState: _globalState),
      const ReelsScreen(),
      const ChatListScreen(),
      ProfileScreen(globalState: _globalState),
    ];

    return Scaffold(
      body: AmbientBackground(
        child: IndexedStack(index: _currentIndex, children: pages),
      ),
      bottomNavigationBar: _FloatingGlassNavigation(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _FloatingGlassNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingGlassNavigation({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: NavigationBar(
            height: 68,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            indicatorColor: const Color(0xFFE0E7FF),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: 'Vault',
              ),
              NavigationDestination(
                icon: Icon(Icons.play_circle_outline),
                selectedIcon: Icon(Icons.play_circle),
                label: 'Reels',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Chats',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AcademicVaultFeedScreen extends StatefulWidget {
  final GlobalState globalState;
  const AcademicVaultFeedScreen({super.key, required this.globalState});

  @override
  State<AcademicVaultFeedScreen> createState() =>
      _AcademicVaultFeedScreenState();
}

class _AcademicVaultFeedScreenState extends State<AcademicVaultFeedScreen> {
  String _selectedCampusFilter = 'All';
  String _selectedCategoryFilter = 'All';
  bool _isAuthenticating = true;
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _campuses = ['All', 'SITRC', 'SIEM', 'SIPS', 'SU'];
  final List<String> _categories = ['All', 'Notes', 'Code', 'Syllabus', 'PYQs'];

  final FirebaseFirestore _userFirestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'sansphere',
  );
  final FirebaseFirestore _vaultFirestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'sanvault',
  );

  @override
  void initState() {
    super.initState();
    _initializeDevSession();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeDevSession() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (e) {
      debugPrint("Auth configuration warning: $e");
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  Color _getCategoryColor(String type) {
    switch (type) {
      case 'Code':
        return Colors.blue;
      case 'Notes':
        return Colors.orange;
      case 'Syllabus':
        return Colors.purple;
      case 'PYQs':
        return Colors.green;
      default:
        return const Color(0xFF2563EB);
    }
  }

  Future<void> _handleOpenViaLinkOrSearch(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    String docId = trimmed;

    if (trimmed.contains('sansphere.app/vault/')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        docId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : trimmed;
      }
    }

    try {
      final query = await _vaultFirestore
          .collection('academic_vault')
          .where('customDocId', isEqualTo: docId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() => _searchQuery = trimmed);
        return;
      }

      final resource = AcademicResource.fromMap(
        query.docs.first.data()..['id'] = query.docs.first.id,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResourceDetailScreen(
            resource: resource,
            globalState: widget.globalState,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error searching resource: $e')));
    }
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _resourceInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticating) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }

    // IMPORTANT:
    // Fetch Academic Vault resources without compound Firestore
    // filters. This avoids composite-index errors.
    //
    // Campus/category/search filtering is intentionally performed
    // locally below so every uploaded resource can appear.
    final Query query = _vaultFirestore.collection('academic_vault');

    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SanSphere Vault',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (currentUid != null)
            StreamBuilder<DocumentSnapshot>(
              stream: _userFirestore
                  .collection('users')
                  .doc(currentUid)
                  .snapshots(),
              builder: (context, snapshot) {
                final coins =
                    (snapshot.data?.data()
                        as Map<String, dynamic>?)?['sanCoins'] ??
                    0;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$coins',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(
              _showSearchBar ? Icons.close : Icons.search,
              color: const Color(0xFF0F172A),
            ),
            onPressed: () => setState(() {
              _showSearchBar = !_showSearchBar;
              if (!_showSearchBar) {
                _searchController.clear();
                _searchQuery = '';
              }
            }),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF0F172A)),
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (_showSearchBar)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, Doc ID, or paste a share link…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () =>
                        _handleOpenViaLinkOrSearch(_searchController.text),
                  ),
                ),
                onSubmitted: _handleOpenViaLinkOrSearch,
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _selectedCampusFilter,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedCampusFilter = newValue);
                    }
                  },
                  items: _campuses.map<DropdownMenuItem<String>>((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UploadResourceScreen(
                          globalState: widget.globalState,
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: const Text(
                    'Publish',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategoryFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0F172A),
                    onSelected: (_) =>
                        setState(() => _selectedCategoryFilter = cat),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading feed: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data?.docs ?? [];

                // ----------------------------------------------------
                // LOCAL FILTERING
                // ----------------------------------------------------
                // Firestore is intentionally not using compound
                // where/orderBy queries here. This means newly
                // uploaded resources are not blocked by missing
                // composite indexes.
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;

                  final college = (data['college'] ?? '').toString().trim();

                  final type = (data['type'] ?? '').toString().toLowerCase();

                  final category = (data['category'] ?? '')
                      .toString()
                      .toLowerCase();

                  final title = (data['title'] ?? '').toString().toLowerCase();

                  final subject = (data['subject'] ?? '')
                      .toString()
                      .toLowerCase();

                  final fileName = (data['fileName'] ?? '')
                      .toString()
                      .toLowerCase();

                  final tags = data['tags'] is List
                      ? (data['tags'] as List)
                            .map((e) => e.toString().toLowerCase())
                            .join(' ')
                      : '';

                  // Campus filter.
                  final campusMatches =
                      _selectedCampusFilter == 'All' ||
                      college.toLowerCase() ==
                          _selectedCampusFilter.toLowerCase();

                  // Category filter.
                  bool categoryMatches = _selectedCategoryFilter == 'All';

                  if (!categoryMatches) {
                    switch (_selectedCategoryFilter) {
                      case 'Notes':
                        categoryMatches =
                            type.contains('note') ||
                            category.contains('lecture') ||
                            category.contains('note');
                        break;

                      case 'Code':
                        categoryMatches =
                            type.contains('code') ||
                            category.contains('code') ||
                            title.contains('code') ||
                            tags.contains('code');
                        break;

                      case 'Syllabus':
                        categoryMatches =
                            type.contains('syllabus') ||
                            category.contains('syllabus') ||
                            title.contains('syllabus');
                        break;

                      case 'PYQs':
                        categoryMatches =
                            type.contains('pyq') ||
                            type.contains('previous year') ||
                            category.contains('pyq') ||
                            title.contains('pyq') ||
                            tags.contains('pyq');
                        break;

                      default:
                        categoryMatches = true;
                    }
                  }

                  // Search filter.
                  final q = _searchQuery.trim().toLowerCase();

                  final searchMatches =
                      q.isEmpty ||
                      title.contains(q) ||
                      subject.contains(q) ||
                      fileName.contains(q) ||
                      college.toLowerCase().contains(q) ||
                      tags.contains(q) ||
                      (data['customDocId'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(q);

                  return campusMatches && categoryMatches && searchMatches;
                }).toList();

                // ----------------------------------------------------
                // SORT NEWEST FIRST LOCALLY
                // ----------------------------------------------------
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;

                  DateTime parseDate(dynamic value) {
                    if (value is Timestamp) {
                      return value.toDate();
                    }

                    if (value is DateTime) {
                      return value;
                    }

                    if (value is String) {
                      return DateTime.tryParse(value) ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                    }

                    return DateTime.fromMillisecondsSinceEpoch(0);
                  }

                  final aDate = parseDate(
                    aData['createdAt'] ?? aData['uploadDate'],
                  );

                  final bDate = parseDate(
                    bData['createdAt'] ?? bData['uploadDate'],
                  );

                  return bDate.compareTo(aDate);
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No academic materials found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    data['id'] = docs[index].id;
                    final resource = AcademicResource.fromMap(data);
                    final Color accent = _getCategoryColor(resource.type);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ResourceDetailScreen(
                              resource: resource,
                              globalState: widget.globalState,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  resource.fileName.toLowerCase().endsWith(
                                        '.pdf',
                                      )
                                      ? Icons.picture_as_pdf_rounded
                                      : Icons.description_rounded,
                                  color: accent,
                                  size: 28,
                                ),
                              ),

                              const SizedBox(width: 13),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      resource.title.isEmpty
                                          ? resource.fileName
                                          : resource.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    if (resource.subject.isNotEmpty)
                                      Text(
                                        resource.subject,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF475569),
                                        ),
                                      ),

                                    const SizedBox(height: 7),

                                    if (resource.fileName.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.insert_drive_file_outlined,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              resource.fileName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                    const SizedBox(height: 8),

                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 5,
                                      children: [
                                        if (resource.college.isNotEmpty)
                                          _resourceInfoChip(
                                            Icons.school_outlined,
                                            resource.college,
                                          ),

                                        if (resource.department.isNotEmpty)
                                          _resourceInfoChip(
                                            Icons.account_balance_outlined,
                                            resource.department,
                                          ),

                                        if (resource.uploaderName.isNotEmpty)
                                          _resourceInfoChip(
                                            Icons.person_outline,
                                            resource.uploaderName,
                                          ),

                                        if (resource.fileSizeMb > 0)
                                          _resourceInfoChip(
                                            Icons.storage_outlined,
                                            '${resource.fileSizeMb.toStringAsFixed(2)} MB',
                                          ),

                                        _resourceInfoChip(
                                          Icons.download_outlined,
                                          '${resource.downloadCount}',
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      'ID: ${resource.customDocId}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: resource.price <= 0
                                          ? const Color(0xFFECFDF5)
                                          : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      resource.price <= 0
                                          ? 'Free'
                                          : '₹${resource.price.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: resource.price <= 0
                                            ? Colors.green.shade700
                                            : const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
