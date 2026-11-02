import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config.dart';

/// Ürün fotoğrafları Cloudinary'de (ücretsiz plan) saklanır.
/// Firebase Storage 2026'dan beri ücretli plan istediği için kullanılmıyor.
class ImageService {
  /// Fotoğrafı yükler ve herkese açık adresini (https) döndürür.
  static Future<String> upload(Uint8List bytes, String filename) async {
    if (!isCloudinaryConfigured) {
      throw Exception(
          'Cloudinary bilgileri lib/config.dart içinde doldurulmamış.');
    }
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$kCloudinaryCloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = kCloudinaryUploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: filename.isEmpty ? 'urun.jpg' : filename));

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode != 200) {
      throw Exception(
          'Fotoğraf yüklenemedi (${response.statusCode}) ${_errorText(response.body)}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['secure_url'] as String;
  }

  static String _errorText(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      return (map['error'] as Map<String, dynamic>)['message'] as String;
    } catch (_) {
      return '';
    }
  }

  /// Cloudinary adresine boyut + otomatik format/kalite ekler: telefonlar yalnızca
  /// ihtiyaç duydukları küçük, sıkıştırılmış (WebP/AVIF) görseli indirir.
  static String optimized(String url, {int width = 500}) {
    const marker = '/upload/';
    final i = url.indexOf(marker);
    if (i < 0 || !url.contains('res.cloudinary.com')) return url;
    final head = url.substring(0, i + marker.length);
    final tail = url.substring(i + marker.length);
    return '${head}w_$width,c_limit,f_auto,q_auto/$tail';
  }
}
