import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class ResourceRatingService {
  ResourceRatingService._();

  static final ResourceRatingService instance =
      ResourceRatingService._();

  final FirebaseFirestore _vaultFirestore =
      FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'sanvault',
  );

  final FirebaseFirestore _userFirestore =
      FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'sansphere',
  );

  final FirebaseFunctions _functions =
      FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> _ratings(
    String resourceId,
  ) {
    return _vaultFirestore
        .collection('academic_vault')
        .doc(resourceId)
        .collection('ratings');
  }

  Future<bool> canRate(String resourceId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return false;

    final cleanResourceId = resourceId.trim();

    if (cleanResourceId.isEmpty) return false;

    final purchase = await _userFirestore
        .collection('purchases')
        .doc('${user.uid}_$cleanResourceId')
        .get();

    if (!purchase.exists) return false;

    final data = purchase.data();

    return data?['buyerId'] == user.uid &&
        data?['resourceId'] == cleanResourceId &&
        data?['permanentlyOwned'] == true;
  }

  Future<Map<String, dynamic>?> getMyRating(
    String resourceId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return null;

    final doc = await _ratings(resourceId).doc(user.uid).get();

    if (!doc.exists) return null;

    return {
      'id': doc.id,
      ...?doc.data(),
    };
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamRatings(
    String resourceId,
  ) {
    return _ratings(resourceId)
        .orderBy('updatedAt', descending: true)
        .limit(5)
        .snapshots();
  }

  Future<void> submitRating({
    required String resourceId,
    required int rating,
    required String review,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'Please sign in to rate this resource.',
      );
    }

    if (rating < 1 || rating > 5) {
      throw Exception(
        'Rating must be between 1 and 5.',
      );
    }

    final cleanResourceId = resourceId.trim();

    if (cleanResourceId.isEmpty) {
      throw Exception('Resource ID is required.');
    }

    try {
      await _functions
          .httpsCallable('submitResourceRating')
          .call({
        'resourceId': cleanResourceId,
        'rating': rating,
        'review': review.trim(),
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(
        e.message ?? 'Could not submit your rating.',
      );
    }
  }
}
