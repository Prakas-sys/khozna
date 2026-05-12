import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/property/screens/saved_properties_screen.dart';
import 'package:khozna/features/property/screens/my_listings_screen.dart';
import 'package:khozna/features/profile/screens/safety_center_screen.dart';
import 'package:khozna/features/profile/screens/help_center_screen.dart';
import 'package:khozna/features/profile/screens/terms_privacy_screen.dart';
import 'package:khozna/features/profile/screens/kyc_screen.dart';
import 'package:khozna/features/profile/screens/settings_screen.dart';
import 'package:khozna/features/auth/screens/login_screen.dart';
import 'package:khozna/features/profile/screens/edit_profile_screen.dart';
import 'package:khozna/features/property/screens/add_property_screen.dart';
import 'package:khozna/features/property/screens/booking_status_screen.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/core/utils/offline_storage.dart';
import 'package:khozna/core/services/cloudinary_service.dart';
import 'package:khozna/core/guards/auth_guard.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/features/profile/widgets/profile_widgets.dart';
import 'package:khozna/features/property/screens/owner_bookings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isVerified;
  const ProfileScreen({super.key, this.isVerified = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final User? user = Supabase.instance.client.auth.currentUser;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isOwner = false;
  String? _avatarUrl;
  bool _isUploading = false;
  String _kycStatus = 'not_started';
  bool _isLoading = true;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
    _checkOwnerStatus();

    if (profileCache.value != null) {
      final cache = profileCache.value!;
      _avatarUrl = cache['avatar_url'];
      _kycStatus = cache['kyc_status'] ?? 'not_started';
      _isOwner = cache['is_owner'] ?? false;
      _isLoading = false;
    }

    _loadFromDiskCache();
    _loadProfile();
  }

  Future<void> _loadFromDiskCache() async {
    final diskCache = await OfflineStorage.loadProfileCache();
    if (diskCache != null && mounted) {
      setState(() {
        _avatarUrl ??= diskCache['avatar_url'];
        if (_kycStatus == 'not_started') {
          _kycStatus = diskCache['kyc_status'] ?? 'not_started';
        }
        _isOwner = _isOwner || (diskCache['is_owner'] ?? false);
        _isLoading = false;
        profileCache.value ??= diskCache;
      });
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
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
            _isOwner = _isOwner || (profile['is_owner'] ?? false);

            final cacheData = {
              'avatar_url': _avatarUrl,
              'kyc_status': _kycStatus,
              'is_owner': _isOwner,
            };
            profileCache.value = cacheData;
            OfflineStorage.saveProfileCache(cacheData);
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

        if (mounted && (response as List).isNotEmpty) {
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
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _isUploading = true;
      });
      try {
        final imageUrl = await CloudinaryService.uploadImage(_imageFile!);
        if (imageUrl != null && user != null) {
          await Supabase.instance.client
              .from('profiles')
              .update({'avatar_url': imageUrl})
              .eq('id', user!.id);

          await Supabase.instance.client.auth.updateUser(
            UserAttributes(data: {'avatar_url': imageUrl}),
          );

          if (mounted) {
            setState(() => _avatarUrl = imageUrl);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile photo updated!')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to update photo: $e')));
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: ProfileHeader(
                fullName:
                    user?.userMetadata?['full_name'] ??
                    user?.userMetadata?['name'],
                avatarUrl: _avatarUrl,
                kycStatus: _kycStatus,
                isOwner: _isOwner,
                isUploading: _isUploading,
                onPickImage: _pickImage,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Column(
                children: [
                  if (!_isLoading && _kycStatus != 'verified') ...[
                    VerificationCard(
                      kycStatus: _kycStatus,
                      onTap: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const KycScreen()),
                        );
                        if (res == true) _loadProfile();
                      },
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (!_isLoading && _kycStatus == 'verified') ...[
                    PostPropertyCard(
                      shimmerAnimation: _shimmerAnimation,
                      onPost: () async {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddPropertyScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],

                  ProfileMenuSection(
                    title: 'OVERVIEW',
                    items: [
                      ProfileMenuItem(
                        icon: Icons.list_alt_rounded,
                        title: 'My Listings',
                        subtitle: 'Properties you posted',
                        onTap: () {
                          if (!AuthGuard.checkAuth(context)) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyListingsScreen(),
                            ),
                          );
                        },
                      ),
                      ProfileMenuItem(
                        icon: Icons.person_outline,
                        title: 'Edit Profi\u200cle',
                        subtitle: 'Update your personal info',
                        onTap: () {
                          if (!AuthGuard.checkAuth(context)) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          ).then((value) {
                            if (value == true) _loadProfile();
                          });
                        },
                      ),
                      ProfileMenuItem(
                        icon: Icons.bookmark_outline,
                        title: 'Saved Properties',
                        subtitle: 'Properties you liked',
                        onTap: () {
                          if (!AuthGuard.checkAuth(context)) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SavedPropertiesScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ProfileMenuSection(
                    title: 'LEGAL & HELP',
                    items: [
                      ProfileMenuItem(
                        icon: Icons.help_center_outlined,
                        title: 'Help Center',
                        subtitle: 'FAQs & Contact Support',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HelpCenterScreen(),
                          ),
                        ),
                      ),
                      ProfileMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Safety Center',
                        subtitle: 'Protect your account',
                        color: Colors.redAccent,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SafetyCenterScreen(),
                          ),
                        ),
                      ),
                      ProfileMenuItem(
                        icon: Icons.description_outlined,
                        title: 'Terms & Privacy',
                        subtitle: 'Our guidelines',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TermsPrivacyScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ProfileMenuSection(
                    title: 'ACCOUNTS',
                    items: [
                      ProfileMenuItem(
                        icon: Icons.switch_account_outlined,
                        title: 'Switch Account',
                        subtitle: 'Manage multiple accounts',
                        onTap: () => _showAccountSwitcher(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout_rounded, color: Colors.red),
                      label: Text(
                        'Log Out From Account',
                        style: GoogleFonts.inter(
                          color: Colors.red,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.red.withOpacity(0.05),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text(
          'Log Out',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              profileCache.value = null;
              await OfflineStorage.clearProfileCache();
              await OfflineStorage.clearHomeCache();
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Log Out',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Switch Account',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.brandColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.brandColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: _avatarUrl != null
                        ? CachedNetworkImageProvider(_avatarUrl!)
                        : null,
                    child: _avatarUrl == null ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.userMetadata?['full_name'] ?? 'Current User',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: AppTheme.brandColor),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              onTap: () async {
                Navigator.pop(context);
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.black),
              ),
              title: Text(
                'Add Account',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                'Log in with email and password',
                style: GoogleFonts.inter(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
