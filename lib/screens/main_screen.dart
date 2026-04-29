import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/features/property/screens/home_screen.dart';
import 'package:khozna/features/property/screens/reels_screen.dart';
import 'package:khozna/features/chat/screens/messages_screen.dart';
import 'package:khozna/features/property/screens/add_property_screen.dart';
import 'package:khozna/features/profile/screens/kyc_screen.dart';
import 'package:khozna/features/profile/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isKycVerified = false;
  bool _isCheckingKyc = true;
  String _kycStatus = 'not_started';

  // Key to communicate with HomeScreen for refreshing data
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(key: _homeKey),
      const ReelsScreen(),
      const MessagesScreen(),
      const ProfileScreen(),
    ];
    SupabaseService.initRealtimeListeners();
    _checkKycStatus();

    // Listen for real-time KYC status changes to show the "Auto-Pilot" popup
    lastKycNotification.addListener(_handleKycStatusUpdate);
  }

  void _handleKycStatusUpdate() {
    final data = lastKycNotification.value;
    if (data == null || !mounted) return;

    final title = data['title'] ?? 'KYC Update';
    final message = data['message'] ?? '';
    final isSuccess = title.toString().contains('Approved') || title.toString().contains('Verified');

    HapticFeedback.heavyImpact();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
                  color: isSuccess ? Colors.green : Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (isSuccess) {
                      _checkKycStatus(); // Refresh local state
                      setState(() => _currentIndex = 0); // Go home
                    } else {
                      // Navigate to Profile to see the rejection card
                      setState(() => _currentIndex = 3);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? Colors.green : Colors.black87,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    isSuccess ? 'Great!' : 'Review Status',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkKycStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isCheckingKyc = false);
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('kyc_status')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isKycVerified = (data != null && data['kyc_status'] == 'verified');
          _kycStatus = data?['kyc_status'] ?? 'not_started';
          _isCheckingKyc = false;
        });
      }
    } catch (e) {
      debugPrint('Initial KYC check failed: $e');
      if (mounted) setState(() => _isCheckingKyc = false);
    }
  }

  void _onTabTapped(int index) {
    HapticFeedback.lightImpact();
    // strict Auth Wall: No guest access to any tab
    // Removed mandatory Auth Wall for guest exploration

    setState(() {
      _currentIndex = index;
    });
    if (index == 2) messageBadgeCount.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    const Color activeColor = AppTheme.brandColor;
    const Color inactiveColor = Color(0xFF717171);

    return AnimatedBuilder(
      animation: Listenable.merge([messageBadgeCount, notificationBadgeCount]),
      builder: (context, _) {
        final mBadge = messageBadgeCount.value;
        final nBadge = notificationBadgeCount.value;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_currentIndex != 0) {
              setState(() => _currentIndex = 0);
            } else {
              // If already on home tab, allow app to close or show exit confirmation
              // For now, let's allow pop if on index 0 to avoid getting "stuck"
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            backgroundColor: _currentIndex == 1 ? Colors.black : Colors.white,
            extendBody: true, // Allow content to flow under the glass navbar
            body: _pages[_currentIndex],
            bottomNavigationBar: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: _currentIndex == 1 
                        ? Colors.black.withValues(alpha: 0.8) 
                        : Colors.white.withValues(alpha: 0.85),
                    border: Border(
                      top: BorderSide(
                        color: _currentIndex == 1 
                            ? Colors.white.withValues(alpha: 0.1) 
                            : Colors.grey.withValues(alpha: 0.2), 
                        width: 1.0
                      ),
                    ),
                  ),
                  child: BottomAppBar(
                    color: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    height: 58,
                    elevation: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      0,
                      'Khozna',
                      'assets/icons/explore.svg',
                      activeColor,
                      inactiveColor,
                      0,
                    ),
                    _buildNavItem(
                      1,
                      'Reels',
                      'assets/icons/reels.svg',
                      activeColor,
                      inactiveColor,
                      0,
                    ),
                    // Central add button
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final user =
                              Supabase.instance.client.auth.currentUser;
                          if (user == null) return;

                          // Instant reaction if cached
                          if (_isKycVerified) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddPropertyScreen(),
                              ),
                            );
                            return;
                          }

                          // If not cached-verified, show a quick check or go to KYC
                          if (_isCheckingKyc) {
                            // Wait for the initial check to finish if it's currently running
                            int retries = 0;
                            while (_isCheckingKyc && retries < 10) {
                              await Future.delayed(
                                const Duration(milliseconds: 200),
                              );
                              retries++;
                            }
                          }

                          // Double check in case they just got verified
                          if (!_isKycVerified) {
                            try {
                              final data = await Supabase.instance.client
                                  .from('profiles')
                                  .select('kyc_status')
                                  .eq('id', user.id)
                                  .maybeSingle();
                              if (data != null &&
                                  data['kyc_status'] == 'verified') {
                                setState(() => _isKycVerified = true);
                              }
                            } catch (e) {
                              debugPrint('KYC Re-check error: $e');
                            }
                          }

                          if (!mounted) return;

                          // Fetch fresh status to distinguish pending vs not_started
                          String freshStatus = _kycStatus;
                          try {
                            final freshData = await Supabase.instance.client
                                .from('profiles')
                                .select('kyc_status')
                                .eq('id', user.id)
                                .maybeSingle();
                            freshStatus = freshData?['kyc_status'] ?? 'not_started';
                            setState(() => _kycStatus = freshStatus);
                          } catch (_) {}

                          if (!mounted) return;

                          if (!_isKycVerified) {
                            if (freshStatus == 'pending') {
                              // Show pending info dialog — do NOT open KYC form again
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.hourglass_top_rounded, color: Colors.orange.shade700, size: 40),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'Verification in Progress',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Your documents are being reviewed.\nVerification takes up to 48 hours.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600], height: 1.5),
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.brandColor,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                          ),
                                          child: Text('Got it', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              // Not started — open KYC form
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const KycScreen()),
                              );
                            }
                          } else {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddPropertyScreen(),
                              ),
                            );

                            // If a property was successfully published, refresh the home screen
                            if (result == true) {
                              // _homeKey.currentState?.refreshData();
                              setState(
                                () => _currentIndex = 0,
                              ); // Ensure we are on Home tab
                            }
                          }
                        },
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Spacer(),
                            Transform.translate(
                              offset: const Offset(0, -4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 22,
                                  weight: 700,
                                ),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                    _buildNavItem(
                      2,
                      'Messages',
                      'assets/icons/message.svg',
                      activeColor,
                      inactiveColor,
                      mBadge,
                    ),
                    _buildNavItem(
                      3,
                      'Profile',
                      'assets/icons/profile.svg',
                      activeColor,
                      inactiveColor,
                      nBadge,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  },
);
  }

  Widget _buildNavItem(
    int index,
    String label,
    String iconPath,
    Color activeColor,
    Color inactiveColor,
    int badgeCount,
  ) {
    final bool isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Top Indicator Line
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: 3.0,
              width: isSelected ? 45 : 0,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.brandColor : Colors.transparent,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(3),
                ),
              ),
            ),
            const Spacer(),
            // Outer container for icon + badge
            SizedBox(
              width: 36,
              height: 28,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Icon with simulated stroke for "bold" look when selected
                  AnimatedScale(
                    scale: isSelected ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Stack(
                      children: [
                        if (isSelected) ...[
                          // Simulated stroke layers (offsets to thicken the SVG lines)
                          for (double i = -0.4; i <= 0.4; i += 0.4)
                            for (double j = -0.4; j <= 0.4; j += 0.4)
                              if (i != 0 || j != 0)
                                Transform.translate(
                                  offset: Offset(i, j),
                                  child: SvgPicture.asset(
                                    iconPath,
                                    width: 24,
                                    height: 24,
                                    colorFilter: ColorFilter.mode(
                                      activeColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                        ],
                        // Main Icon Layer
                        SvgPicture.asset(
                          iconPath,
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            isSelected ? activeColor : inactiveColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Premium red badge
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -2,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0000), // Pure vibrant red
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ), // Pure white border for contrast
                        ),
                        child: Center(
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Minimal gap and slight upward pull for text
            Transform.translate(
              offset: const Offset(0, -3.5),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? activeColor : inactiveColor,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
