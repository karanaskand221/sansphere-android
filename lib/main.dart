import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Your imports
import 'firebase_options.dart'; 
import 'global_state.dart';
import 'models/academic_resource.dart'; // Ensure this points to your model
import 'screens/upload_resource_screen.dart';
import 'screens/resource_detail_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/reels_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SanSphereApp());
}

class SanSphereApp extends StatelessWidget {
  const SanSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SanSphere Academic Vault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF2563EB),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const AuthGate(),
    );
  }
}

// -----------------------------------------------------------------------------
// AUTHENTICATION GATE
// -----------------------------------------------------------------------------
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
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

// -----------------------------------------------------------------------------
// MAIN NAVIGATION DASHBOARD
// -----------------------------------------------------------------------------
class MainNavigationScreen extends StatefulWidget {
  final bool isGuestMode;
  
  const MainNavigationScreen({super.key, required this.isGuestMode});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const AcademicVaultFeedScreen(),
    const ReelsScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Vault'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library_rounded), label: 'Reels'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
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

  final List<String> _campuses = ['SITRC', 'SIEM', 'SIPS', 'SU'];
  final List<String> _categories = ['All', 'Notes', 'Code', 'Syllabus', 'PYQs'];

  @override
  void initState() {
    super.initState();
    _initializeDevSession();
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

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticating) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
      );
    }

    Query query = FirebaseFirestore.instance
        .collection('academic_vault')
        .where('college', isEqualTo: _selectedCampusFilter);

    if (_selectedCategoryFilter != 'All') {
      query = query.where('type', isEqualTo: _selectedCategoryFilter);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Vault', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF2563EB), size: 18),
                const SizedBox(width: 6),
                Text('₹${GlobalState.currentUserWallet.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
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
          // Category chips...
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
                
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text('No materials found.'));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    // CONVERSION LOGIC:
                    final data = docs[index].data() as Map<String, dynamic>;
                    final resource = AcademicResource.fromMap(data, docs[index].id);
                    final Color accent = _getCategoryColor(resource.type);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: ListTile(
                        leading: Icon(Icons.description_rounded, color: accent),
                        title: Text(resource.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        // PASSING OBJECT:
                        onTap: () => Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (_) => ResourceDetailScreen(resource: resource)
                          )
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