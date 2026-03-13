import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'saved_properties_screen.dart';
import 'notifications_screen.dart';
import 'my_listings_screen.dart';
import 'safety_center_screen.dart';
import 'kyc_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isVerified;
  const ProfileScreen({super.key, this.isVerified = false}); // Default to false for testing

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _checkOwnerStatus();
  }

  Future<void> _checkOwnerStatus() async {
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('properties')
            .select('id')
            .eq('owner_id', user!.uid)
            .limit(1);
        
        if (mounted && response != null && (response as List).isNotEmpty) {
          setState(() {
            _isOwner = true;
          });
        }
      } catch (e) {
        debugPrint('Error checking owner status: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // ... (keep the same header code)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile',
                    style: GoogleFonts.outfit(
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

            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  child: _imageFile != null
                      ? ClipOval(child: Image.file(_imageFile!, width: 100, height: 100, fit: BoxFit.cover))
                      : Icon(Icons.person, size: 50, color: Colors.grey[400]),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.brandColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              user?.displayName ?? 'Guest',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryTextColor,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: _isOwner 
                        ? AppTheme.brandColor.withValues(alpha: 0.1) 
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isOwner ? 'Owner' : 'Guest',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _isOwner ? AppTheme.brandColor : Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  user?.phoneNumber ?? 'No Phone Linked',
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // VERIFICATION BADGE - UPDATED TO RED
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // More compact padding
                decoration: BoxDecoration(
                  color: widget.isVerified
                      ? Colors.green.withValues(alpha: 0.05)
                      : Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24), // Smoother rounded corners
                  border: Border.all(
                    color: widget.isVerified
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.red.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6), // Compact icon padding
                      decoration: BoxDecoration(
                        color: widget.isVerified ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isVerified ? Icons.verified_user : Icons.gpp_bad_rounded,
                        color: Colors.white,
                        size: 18, // Smaller icon
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: widget.isVerified ? 'Verified Profile ' : 'Not Verified ',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: widget.isVerified ? Colors.green[800] : Colors.red[800],
                                  ),
                                ),
                                TextSpan(
                                  text: widget.isVerified ? '(प्रमाणित)' : '(अप्रमाणित)',
                                  style: GoogleFonts.mukta(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: widget.isVerified ? Colors.green[800] : Colors.red[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            widget.isVerified
                                ? 'Your identity is fully verified.'
                                : 'ID verification is required.',
                            style: GoogleFonts.outfit(
                              fontSize: 11, // Smaller subtitle
                              color: widget.isVerified
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!widget.isVerified)
                      SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const KycScreen(),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Verify Now',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildSectionLabel('Account'),
                  _buildProfileMenuItem(
                    context,
                    Icons.person_pin_outlined,
                    'Edit Profile',
                    AppTheme.brandColor,
                    onTap: () {},
                  ),
                  _buildProfileMenuItem(
                    context,
                    Icons.bookmark_outline_rounded,
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
                    Icons.holiday_village_outlined,
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

                  const SizedBox(height: 16),
                   _buildSectionLabel('Legal & Safety'),
                  _buildProfileMenuItem(
                    context,
                    Icons.balance_outlined,
                    'Legal Information',
                    Colors.grey[700]!,
                    onTap: () {
                      // Show sub-folder/bottom sheet with legal links
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Legal & Safety',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildProfileMenuItem(
                                context,
                                Icons.security_outlined,
                                'Safety Center (सुरक्षा केन्द्र)',
                                Colors.red,
                                onTap: () {
                                  Navigator.pop(context);
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
                                onTap: () {
                                  Navigator.pop(context);
                                },
                              ),
                              _buildProfileMenuItem(
                                context,
                                Icons.privacy_tip_outlined,
                                'Privacy Policy',
                                Colors.grey[700]!,
                                onTap: () {
                                  Navigator.pop(context);
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                   _buildSectionLabel('Support'),
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
                    onTap: () async {
                      await firebase_auth.FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
           color: Colors.grey[600],
           letterSpacing: 0.5,
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
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
