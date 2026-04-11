 import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import 'saved_properties_screen.dart';
import 'my_listings_screen.dart';
import 'safety_center_screen.dart';
import 'kyc_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'add_property_screen.dart';
import '../utils/cloudinary_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool isVerified;
  const ProfileScreen({super.key, this.isVerified = false}); // Default to false for testing

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = Supabase.instance.client.auth.currentUser;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isOwner = false;
  String? _avatarUrl;
  bool _isUploading = false;
  String _kycStatus = 'not_started';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkOwnerStatus();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (user != null) {
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('avatar_url, kyc_status, is_owner')
            .eq('id', user!.id)
            .maybeSingle();
        
        if (mounted && profile != null) {
          setState(() {
            _avatarUrl = profile['avatar_url'];
            _kycStatus = profile['kyc_status'] ?? 'not_started';
            _isOwner = profile['is_owner'] ?? false;
          });
        }
      } catch (e) {
        debugPrint('Error loading profile: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkOwnerStatus() async {
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('properties')
            .select('id')
            .eq('owner_id', user!.id)
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
        _isUploading = true;
      });
      try {
        final imageUrl = await CloudinaryService.uploadImage(_imageFile!);
        if (imageUrl != null && user != null) {
          await Supabase.instance.client.from('profiles').update({'avatar_url': imageUrl}).eq('id', user!.id);
          if (mounted) {
            setState(() => _avatarUrl = imageUrl);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated!')));
          }
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update photo: $e')));
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
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
                      child: const CircleAvatar(radius: 60, backgroundColor: Colors.white12),
                    ),
                     Positioned(
                      bottom: 40,
                      left: -20,
                      child: const CircleAvatar(radius: 40, backgroundColor: Colors.white10),
                    ),
                    SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.2)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircleAvatar(
                                      radius: 54,
                                      backgroundColor: Colors.grey[50],
                                      child: _isUploading
                                          ? const CircularProgressIndicator(color: AppTheme.brandColor, strokeWidth: 2)
                                          : _imageFile != null
                                              ? ClipOval(child: Image.file(_imageFile!, width: 108, height: 108, fit: BoxFit.cover))
                                              : _avatarUrl != null
                                                  ? ClipOval(child: Image.network(_avatarUrl!, width: 108, height: 108, fit: BoxFit.cover))
                                                  : Container(
                                                      width: 108,
                                                      height: 108,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        gradient: LinearGradient(
                                                          colors: [Colors.grey[200]!, Colors.grey[100]!],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        ),
                                                      ),
                                                      child: Icon(Icons.person_rounded, size: 54, color: Colors.grey[400]),
                                                    ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: AppTheme.brandColor,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'] ?? (_isOwner ? 'Owner' : 'Guest'),
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (_kycStatus == 'verified') ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified_rounded, 
                                    color: Color(0xFF1D9BF0), // Twitter/Verified Blue
                                    size: 16,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (_isOwner) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                  const SizedBox(width: 5),
                                  Text(
                                    'PREMIUM OWNER',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                   // Verification Card (Only if not verified and not loading)
                  if (!_isLoading && _kycStatus != 'verified') ...[
                    _buildVerificationCard(),
                    const SizedBox(height: 20),
                  ],

                  // Post Property Call (Airbnb Style)
                  if (!_isLoading && _kycStatus == 'verified') ...[
                    _buildPostPropertyCard(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Menu Items in Sections
                  _buildMenuSection('OVERVIEW', [
                    _buildMenuItem(Icons.list_alt_rounded, 'My Listings', 'Properties you posted', onTap: () {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsScreen()));
                    }),
                    _buildMenuItem(Icons.person_outline, 'Edit Profile', 'Update your personal info', onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      ).then((value) {
                        if (value == true) _loadProfile();
                      });
                    }),
                    _buildMenuItem(Icons.bookmark_outline, 'Saved Properties', 'Properties you liked', onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPropertiesScreen()));
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
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Text('Log Out', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                            content: Text('Are you sure you want to log out of Khozna?', style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 14)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context); // Close dialog
                                  await Supabase.instance.client.auth.signOut();
                                  if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  minimumSize: const Size(0, 36),
                                ),
                                child: Text('Log Out', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout_rounded, color: Colors.red),
                      label: Text('Log Out From Account', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final bool isVerified = _kycStatus == 'verified';
    final bool isPending = _kycStatus == 'pending';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isVerified ? Colors.green : Colors.orange).withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: (isVerified ? Colors.green : Colors.orange).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isVerified 
                    ? [Colors.green.shade50, Colors.green.shade100]
                    : [Colors.orange.shade50, Colors.orange.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVerified ? Icons.verified_user_rounded : (isPending ? Icons.hourglass_empty_rounded : Icons.gpp_maybe_rounded),
              color: isVerified ? Colors.green.shade700 : Colors.orange.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified ? 'Profile Verified' : (isPending ? 'Verification Pending' : 'Incomplete KYC'),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  isVerified ? 'Your identity is fully confirmed.' : 'Get verified to start posting properties.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!isVerified && !isPending)
            InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KycScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.brandColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.brandColor.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Verify',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostPropertyCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1E1E),
            const Color(0xFF2D2D2D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background pattern
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.home_work_rounded, size: 120, color: Colors.white.withValues(alpha: 0.05)),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_business_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready to Earn?',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Become a Khozna Owner',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'List your room, flat, or house and connect with verified guests in minutes.',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Post Your Property',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[400],
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(children: items),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, {VoidCallback? onTap, Color? color}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.brandColor).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? AppTheme.brandColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15, 
          fontWeight: FontWeight.bold, 
          color: const Color(0xFF1E1E1E), 
          letterSpacing: -0.3
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12, 
          color: Colors.grey[500], 
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
      ),
    );
  }
}
