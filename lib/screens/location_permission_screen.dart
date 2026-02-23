import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isRequesting = false;

  Future<void> _handlePermission() async {
    setState(() => _isRequesting = true);
    
    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Direct "Push" to Location Settings
        await Geolocator.openLocationSettings();
        setState(() => _isRequesting = false);
        return;
      }

      // 2. Request Permission
      PermissionStatus status = await Permission.location.request();

      if (status.isGranted) {
        _navigateToLogin();
      } else {
        // Direct "Push" to App Settings if denied, permanently denied, or restricted
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              const Color(0xFFF9FBFF),
              AppTheme.brandColor.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // NEW: Richer 3D UI ICON
                _buildPremium3DIcon(),
                const Spacer(flex: 3),
                // Content with staggered fade-in
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutBack,
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Text(
                        'Enable Real-time\nLocation',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          height: 1.1,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Let Khozna find properties near you. Get accurate listings and directions in your neighborhood.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.6,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 4),
                // Action Buttons
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 62,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [AppTheme.brandColor, Color(0xFFFF8C42)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.brandColor.withOpacity(0.35),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isRequesting ? null : _handlePermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isRequesting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                'ALLOW ACCESS',
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _navigateToLogin,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[500],
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      ),
                      child: Text(
                        'NOT NOW, MAYBE LATER',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremium3DIcon() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Radar Rings
              _buildModernRadarRing(180 * value, 0.12, 1),
              _buildModernRadarRing(240 * value, 0.06, 2),
              
              // 2. Shadows for depth
              Transform.translate(
                offset: const Offset(0, 40),
                child: Container(
                  width: 100 * value,
                  height: 20 * value,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Main Orb / Base
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.blue.shade50.withOpacity(0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                    BoxShadow(
                      color: AppTheme.brandColor.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF0F6FF),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: AppTheme.brandColor,
                          size: 45,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Floating 3D Pin with dynamic bounce
              _buildBouncingPin(value),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernRadarRing(double size, double opacity, int index) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.brandColor.withOpacity(opacity),
          width: 3,
        ),
      ),
    );
  }

  Widget _buildBouncingPin(double value) {
    // Creating a subtle floating animation using the tween value
    return AnimatedBuilder(
      animation: AlwaysStoppedAnimation(value),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -65 - (8 * (1 - value))),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.brandColor, Color(0xFFFF8C42)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brandColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 34),
          ),
        );
      },
    );
  }
}
