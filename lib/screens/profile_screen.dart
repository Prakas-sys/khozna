 import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'saved_properties_screen.dart';
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
    return Scaffold(
      backgroundColor: Colors.grey[50], // Slightly off-white for a cleaner feel
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.brandColor,
                      AppTheme.brandColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative bubbles
                    Positioned(
                      top: -20,
                      right: -30,
                      child: CircleAvatar(radius: 60, backgroundColor: Colors.white12),
                    ),
                     Positioned(
                      bottom: 40,
                      left: -20,
                      child: CircleAvatar(radius: 40, backgroundColor: Colors.white10),
                    ),
                    SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 48,
                                    backgroundColor: Colors.grey[100],
                                    child: _imageFile != null
                                        ? ClipOval(child: Image.file(_imageFile!, width: 96, height: 96, fit: BoxFit.cover))
                                        : Icon(Icons.person_rounded, size: 48, color: Colors.grey[400]),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.add_a_photo_outlined,
                                        color: AppTheme.brandColor,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user?.displayName ?? 'Khozna Guest',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _isOwner ? '⚡ Property Owner' : '🏠 Active Tenant',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                   // Verification Card
                  _buildVerificationCard(),
                  const SizedBox(height: 24),
                  
                  // Menu Items in Sections
                  _buildMenuSection('OVERVIEW', [
                    _buildMenuItem(Icons.person_outline, 'Edit Profile', 'Update your personal info', onTap: () {}),
                    _buildMenuItem(Icons.bookmark_outline, 'Saved Properties', 'Properties you liked', onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPropertiesScreen()));
                    }),
                    _buildMenuItem(Icons.list_alt_rounded, 'My Listings', 'Properties you posted', onTap: () {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsScreen()));
                    }),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  _buildMenuSection('LEGAL & HELP', [
                    _buildMenuItem(Icons.privacy_tip_outlined, 'Safety Center', 'Protect your account', 
                      color: Colors.redAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyCenterScreen()))),
                    _buildMenuItem(Icons.help_center_outlined, 'Help Center', 'FAQs & Contact Support', onTap: () {}),
                    _buildMenuItem(Icons.description_outlined, 'Terms & Privacy', 'Our guidelines', onTap: () {}),
                  ]),
                  
                  const SizedBox(height: 32),
                  
                  // Log Out Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () async {
                        await firebase_auth.FirebaseAuth.instance.signOut();
                        if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                      },
                      icon: const Icon(Icons.logout_rounded, color: Colors.red),
                      label: Text('Log Out From Account', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: Colors.red.withOpacity(0.05),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: widget.isVerified 
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.orange.shade400, Colors.red.shade600],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (widget.isVerified ? Colors.green : Colors.red).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isVerified ? Icons.verified_rounded : Icons.gpp_maybe_rounded,
                color: widget.isVerified ? Colors.green : Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isVerified ? 'Profile Verified (प्रोफाइल प्रमाणित)' : 'Incomplete KYC (केवाइसी बाँकी)',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    widget.isVerified 
                        ? 'Your identity is fully confirmed.' 
                        : 'Verify now to gain more trust (प्रमाणित गर्नुहोस्)',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (!widget.isVerified)
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KycScreen())),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.grey[400],
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, {VoidCallback? onTap, Color? color}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.brandColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color ?? AppTheme.brandColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E1E1E), letterSpacing: -0.3),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500], letterSpacing: -0.2),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
    );
  }
}
