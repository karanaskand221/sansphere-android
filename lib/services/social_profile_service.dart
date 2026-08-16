import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class SocialProfileService {
  SocialProfileService._();

  static final SocialProfileService instance = SocialProfileService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: FirebaseAuth.instance.app,
    databaseId: 'sansphere',
  );

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    app: FirebaseAuth.instance.app,
    region: 'us-central1',
  );

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<void> followUser(String targetUid) async {
    final uid = targetUid.trim();

    if (uid.isEmpty) {
      throw ArgumentError('Target user is required.');
    }

    await _functions.httpsCallable('followUser').call(<String, dynamic>{
      'targetUid': uid,
    });
  }

  Future<void> unfollowUser(String targetUid) async {
    final uid = targetUid.trim();

    if (uid.isEmpty) {
      throw ArgumentError('Target user is required.');
    }

    await _functions.httpsCallable('unfollowUser').call(<String, dynamic>{
      'targetUid': uid,
    });
  }

  Future<bool> isFollowing(String targetUid) async {
    final uid = targetUid.trim();

    if (uid.isEmpty) {
      return false;
    }

    final result = await _functions.httpsCallable('checkFollowing').call(
      <String, dynamic>{'targetUid': uid},
    );

    final data = result.data;

    if (data is Map) {
      return data['following'] == true;
    }

    return false;
  }

  Future<Map<String, dynamic>> getPublicProfile(String targetUid) async {
    final uid = targetUid.trim();

    if (uid.isEmpty) {
      throw ArgumentError('Target user is required.');
    }

    final result = await _functions.httpsCallable('getPublicProfile').call(
      <String, dynamic>{'targetUid': uid},
    );

    final data = result.data;

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw StateError('Invalid public profile response.');
  }

  Future<List<Map<String, dynamic>>> getVisibleProfileResources({
    required String targetUid,
    required String resourceType,
  }) async {
    final uid = targetUid.trim();
    final type = resourceType.trim();

    if (uid.isEmpty) {
      throw ArgumentError('Target user is required.');
    }

    if (type != 'uploaded' && type != 'purchased') {
      throw ArgumentError('Invalid resource type.');
    }

    final result = await _functions
        .httpsCallable('getVisibleProfileResources')
        .call(<String, dynamic>{'targetUid': uid, 'resourceType': type});

    final data = result.data;

    if (data is! Map) {
      throw StateError('Invalid resource response.');
    }

    final rawResources = data['resources'];

    if (rawResources is! List) {
      return <Map<String, dynamic>>[];
    }

    return rawResources
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchFollowers(String uid) {
    return _users
        .doc(uid)
        .collection('followers')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchFollowing(String uid) {
    return _users
        .doc(uid)
        .collection('following')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
