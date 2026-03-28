import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme/app_theme.dart';

class VoiceSearchOverlay extends StatefulWidget {
  final Function(String) onResult;

  const VoiceSearchOverlay({super.key, required this.onResult});

  @override
  State<VoiceSearchOverlay> createState() => _VoiceSearchOverlayState();
}

class _VoiceSearchOverlayState extends State<VoiceSearchOverlay> with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Listening...';
  double _confidence = 1.0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _startListening();
  }

  @override
  void dispose() {
    _controller.dispose();
    _speech.stop();
    super.dispose();
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          if (mounted && _isListening) {
             setState(() => _isListening = false);
             if (_text != 'Listening...' && _text.isNotEmpty) {
               Future.delayed(const Duration(milliseconds: 500), () {
                 if (mounted) widget.onResult(_text);
               });
             }
          }
        }
      },
      onError: (val) => print('Error: $val'),
    );
    if (available) {
      if (mounted) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isListening = false;
          _text = 'Speech recognition not available';
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Spacer(),
          ScaleTransition(
            scale: _animation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.brandColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.brandColor.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.mic,
                color: AppTheme.brandColor,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _isListening ? 'Listening...' : 'Searching...',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppTheme.brandColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Text(
             'Speak clearly: "Flat in Baluwatar"',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
