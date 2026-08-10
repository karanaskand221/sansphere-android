import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class SanCoinsWalletService {
  SanCoinsWalletService._();

  static final SanCoinsWalletService instance =
      SanCoinsWalletService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'sansphere',
  );

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<Map<String, dynamic>?> walletStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  Future<Map<String, dynamic>?> getWallet() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final snapshot =
        await _firestore.collection('users').doc(user.uid).get();

    return snapshot.data();
  }

  Future<int> getSanCoins() async {
    final wallet = await getWallet();

    return (wallet?['sanCoins'] as num?)?.toInt() ?? 0;
  }

  Future<int> getEarnedCoins() async {
    final wallet = await getWallet();

    return (wallet?['earnedCoins'] as num?)?.toInt() ?? 0;
  }
}
