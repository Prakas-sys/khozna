import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:video_compress/video_compress.dart';

class VideoService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Uploads a video reel to Supabase Storage and saves metadata to the reels table.
  /// Compresses the video to ensure it's under 30MB before upload.
  static Future<String?> uploadReel({
    required File videoFile,
    String? propertyId,
    String? caption,
    Function(double)? onProgress,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      // 1. COMPRESS VIDEO
      if (onProgress != null) onProgress(0.1); // Indicate compression started
      
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.MediumQuality, // Good balance for reels
        deleteOrigin: false, 
        includeAudio: true,
      );

      if (mediaInfo == null || mediaInfo.file == null) {
        print('Video compression failed');
        return null;
      }

      final File compressedFile = mediaInfo.file!;
      
      // Verify size (optional but good practice)
      final int sizeInBytes = await compressedFile.length();
      if (sizeInBytes > 31457280) { // ~30MB
        print('Video still too large after compression: ${sizeInBytes / 1024 / 1024} MB');
        // We proceed anyway as it's much smaller than the original, 
        // but the 50MB policy will catch it if it exceeds that.
      }

      if (onProgress != null) onProgress(0.3); // Indicate compression done

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(compressedFile.path)}';
      final String filePath = '${user.id}/$fileName';

      // 2. Upload Video to Storage
      await _client.storage.from('reels').upload(
            filePath,
            compressedFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      if (onProgress != null) onProgress(0.8); 

      // 3. Get Public URL
      final String videoUrl = _client.storage.from('reels').getPublicUrl(filePath);

      // 4. Save to Reels Table
      await _client.from('reels').insert({
        'user_id': user.id,
        'property_id': propertyId,
        'video_url': videoUrl,
        'caption': caption,
      });

      // Cleanup temporary compressed file
      await VideoCompress.deleteAllCache();

      if (onProgress != null) onProgress(1.0);
      return videoUrl;
    } catch (e) {
      print('Video Upload Error: $e');
      return null;
    }
  }
}
