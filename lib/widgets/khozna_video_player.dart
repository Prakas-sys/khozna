import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/widgets/khozna_image.dart';
import 'package:khozna/core/utils/app_notifiers.dart';

class KhoznaVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final bool autoPlay;
  final bool loop;
  final VoidCallback? onVideoEnded;

  const KhoznaVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.autoPlay = true,
    this.loop = true,
    this.onVideoEnded,
  });

  @override
  State<KhoznaVideoPlayer> createState() => _KhoznaVideoPlayerState();
}

class _KhoznaVideoPlayerState extends State<KhoznaVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _hasEnded = false;
  bool _wasPlayingBeforeTabSwitch = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    // Listen for tab visibility changes to pause/resume video
    reelsTabActive.addListener(_onReelsTabChanged);
  }

  void _onReelsTabChanged() {
    if (!_isInitialized) return;
    if (reelsTabActive.value) {
      // Returned to Reels tab — resume if it was playing before
      if (_wasPlayingBeforeTabSwitch) {
        _controller.play();
      }
    } else {
      // Left Reels tab — pause the video
      _wasPlayingBeforeTabSwitch = _controller.value.isPlaying;
      _controller.pause();
    }
  }

  void _videoListener() {
    if (!_controller.value.isInitialized) return;
    final position = _controller.value.position;
    final duration = _controller.value.duration;

    if (position >= duration && duration > Duration.zero) {
      if (!_hasEnded) {
        _hasEnded = true;
        if (widget.onVideoEnded != null) {
          widget.onVideoEnded!();
        }
      }
    } else if (position < duration) {
      _hasEnded = false;
    }
  }

  Future<void> _initializePlayer() async {
    if (widget.videoUrl.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller.addListener(_videoListener);

    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (widget.autoPlay && reelsTabActive.value) {
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
    reelsTabActive.removeListener(_onReelsTabChanged);
    _controller.removeListener(_videoListener);
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
