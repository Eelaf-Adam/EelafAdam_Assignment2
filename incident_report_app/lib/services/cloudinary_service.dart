import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Uses an unsigned preset, so no API secret is stored in the app.
/// Chosen over Firebase Storage, which requires the paid Blaze plan.
class CloudinaryService {
  CloudinaryService({http.Client? client}) : _client = client ?? http.Client();

  static const _cloudName = 'vrqsrjl2';
  static const _uploadPreset = 'ccvubtoo';
  static const _folder = 'rapport_incidents';

  final http.Client _client;

  Future<String> uploadImage(File file) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = _folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final http.Response response;
    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 60));
      response = await http.Response.fromStream(streamed);
    } on SocketException {
      throw const CloudinaryException(
        'No internet connection. Check your network and try again.',
      );
    } catch (_) {
      throw const CloudinaryException('Photo upload timed out. Try again.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      final error = body['error'] as Map<String, dynamic>?;
      throw CloudinaryException(
        'Photo upload failed: ${error?['message'] ?? response.statusCode}',
      );
    }

    return body['secure_url'] as String;
  }
}

class CloudinaryException implements Exception {
  const CloudinaryException(this.message);
  final String message;

  @override
  String toString() => message;
}
