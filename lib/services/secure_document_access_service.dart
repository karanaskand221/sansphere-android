import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart';

import 'sancoin_service.dart';

class SecureDocumentAccessService {
  SecureDocumentAccessService._();

  static final SecureDocumentAccessService instance =
      SecureDocumentAccessService._();

  final SanCoinService _sanCoinService = SanCoinService.instance;

  /// Fetches the generated PDF derivative for preview.
  ///
  /// Preview access never requests the original Storage file.
  Future<Uint8List> fetchPreviewDocument(String resourceId) async {
    final cleanResourceId = resourceId.trim();

    if (cleanResourceId.isEmpty) {
      throw ArgumentError('Resource ID required.');
    }

    final callable = FirebaseFunctions.instance.httpsCallable(
      'getResourcePreviewUrl',
    );

    final result = await callable.call(<String, dynamic>{
      'resourceId': cleanResourceId,
    });

    final data = Map<String, dynamic>.from(
      result.data as Map,
    );

    final signedUrl = (data['url'] ?? '').toString().trim();

    if (signedUrl.isEmpty) {
      throw Exception('Preview URL was not returned.');
    }

    final uri = Uri.tryParse(signedUrl);

    if (uri == null || !uri.hasScheme) {
      throw Exception('Invalid preview document URL.');
    }

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Preview document request failed (${response.statusCode}).',
      );
    }

    if (response.bodyBytes.isEmpty) {
      throw Exception('The preview document is empty.');
    }

    return Uint8List.fromList(response.bodyBytes);
  }

  /// Fetches an entitled resource directly into memory.
  ///
  /// The backend verifies permanent ownership before returning the
  /// short-lived signed URL. The PDF is never written to a normal
  /// phone-visible download location.
  Future<Uint8List> fetchPurchasedDocument(String resourceId) async {
    final cleanResourceId = resourceId.trim();

    if (cleanResourceId.isEmpty) {
      throw ArgumentError('Resource ID required.');
    }

    final signedUrl = await _sanCoinService.getPurchasedFileUrl(
      cleanResourceId,
    );

    final uri = Uri.tryParse(signedUrl);

    if (uri == null || !uri.hasScheme) {
      throw Exception('Invalid secure document URL.');
    }

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Secure document request failed (${response.statusCode}).',
      );
    }

    if (response.bodyBytes.isEmpty) {
      throw Exception('The document is empty.');
    }

    return Uint8List.fromList(response.bodyBytes);
  }
}
