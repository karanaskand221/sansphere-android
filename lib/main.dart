import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_storage/firebase_storage.dart";
import "package:firebase_auth/firebase_auth.dart";
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'screens/marketplace_feed.dart';
import 'screens/reels_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth/login_screen.dart';

// --- Shared Live State ---
bool isFirebaseReady = false;

// GLOBAL CUSTOM DATABASE INSTANCE
late FirebaseFirestore customFirestore;

void main() async {
  // Ensure framework initialization layer runs securely
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Core Firebase Setup
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // 2. Database targets the custom named 'sansphere' database instance safely
    customFirestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'sansphere',
    );
    
    // 3. Force-clear client persistence cache logs once to clear conflicts
    await customFirestore.clearPersistence();
    
    // 4. Set stable configuration parameters
    customFirestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    isFirebaseReady = true;
    debugPrint("Connected safely using custom 'sansphere' database parameters.");
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
    isFirebaseReady = false;
  }

  runApp(const SansphereApp());
}

class SansphereApp extends StatelessWidget {
  const SansphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blueAccent, useMaterial3: true),
      home: isFirebaseReady
          ? StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                // FALLBACK LAYER: If the connection hangs or errors out, redirect to LoginScreen
                if (snapshot.hasError) {
                  return const LoginScreen();
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.blueAccent),
                          SizedBox(height: 16),
                          Text("Verifying Session...", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }
                if (snapshot.hasData && snapshot.data != null) {
                  return const MainNavigationScreen(isGuestMode: false);
                }
                return const LoginScreen();
              },
            )
          : const LoginScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final bool isGuestMode;
  const MainNavigationScreen({super.key, this.isGuestMode = false});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  Widget _buildLockedFeatureView(String featureName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_person_outlined, size: 64, color: Colors.blueAccent),
            ),
            const SizedBox(height: 24),
            Text(
              "$featureName Locked",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),
            const Text(
              "Full accounts get absolute access to interactive campus systems. Please sign up to connect with your peers.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const MarketplaceFeed(), 
      widget.isGuestMode ? _buildLockedFeatureView("Reels Feed") : const ReelsScreen(), 
      widget.isGuestMode ? _buildLockedFeatureView("Campus Chat System") : const ChatListScreen(), 
      ProfileScreen(isGuestMode: widget.isGuestMode),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/S.jpeg',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.school, color: Colors.blueAccent);
                },
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "SANSPHERE",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.blueAccent,
                letterSpacing: 1.2,
                fontSize: 20,
              ),
            ),
            if (widget.isGuestMode) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Text("GUEST", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ]
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Vault'),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle), label: 'Reels'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Profile'),
        ],
      ),
    );
  }
}