import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'saved_properties_screen.dart';
import 'notifications_screen.dart';
import 'my_listings_screen.dart';
import 'safety_center_screen.dart';
import 'kyc_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  final bool isVerified;
  const ProfileScreen({super.key, this.isVerified = true});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTextColor,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          ),
                          child: const Icon(
                            Icons.notifications_none,
                            color: Colors.black,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          ),
                          child: const Icon(
                            Icons.settings_outlined,
                            color: Colors.black,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'John Doe',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryTextColor,
              ),
            ),
            Text(
              'johndoe@example.com',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500]),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isVerified
                      ? Colors.green.withValues(alpha: 0.05)
                      : Colors.orange.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isVerified
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isVerified ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isVerified ? Icons.verified_user : Icons.gpp_maybe,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isVerified
                                ? 'Verified Profile'
                                : 'Complete Verification',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isVerified
                                  ? Colors.green[800]
                                  : Colors.orange[800],
                            ),
                          ),
                          Text(
                            isVerified
                                ? 'Your identity is fully verified.'
                                : 'Verify your ID to build trust.',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: isVerified
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isVerified)
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const KycScreen(),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('ACCOUNT'),
                  _buildProfileMenuItem(
                    context,
                    Icons.person_outline,
                    'Edit Profile',
                    AppTheme.brandColor,
                    onTap: () {},
                  ),
                  _buildProfileMenuItem(
                    context,
                    Icons.favorite_border,
                    'Saved Properties',
                    AppTheme.brandColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavedPropertiesScreen(),
                        ),
                      );
                    },
                  ),
                  _buildProfileMenuItem(
                    context,
                    Icons.home_work_outlined,
                    'My Listings',
                    AppTheme.brandColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyListingsScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  _buildSectionLabel('LEGAL & SAFETY'),
                  _buildProfileMenuItem(
                    context,
                    Icons.security_outlined,
                    'Safety Center (सुरक्षा केन्द्र)',
                    Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SafetyCenterScreen(),
                        ),
                      );
                    },
                  ),
                  _buildProfileMenuItem(
                    context,
                    Icons.description_outlined,
                    'Terms of Service',
                    Colors.grey[700]!,
                    onTap: () {},
                  ),
                  _buildProfileMenuItem(
                    context,
                    Icons.privacy_tip_outlined,
                    'Privacy Policy',
                    Colors.grey[700]!,
                    onTap: () {},
                  ),

                  const SizedBox(height: 24),
                  _buildSectionLabel('SUPPORT'),
                  _buildProfileMenuItem(
                    context,
                    Icons.help_outline,
                    'Help Center',
                    AppTheme.brandColor,
                    onTap: () {},
                  ),
                  _buildProfileMenuItem(
                    context,
                    Icons.logout,
                    'Log Out',
                    Colors.red,
                    showArrow: false,
                    onTap: () {},
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    Color color, {
    bool showArrow = true,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
              ),
              if (showArrow)
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[300],
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
