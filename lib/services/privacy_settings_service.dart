import 'package:cloud_functions/cloud_functions.dart';

class PrivacySettingsService {
  PrivacySettingsService._();

  static final PrivacySettingsService instance = PrivacySettingsService._();

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  Future<Map<String, dynamic>> updatePrivacySettings({
    required String profileVisibility,
    required String uploadedResourcesVisibility,
    required String purchasedResourcesVisibility,
    required bool showActivity,
    required bool allowMessages,
  }) async {
    const validProfileVisibility = {'public', 'private'};

    const validResourceVisibility = {'public', 'followers', 'private'};

    if (!validProfileVisibility.contains(profileVisibility)) {
      throw ArgumentError('Invalid profile visibility.');
    }

    if (!validResourceVisibility.contains(uploadedResourcesVisibility)) {
      throw ArgumentError('Invalid uploaded resource visibility.');
    }

    if (!validResourceVisibility.contains(purchasedResourcesVisibility)) {
      throw ArgumentError('Invalid purchased resource visibility.');
    }

    final callable = _functions.httpsCallable('updatePrivacySettings');

    final result = await callable.call({
      'profileVisibility': profileVisibility,
      'uploadedResourcesVisibility': uploadedResourcesVisibility,
      'purchasedResourcesVisibility': purchasedResourcesVisibility,
      'showActivity': showActivity,
      'allowMessages': allowMessages,
    });

    return Map<String, dynamic>.from(result.data as Map);
  }
}
