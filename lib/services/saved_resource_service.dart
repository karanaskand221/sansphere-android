import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class SavedResourceService {
  SavedResourceService._();

  static final SavedResourceService instance = SavedResourceService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'sansphere',
  );

  CollectionReference<Map<String, dynamic>> _savedCollection(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('saved_resources');
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;

    if (uid == null || uid.trim().isEmpty) {
      throw Exception('You must be signed in to save resources.');
    }

    return uid;
  }

  String _cleanResourceId(String resourceId) {
    final id = resourceId.trim();

    if (id.isEmpty) {
      throw ArgumentError('Resource ID required.');
    }

    return id;
  }

  Future<bool> isSaved(String resourceId) async {
    final uid = _requireUid();
    final id = _cleanResourceId(resourceId);

    final doc = await _savedCollection(uid).doc(id).get();

    return doc.exists;
  }

  Future<void> saveResource(String resourceId) async {
    final uid = _requireUid();
    final id = _cleanResourceId(resourceId);

    await _savedCollection(
      uid,
    ).doc(id).set({'resourceId': id, 'savedAt': FieldValue.serverTimestamp()});
  }

  Future<void> removeSavedResource(String resourceId) async {
    final uid = _requireUid();
    final id = _cleanResourceId(resourceId);

    await _savedCollection(uid).doc(id).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamSavedResources() {
    final uid = _requireUid();

    return _savedCollection(
      uid,
    ).orderBy('savedAt', descending: true).snapshots();
  }
}
