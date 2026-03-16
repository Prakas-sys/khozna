import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/app_notifiers.dart';
import '../utils/supabase_service.dart';
import 'home_screen.dart';
import 'reels_screen.dart';
import 'messages_screen.dart';
import 'add_property_screen.dart';
import 'kyc_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isKycVerified = false; // Mock KYC status

  final List<Widget> _pages = [
    const HomeScreen(),
    const ReelsScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Magic: Listen for all user notifications in real-time
    SupabaseService.listenToUserNotifications();
  }

  void _onTabTapped(int index) {
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

    return ValueListenableBuilder<int>(
      valueListenable: messageBadgeCount,
      builder: (context, badgeCount, _) {
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
          body: _pages[_currentIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1.0),
              ),
            ),
            child: BottomAppBar(
              color: Colors.white,
              surfaceTintColor: Colors.white,
              padding: EdgeInsets.zero,
              height: 58,
              elevation: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, 'Khozna', 'assets/icons/explore.svg', activeColor, inactiveColor, 0),
                  _buildNavItem(1, 'Reels', 'assets/icons/reels.svg', activeColor, inactiveColor, 0),
                  // Central add button
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        // Guest users can now see posting options
                        _showAddPropertyOptions(context);
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
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.brandColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 22, weight: 700),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                  _buildNavItem(2, 'Message', 'assets/icons/message.svg', activeColor, inactiveColor, badgeCount),
                  _buildNavItem(3, 'Profile', 'assets/icons/profile.svg', activeColor, inactiveColor, 0),
                ],
              ),
            ),
          ),
        ),);
      },
    );
  }

  void _showAddPropertyOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 20,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
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
            const SizedBox(height: 28),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_home_rounded, color: AppTheme.brandColor, size: 30),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'आफ्नो सम्पत्ति राख्नुहोस्',
              style: GoogleFonts.mukta(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quick and easy way to list your\nRoom, Flat, House or Hostel.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (!_isKycVerified) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const KycScreen()),
                    ).then((value) {
                      if (value == true) {
                        setState(() => _isKycVerified = true);
                      }
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddPropertyScreen(),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  'Post Now',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap ?? () => Navigator.pop(context),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.brandColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.brandColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF717171)),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Color(0xFF717171),
      ),
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
              height: 3.2,
              width: isSelected ? 48 : 0,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.brandColor : Colors.transparent,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
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
                  // Icon
                  AnimatedScale(
                    scale: isSelected ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isSelected) ...[
                          // Pseudo-stroke to make the icon bolder when active
                          Transform.translate(offset: const Offset(0.5, 0), child: SvgPicture.asset(iconPath, width: 24, height: 24, colorFilter: ColorFilter.mode(activeColor, BlendMode.srcIn))),
                          Transform.translate(offset: const Offset(-0.5, 0), child: SvgPicture.asset(iconPath, width: 24, height: 24, colorFilter: ColorFilter.mode(activeColor, BlendMode.srcIn))),
                          Transform.translate(offset: const Offset(0, 0.5), child: SvgPicture.asset(iconPath, width: 24, height: 24, colorFilter: ColorFilter.mode(activeColor, BlendMode.srcIn))),
                          Transform.translate(offset: const Offset(0, -0.5), child: SvgPicture.asset(iconPath, width: 24, height: 24, colorFilter: ColorFilter.mode(activeColor, BlendMode.srcIn))),
                        ],
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
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0000), // Pure vibrant red
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 1.5), // Pure white border for contrast
                        ),
                        child: Center(
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: GoogleFonts.outfit(
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
                style: GoogleFonts.outfit(
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
