import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class KhoznaFeedback {
  /// Show a premium success dialog with haptic feedback
  static void showSuccess(BuildContext context, String message) {
    HapticFeedback.mediumImpact();
    _showFeedback(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF00C853),
      title: 'Success',
    );
  }

  /// Show a premium error dialog with haptic feedback
  static void showError(BuildContext context, String message) {
    HapticFeedback.vibrate();
    _showFeedback(
      context,
      message: message,
      icon: Icons.error_rounded,
      color: const Color(0xFFFF3D00),
      title: 'Oops!',
    );
  }

  /// Internal builder for the premium feedback dialog
  static void _showFeedback(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color color,
    required String title,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => FadeInDialog(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Icon Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 44),
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Dismiss',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom animation wrapper for the feedback dialog
class FadeInDialog extends StatefulWidget {
  final Widget child;
  const FadeInDialog({super.key, required this.child});

  @override
  State<FadeInDialog> createState() => _FadeInDialogState();
}

class _FadeInDialogState extends State<FadeInDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.5, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: 0.6 + (0.4 * _scaleAnimation.value),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
