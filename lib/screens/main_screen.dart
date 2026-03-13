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
    // Magic: Listen for property bookings in real-time
    SupabaseService.listenToBookingNotifications();
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'प्रोपर्टी राख्नुहोस् (Post Property)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionItem(
              context,
              Icons.home_work_outlined,
              'कोठा वा घर थप्नुहोस्',
              'List your Room, House or Land',
              onTap: () {
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
            ),
            _buildOptionItem(
              context,
              Icons.videocam_outlined,
              'भिडियो राख्नुहोस्',
              'Share a Video Tour',
            ),
            _buildOptionItem(
              context,
              Icons.edit_note_outlined,
              'आफ्नो आवश्यकता लेख्नुहोस्',
              'Post what you are looking for',
            ),
            const SizedBox(height: 24),
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
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF3B30).withValues(alpha: 0.45),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
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
