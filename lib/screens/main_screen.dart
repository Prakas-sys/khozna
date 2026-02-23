import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'reels_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'add_property_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

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
          height: 58, // Reduced from 65
          elevation:
              0, // Removing default elevation now that we have a crisp border
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                0,
                'Khozna',
                'assets/icons/explore.svg',
                activeColor,
                inactiveColor,
              ),
              _buildNavItem(
                1,
                'Reels',
                'assets/icons/reels.svg',
                activeColor,
                inactiveColor,
              ),
              // The central add button directly inside the row
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
                        offset: const Offset(
                          0,
                          -4, // Adjusted from -6 for shorter bar
                        ), // Shifting slightly up to align with adjacent SVGs
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
                            weight: 700, // Sharper, bolder for better contrast
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildNavItem(
                2,
                'Message',
                'assets/icons/message.svg',
                activeColor,
                inactiveColor,
              ),
              _buildNavItem(
                3,
                'Profile',
                'assets/icons/profile.svg',
                activeColor,
                inactiveColor,
              ),
            ],
          ),
        ),
      ),
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
              style: GoogleFonts.outfit(
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPropertyScreen(),
                  ),
                );
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
            const SizedBox(height: 32),
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
          color: AppTheme.brandColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.brandColor, size: 24),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
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
  ) {
    final bool isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.06 : 1.0, // Tiny bit more scale
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                width: 25, // Increased from 24
                height: 25,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Base icon
                    SvgPicture.asset(
                      iconPath,
                      width: 25,
                      height: 25,
                      colorFilter: ColorFilter.mode(
                        isSelected ? activeColor : inactiveColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    // If selected, add uniform offset versions for a clean bold effect
                    if (isSelected) ...[
                      _buildOffsetIcon(iconPath, 0.2, 0, activeColor),
                      _buildOffsetIcon(iconPath, -0.2, 0, activeColor),
                      _buildOffsetIcon(iconPath, 0, 0.2, activeColor),
                      _buildOffsetIcon(iconPath, 0, -0.2, activeColor),
                    ],
                  ],
                ),
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
        colorFilter: ColorFilter.mode(
          color,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
