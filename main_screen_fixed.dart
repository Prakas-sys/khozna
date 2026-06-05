import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/core/utils/offline_storage.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/features/property/screens/home_screen.dart';
import 'package:khozna/features/property/screens/reels_screen.dart';
import 'package:khozna/features/chat/screens/messages_screen.dart';
import 'package:khozna/features/property/screens/post_property_intro_screen.dart';
import 'package:khozna/features/profile/screens/kyc_screen.dart';
import 'package:khozna/features/profile/screens/profile_screen.dart';
import 'package:khozna/core/guards/auth_guard.dart';

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
    // Listen for regular real-time notifications to show Airbnb-style toasts
    lastRealtimeNotification.addListener(_handleRealtimeNotification);
  }

  @override
  void dispose() {
    lastKycNotification.removeListener(_handleKycStatusUpdate);
    lastRealtimeNotification.removeListener(_handleRealtimeNotification);
    reelsTabActive.value = false;
    super.dispose();
  }

  void _handleKycStatusUpdate() {
    final data = lastKycNotification.value;
    if (data == null || !mounted) return;

    final title = data['title'] ?? 'KYC Update';
    final message = data['message'] ?? '';
    final isSuccess =
        title.toString().contains('Approved') ||
        title.toString().contains('Verified');

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
                  color: isSuccess
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess
                      ? Icons.verified_user_rounded
                      : Icons.gpp_bad_rounded,
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isSuccess ? 'Great!' : 'Review Status',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRealtimeNotification() {
    final data = lastRealtimeNotification.value;
    if (data == null || !mounted) return;

    // Don't show toast for KYC notifications as they have their own full-screen popup
    if (data['type'] == 'kyc_update' || (data['title'] ?? '').toString().contains('KYC')) {
      return;
    }

    final String title = data['title'] ?? 'New Notification';
    final String message = data['message'] ?? '';
    final String type = data['type'] ?? 'general';

    HapticFeedback.lightImpact();

    // Show a premium top banner (Airbnb style)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        dismissDirection: DismissDirection.up,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 180,
          left: 16,
          right: 16,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.brandColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _getNotificationIcon(type),
                    color: AppTheme.brandColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'message': return Icons.chat_bubble_rounded;
      case 'booking_request': return Icons.home_work_rounded;
      case 'visit_request': return Icons.visibility_rounded;
      case 'payment_received': return Icons.account_balance_wallet_rounded;
      case 'visit_approved': return Icons.check_circle_rounded;
      case 'recommendation': return Icons.star_rounded;
      default: return Icons.notifications_active_rounded;
    }
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
      // Offline fallback: use persistent cache
      final cached = await OfflineStorage.loadProfileCache();
      if (mounted) {
        setState(() {
          if (cached != null) {
            _kycStatus = cached['kyc_status'] ?? 'not_started';
            _isKycVerified = _kycStatus == 'verified';
          }
          _isCheckingKyc = false;
        });
      }
    }
  }

  void _onTabTapped(int index) {
    HapticFeedback.lightImpact();
    
    if (index == 2) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        AuthGuard.showLoginPrompt(
          context,
          title: 'Messages',
          message: 'Log in to view your messages and chat with property owners.',
        );
        return;
      }
    }

    setState(() {
      _currentIndex = index;
    });
    // Pause/resume reel videos based on tab visibility
    reelsTabActive.value = (index == 1);
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
            extendBody: false, // Changed from true to false for solid navbar
            body: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: _currentIndex == 1 ? Colors.black : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: _currentIndex == 1
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.15),
                    width: 1.0,
                  ),
                ),
                boxShadow: _currentIndex == 1
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
              ),
              child: BottomAppBar(
                color: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                padding: EdgeInsets.zero,
                height: 68,
                elevation: 0,
                child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      0,
                      'assets/icons/Search vector.svg',
                      26,
                      26,
                      activeColor,
                      inactiveColor,
                      0,
                    ),
                    _buildNavItem(
                      1,
                      'assets/icons/Vector reel.svg',
                      24,
                      24,
                      activeColor,
                      inactiveColor,
                      0,
                    ),
                    _buildNavItem(
                      -1,
                      'assets/icons/Vector list go.svg',
                      38,
                      24,
                      activeColor,
                      inactiveColor,
                      0,
                      onTap: () async {
                        final user =
                            Supabase.instance.client.auth.currentUser;
                        if (user == null) {
                          AuthGuard.showLoginPrompt(
                            context,
                            title: 'List Property',
                            message: 'Log in to list and post properties on Khozna.',
                          );
                          return;
                        }

                        // Instant reaction if cached
                        if (_isKycVerified) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PostPropertyIntroScreen(),
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
                          freshStatus =
                              freshData?['kyc_status'] ?? 'not_started';
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
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
                                      child: Icon(
                                        Icons.hourglass_top_rounded,
                                        color: Colors.orange.shade700,
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Verification in Progress',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Your documents are being reviewed.\nVerification takes up to 48 hours.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.brandColor,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                        child: Text(
                                          'Got it',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
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
                              MaterialPageRoute(
                                builder: (context) => const KycScreen(),
                              ),
                            );
                          }
                        } else {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PostPropertyIntroScreen(),
                            ),
                          );

                          // If a property was successfully published, refresh the home screen
                          if (result == true) {
                            _homeKey.currentState?.refreshData();
                            setState(
                              () => _currentIndex = 0,
                            ); // Ensure we are on Home tab
                          }
                        }
                      },
                    ),
                    _buildNavItem(
                      2,
                      'assets/icons/Message neww.svg',
                      24,
                      24,
                      activeColor,
                      inactiveColor,
                      mBadge,
                    ),
                    _buildNavItem(
                      3,
                      'assets/icons/Vector profile.svg',
                      24,
                      24,
                      activeColor,
                      inactiveColor,
                      0,
                    ),
                  ],
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
    String iconPath,
    double width,
    double height,
    Color activeColor,
    Color inactiveColor,
    int badgeCount, {
    VoidCallback? onTap,
  }) {
    final bool isSelected = _currentIndex == index;

    String label = '';
    if (index == 0) {
      label = 'Khozna';
    } else if (index == 1) {
      label = 'Reels';
    } else if (index == -1) {
      label = 'List';
    } else if (index == 2) {
      label = 'Message';
    } else if (index == 3) {
      label = 'Profile';
    }

    return Expanded(
      child: InkWell(
        onTap: onTap ?? () => _onTabTapped(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top indicator line (LinkedIn-style)
            Center(
              child: Transform.translate(
                offset: const Offset(0.0, 0.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  height: 2.5,
                  width: isSelected && index != -1 ? 40 : 0,
                  decoration: BoxDecoration(
                    color: isSelected && index != -1
                        ? activeColor
                        : Colors.transparent,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: Offset(0, index == -1 ? -6 : 0),
                  child: Center(
                    child: SizedBox(
                      width: index == -1 ? 48 : width,
                      height: 26, // Constant height for all items to align labels
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          OverflowBox(
                            minWidth: 0,
                            maxWidth: index == -1 ? 48 : width,
                            minHeight: 0,
                            maxHeight: index == -1 ? 31 : height,
                            child: SvgPicture.asset(
                              iconPath,
                              width: index == -1 ? 48 : width,
                              height: index == -1 ? 31 : height,
                              colorFilter: index == -1
                                  ? null
                                  : ColorFilter.mode(
                                      isSelected ? activeColor : inactiveColor,
                                      BlendMode.srcIn,
                                    ),
                            ),
                          ),
                          // Premium red badge
                          if (badgeCount > 0)
                            Positioned(
                              top: -2,
                              right: -6,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF0000),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    badgeCount > 99 ? '99+' : '$badgeCount',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 9,
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
                  ),
                ),
                const SizedBox(height: 1.5),
                Center(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: isSelected ? activeColor : inactiveColor,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
