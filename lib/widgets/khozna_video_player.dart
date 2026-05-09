import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/widgets/khozna_image.dart';

class KhoznaVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final bool autoPlay;
  final bool loop;

  const KhoznaVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.autoPlay = true,
    this.loop = true,
  });

  @override
  State<KhoznaVideoPlayer> createState() => _KhoznaVideoPlayerState();
}

class _KhoznaVideoPlayerState extends State<KhoznaVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (widget.videoUrl.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (widget.autoPlay) {
          _controller.play();
        }
        if (widget.loop) {
          _controller.setLooping(true);
        }
      }
    } catch (e) {
      debugPrint('KhoznaVideoPlayer error: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(KhoznaVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller.dispose();
      _isInitialized = false;
      _hasError = false;
      _initializePlayer();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || widget.videoUrl.isEmpty) {
      return _buildPlaceholder();
    }

    if (!_isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (widget.thumbnailUrl != null)
            KhoznaImage(
              imageUrl: widget.thumbnailUrl!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          const Center(
            child: CircularProgressIndicator(color: AppTheme.brandColor),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Blur (to fill gaps for "small ratio" videos)
          if (_isInitialized)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4),
                  BlendMode.darken,
                ),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),
              ),
            ),

          // Main Video with proper Aspect Ratio
          if (_isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),

          if (!_controller.value.isPlaying && _isInitialized)
            Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 80,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty)
            Opacity(
              opacity: 0.3,
              child: KhoznaImage(
                imageUrl: widget.thumbnailUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(
                    Icons.videocam_off_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.videoUrl.isEmpty
                      ? 'Video Coming Soon'
                      : 'Failed to load video',
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
