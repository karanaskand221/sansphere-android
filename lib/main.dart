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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Attempt initialization using the configuration file
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseReady = true;
    debugPrint("Connected safely using DefaultFirebaseOptions configuration.");
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasData && snapshot.data != null) {
                  return const MainNavigationScreen();
                }
                return const LoginScreen();
              },
            )
          : const LoginScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const MarketplaceFeed(), 
    const ReelsScreen(), 
    const ChatListScreen(), 
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
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