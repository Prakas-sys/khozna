import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/app_notifiers.dart';
import 'home_screen.dart';
import 'reels_screen.dart';
import 'messages_screen.dart';
import 'add_property_screen.dart';
import 'kyc_screen.dart';
import 'profile_screen.dart';

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
  Widget build(BuildContext context) {
    const Color activeColor = AppTheme.brandColor;
    const Color inactiveColor = Color(0xFF717171);

    return ValueListenableBuilder<int>(
      valueListenable: messageBadgeCount,
      builder: (context, badgeCount, _) {
        return Scaffold(
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
                      onTap: () => _showAddPropertyOptions(context),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
        );
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
        onTap: () {
          setState(() => _currentIndex = index);
          if (index == 2) messageBadgeCount.value = 0;
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Outer container for icon + badge
            SizedBox(
              width: 36,
              height: 30,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Icon (with bold-effect when selected)
                  AnimatedScale(
                    scale: isSelected ? 1.06 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SvgPicture.asset(
                          iconPath,
                          width: 25,
                          height: 25,
                          colorFilter: ColorFilter.mode(
                            isSelected ? activeColor : inactiveColor,
                            BlendMode.srcIn,
                          ),
                        ),
                        if (isSelected) ...[
                          _buildOffsetIcon(iconPath, 0.2, 0, activeColor),
                          _buildOffsetIcon(iconPath, -0.2, 0, activeColor),
                          _buildOffsetIcon(iconPath, 0, 0.2, activeColor),
                          _buildOffsetIcon(iconPath, 0, -0.2, activeColor),
                        ],
                      ],
                    ),
                  ),
                  // Premium red badge (top-right, floating outside)
                  if (badgeCount > 0)
                    Positioned(
                      top: -2,
                      right: 0,
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
            const SizedBox(height: 1),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffsetIcon(String path, double dx, double dy, Color color) {
    return Positioned(
      left: dx,
      top: dy,
      child: SvgPicture.asset(
        path,
        width: 25,
        height: 25,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}
