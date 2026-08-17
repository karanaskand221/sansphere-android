import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class SanCoinsWalletService {
  SanCoinsWalletService._();

  static final SanCoinsWalletService instance = SanCoinsWalletService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    app: Firebase.app(),
    region: 'us-central1',
  );

  Future<Map<String, dynamic>?> getWallet() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final result = await _functions.httpsCallable('getSanCoinWallet').call();

    final data = result.data;

    if (data is! Map) {
      throw StateError('Invalid SanCoin wallet response.');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<int> getSanCoins() async {
    final wallet = await getWallet();

    return (wallet?['sanCoins'] as num?)?.toInt() ?? 0;
  }

  Future<int> getEarnedCoins() async {
    final wallet = await getWallet();

    return (wallet?['earnedCoins'] as num?)?.toInt() ?? 0;
  }

  Future<int> getSpentCoins() async {
    final wallet = await getWallet();

    return (wallet?['spentCoins'] as num?)?.toInt() ?? 0;
  }

  Future<int> getPurchasedKnowledge() async {
    final wallet = await getWallet();

    return (wallet?['purchasedKnowledge'] as num?)?.toInt() ?? 0;
  }

  Future<int> getAdsWatched() async {
    final wallet = await getWallet();

    return (wallet?['adsWatched'] as num?)?.toInt() ?? 0;
  }

  Future<int> getReferralCount() async {
    final wallet = await getWallet();

    return (wallet?['referralCount'] as num?)?.toInt() ?? 0;
  }
}
