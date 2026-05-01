import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as path;
import 'package:khozna/core/security/app_logger.dart';

class CloudinaryService {
  static final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static final String apiKey = dotenv.env['CLOUDINARY_API_KEY'] ?? '';

  // For security, unsigned uploads are recommended for client-side apps.
  // You should create an "unsigned upload preset" in your Cloudinary Dashboard.
  static final String uploadPreset =
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  /// Uploads any image to Cloudinary and returns the URL.
  static Future<String?> uploadImage(File imageFile) async {
    // 🔐 Strict File Validation
    final fileSize = await imageFile.length();
    if (fileSize > 5 * 1024 * 1024) throw Exception('Image exceeds 5MB limit');
    
    final ext = path.extension(imageFile.path).toLowerCase();
    if (!['.jpg', '.jpeg', '.png', '.webp'].contains(ext)) {
      throw Exception('Invalid image format. Only JPG, PNG, WEBP allowed.');
    }

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'];
      } else {
        AppLogger.logApiError(endpoint: 'cloudinary/uploadImage', error: 'Upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      AppLogger.logApiError(endpoint: 'cloudinary/uploadImage', error: e.toString());
      return null;
    }
  }

  /// Uploads an image to Cloudinary and saves the URL to Supabase.
  static Future<String?> uploadPropertyImage(
    File imageFile,
    String propertyId,
  ) async {
    // 🔐 Strict File Validation
    final fileSize = await imageFile.length();
    if (fileSize > 5 * 1024 * 1024) throw Exception('Image exceeds 5MB limit');
    
    final ext = path.extension(imageFile.path).toLowerCase();
    if (!['.jpg', '.jpeg', '.png', '.webp'].contains(ext)) {
      throw Exception('Invalid image format. Only JPG, PNG, WEBP allowed.');
    }

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    try {
      // 1. Prepare Request
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      // 2. Execute Upload
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        final String imageUrl = jsonMap['secure_url'];

        // 3. Store in Supabase
        await Supabase.instance.client.from('property_images').insert({
          'property_id': propertyId,
          'image_url': imageUrl,
        });

        return imageUrl;
      } else {
        AppLogger.logApiError(endpoint: 'cloudinary/uploadPropertyImage', error: 'Upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      AppLogger.logApiError(endpoint: 'cloudinary/uploadPropertyImage', error: e.toString());
      return null;
    }
  }

  /// Uploads a video to Cloudinary and returns the URL.
  static Future<String?> uploadVideo(File videoFile) async {
    // 🔐 Strict File Validation
    final fileSize = await videoFile.length();
    if (fileSize > 50 * 1024 * 1024) throw Exception('Video exceeds 50MB limit');
    
    final ext = path.extension(videoFile.path).toLowerCase();
    if (!['.mp4', '.mov'].contains(ext)) {
      throw Exception('Invalid video format. Only MP4 and MOV allowed.');
    }

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/video/upload',
    );

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', videoFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'];
      } else {
        AppLogger.logApiError(endpoint: 'cloudinary/uploadVideo', error: 'Upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      AppLogger.logApiError(endpoint: 'cloudinary/uploadVideo', error: e.toString());
      return null;
    }
  }
}
