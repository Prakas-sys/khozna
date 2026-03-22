import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  static final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static final String apiKey = dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  
  // For security, unsigned uploads are recommended for client-side apps.
  // You should create an "unsigned upload preset" in your Cloudinary Dashboard.
  static final String uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? ''; 

  /// Uploads any image to Cloudinary and returns the URL.
  static Future<String?> uploadImage(File imageFile) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

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
        print('Cloudinary Upload Failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Cloudinary Error: $e');
      return null;
    }
  }

  /// Uploads an image to Cloudinary and saves the URL to Supabase.
  static Future<String?> uploadPropertyImage(File imageFile, String propertyId) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

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
        print('Cloudinary Upload Failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Cloudinary Error: $e');
      return null;
    }
  }
}
