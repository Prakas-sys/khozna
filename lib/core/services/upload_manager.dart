import 'dart:io';
import 'package:khozna/core/services/cloudinary_service.dart';
import 'package:video_compress/video_compress.dart';
import 'package:flutter/foundation.dart';

class UploadManager extends ChangeNotifier {
  static final UploadManager instance = UploadManager._();
  UploadManager._();

  final Map<String, String> _uploadedUrls = {};
  final Map<String, bool> _uploading = {};
  final Map<String, double> _progress = {};

  bool isUploading(String path) => _uploading[path] ?? false;
  String? getUrl(String path) => _uploadedUrls[path];
  double getProgress(String path) => _progress[path] ?? 0.0;

  Future<void> startUpload(File file, {bool isVideo = false}) async {
    final path = file.path;
    if (_uploadedUrls.containsKey(path) || _uploading[path] == true) return;

    _uploading[path] = true;
    _progress[path] = 0.1;
    notifyListeners();

    try {
      String? url;
      if (isVideo) {
        debugPrint('UploadManager: Compressing video $path');
        final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
          path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
        );
        if (mediaInfo?.path != null) {
          _progress[path] = 0.3;
          notifyListeners();
          url = await CloudinaryService.uploadVideo(File(mediaInfo!.path!));
        }
      } else {
        url = await CloudinaryService.uploadImage(file);
      }

      if (url != null) {
        _uploadedUrls[path] = url;
        _progress[path] = 1.0;
        debugPrint('UploadManager: Upload success for $path -> $url');
      }
    } catch (e) {
      debugPrint('UploadManager: Error uploading $path: $e');
    } finally {
      _uploading[path] = false;
      notifyListeners();
    }
  }

  void clear() {
    _uploadedUrls.clear();
    _uploading.clear();
    _progress.clear();
  }
}
