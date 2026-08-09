import 'package:cloud_functions/cloud_functions.dart';

class SanCoinsService {
  SanCoinsService._();

  static final SanCoinsService instance = SanCoinsService._();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<Map<String, dynamic>> initializeSanCoins() async {
    final callable = _functions.httpsCallable('initializeSanCoins');

    final result = await callable.call();

    return Map<String, dynamic>.from(
      result.data as Map,
    );
  }

  Future<Map<String, dynamic>> applyReferral(String code) async {
    final callable = _functions.httpsCallable('applyReferral');

    final result = await callable.call({
      'code': code.trim().toUpperCase(),
    });

    return Map<String, dynamic>.from(
      result.data as Map,
    );
  }

  Future<Map<String, dynamic>> rewardAd(String rewardId) async {
    final callable = _functions.httpsCallable('rewardAd');

    final result = await callable.call({
      'rewardId': rewardId,
    });

    return Map<String, dynamic>.from(
      result.data as Map,
    );
  }

  Future<Map<String, dynamic>> purchaseResource(
    String resourceId,
  ) async {
    final callable = _functions.httpsCallable('purchaseResource');

    final result = await callable.call({
      'resourceId': resourceId,
    });

    return Map<String, dynamic>.from(
      result.data as Map,
    );
  }

  Future<bool> checkPurchase(String resourceId) async {
    final callable = _functions.httpsCallable('checkPurchase');

    final result = await callable.call({
      'resourceId': resourceId,
    });

    final data = Map<String, dynamic>.from(
      result.data as Map,
    );

    return data['purchased'] == true;
  }

  Future<String> getPurchasedFileUrl(String resourceId) async {
    final callable = _functions.httpsCallable('getPurchasedFileUrl');

    final result = await callable.call({
      'resourceId': resourceId,
    });

    final data = Map<String, dynamic>.from(
      result.data as Map,
    );

    final url = data['url'];

    if (url is! String || url.isEmpty) {
      throw Exception('Invalid purchased file URL.');
    }

    return url;
  }
}
