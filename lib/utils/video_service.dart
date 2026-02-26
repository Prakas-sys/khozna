import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class VideoService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Uploads a video reel to Supabase Storage and saves metadata to the reels table.
  /// [onProgress] callback returns a double from 0.0 to 1.0.
  static Future<String?> uploadReel({
    required File videoFile,
    String? propertyId,
    String? caption,
    Function(double)? onProgress,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(videoFile.path)}';
      final String filePath = '${user.id}/$fileName';

      // 1. Upload Video to Storage
      // Supabase storage upload with progress is not directly supported in the standard 'upload' method,
      // but we can simulate progress or use the 'onProgress' if available in future SDKs.
      // For now, we perform the upload.
      
      await _client.storage.from('reels').upload(
            filePath,
            videoFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      if (onProgress != null) onProgress(0.8); // Simple progress simulation

      // 2. Get Public URL
      final String videoUrl = _client.storage.from('reels').getPublicUrl(filePath);

      // 3. Save to Reels Table
      await _client.from('reels').insert({
        'user_id': user.id,
        'property_id': propertyId,
        'video_url': videoUrl,
        'caption': caption,
      });

      if (onProgress != null) onProgress(1.0);
      return videoUrl;
    } catch (e) {
      print('Video Upload Error: $e');
      return null;
    }
  }
}
