MARKER = "// -----------------------------------------------------------------------------\n// ACADEMIC VAULT FEED SCREEN\n// -----------------------------------------------------------------------------\nclass AcademicVaultFeedScreen extends StatefulWidget {"

NEW_BLOCK = '''// -----------------------------------------------------------------------------
// ACADEMIC VAULT FEED SCREEN
// -----------------------------------------------------------------------------
class AcademicVaultFeedScreen extends StatefulWidget {
  const AcademicVaultFeedScreen({super.key});

  @override
  State<AcademicVaultFeedScreen> createState() => _AcademicVaultFeedScreenState();
}

class _AcademicVaultFeedScreenState extends State<AcademicVaultFeedScreen> {
  String _selectedCampusFilter = 'SITRC';
  String _selectedCategoryFilter = 'All';
  bool _isAuthenticating = true;
  bool _showSearchBar = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _campuses = ['SITRC', 'SIEM', 'SIPS', 'SU'];
  final List<String> _categories = ['All', 'Notes', 'Code', 'Syllabus', 'PYQs'];

  final _userFirestore = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'sansphere');

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
      case 'Code': return Colors.blue;
      case 'Notes': return Colors.orange;
      case 'Syllabus': return Colors.purple;
      case 'PYQs': return Colors.green;
      default: return const Color(0xFF2563EB);
    }
  }

  Future<void> _handleOpenViaLinkOrSearch(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    String docId = trimmed;
    String? refUid;

    if (trimmed.contains('sansphere.app/vault/')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        docId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : trimmed;
        refUid = uri.queryParameters['ref'];
      }
    }

    final query = await FirebaseFirestore.instance
        .collection('academic_vault')
        .where('customDocId', isEqualTo: docId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      setState(() => _searchQuery = trimmed);
      return;
    }

    final resource = AcademicResource.fromMap(query.docs.first.data(), query.docs.first.id);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResourceDetailScreen(resource: resource, referrerUid: refUid)),
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

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticating) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
      );
    }

    Query query = FirebaseFirestore.instance
        .collection('academic_vault')
        .orderBy('createdAt', descending: true)
        .where('college', isEqualTo: _selectedCampusFilter);

    if (_selectedCategoryFilter != 'All') {
      query = query.where('type', isEqualTo: _selectedCategoryFilter);
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Vault', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (currentUid != null)
            StreamBuilder<DocumentSnapshot>(
              stream: _userFirestore.collection('users').doc(currentUid).snapshots(),
              builder: (context, snapshot) {
                final coins = (snapshot.data?.data() as Map<String, dynamic>?)?['sanCoins'] ?? 0;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text('$coins', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                    ],
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search, color: const Color(0xFF0F172A)),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => _handleOpenViaLinkOrSearch(_searchController.text),
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  underline: const SizedBox(),
                  onChanged: (String? newValue) => setState(() => _selectedCampusFilter = newValue!),
                  items: _campuses.map<DropdownMenuItem<String>>((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadResourceScreen())).then((_) => setState(() {})),
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: const Text('Publish'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0F172A),
                    onSelected: (_) => setState(() => _selectedCategoryFilter = cat),
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
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data?.docs ?? [];

                if (_searchQuery.trim().isNotEmpty) {
                  final q = _searchQuery.trim().toLowerCase();
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final title = (data['title'] ?? '').toString().toLowerCase();
                    final docId = (data['customDocId'] ?? '').toString().toLowerCase();
                    final fileName = (data['fileName'] ?? '').toString().toLowerCase();
                    return title.contains(q) || docId.contains(q) || fileName.contains(q);
                  }).toList();
                }

                if (docs.isEmpty) return const Center(child: Text('No materials found.'));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final resource = AcademicResource.fromMap(data, docs[index].id);
                    final Color accent = _getCategoryColor(resource.type);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: accent.withValues(alpha: 0.12),
                          child: Icon(Icons.description_rounded, color: accent),
                        ),
                        title: Text(resource.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${resource.college} • ID: ${resource.customDocId}', style: const TextStyle(fontSize: 12)),
                        trailing: Text(
                          resource.price <= 0 ? "Free" : "₹${resource.price.toStringAsFixed(0)}",
                          style: TextStyle(fontWeight: FontWeight.bold, color: resource.price <= 0 ? Colors.green : const Color(0xFF2563EB)),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ResourceDetailScreen(resource: resource)),
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
'''

with open("lib/main.dart", "r", encoding="utf-8") as f:
    content = f.read()

idx = content.find(MARKER)
if idx == -1:
    print("[ERROR] Could not find the AcademicVaultFeedScreen marker in lib/main.dart.")
    print("The file may already differ from what I expect — paste me its current content and I'll fix this manually.")
else:
    new_content = content[:idx] + NEW_BLOCK
    with open("lib/main.dart", "w", encoding="utf-8") as f:
        f.write(new_content)
    print("[ok] Replaced AcademicVaultFeedScreen through end of file in lib/main.dart")
