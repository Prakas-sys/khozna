import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/auth/screens/login_screen.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen>
    with SingleTickerProviderStateMixin {
  bool _isRequesting = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation1;
  late Animation<double> _pulseAnimation2;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _pulseAnimation1 = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _pulseAnimation2 = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _checkPermissionStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionStatus() async {
    if (await Permission.location.isGranted) {
      if (mounted) {
        _navigateToLogin();
      }
    }
  }

  Future<void> _handlePermission() async {
    setState(() => _isRequesting = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        setState(() => _isRequesting = false);
        return;
      }

      PermissionStatus status = await Permission.location.request();

      if (status.isGranted) {
        _navigateToLogin();
      } else {
        await openAppSettings();
      }
    } catch (e) {
      debugPrint('Error requesting location: $e');
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            
            // Premium Pulsing Location Graphic
            Center(
              child: SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Pulse Ring 2
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 250 * _pulseAnimation2.value,
                          height: 250 * _pulseAnimation2.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.brandColor.withOpacity(
                              (1.0 - _pulseAnimation2.value).clamp(0.0, 0.15),
                            ),
                            border: Border.all(
                              color: AppTheme.brandColor.withOpacity(
                                (1.0 - _pulseAnimation2.value).clamp(0.0, 0.2),
                              ),
                              width: 1.5,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Inner Pulse Ring 1
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 190 * _pulseAnimation1.value,
                          height: 190 * _pulseAnimation1.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.brandColor.withOpacity(
                              (1.0 - _pulseAnimation1.value).clamp(0.0, 0.25),
                            ),
                            border: Border.all(
                              color: AppTheme.brandColor.withOpacity(
                                (1.0 - _pulseAnimation1.value).clamp(0.0, 0.3),
                              ),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),

                    // Solid Center Plate (Glow effect)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.brandColor.withOpacity(0.12),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                    ),

                    // Center Glass Container
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.brandColor.withOpacity(0.06),
                        border: Border.all(
                          color: AppTheme.brandColor.withOpacity(0.15),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.brandColor,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(flex: 2),

            // Typography & Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36.0),
              child: Column(
                children: [
                  Text(
                    'Need Your Location',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'To show you rooms and apartments nearby, Khozna requires access to your physical location.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 3),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isRequesting ? null : _handlePermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        shadowColor: Colors.transparent,
                      ),
                      child: _isRequesting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Allow Location Access',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: _navigateToLogin,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: Text(
                        'Not Now',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
