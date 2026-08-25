import 'package:khozna/widgets/khozna_image.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/services/cloudinary_service.dart';
import 'package:khozna/core/security/security_utils.dart';
import 'package:khozna/features/profile/screens/kyc_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final User? user = Supabase.instance.client.auth.currentUser;
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _esewaController = TextEditingController();
  final _khaltiController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _areaController = TextEditingController();
  final _userTypeController = TextEditingController();
  final _bioController = TextEditingController();
  final _orgController = TextEditingController();

  // Focus nodes for interactive "Design Box" borders
  final Map<String, FocusNode> _focusNodes = {
    'name': FocusNode(),
    'phone': FocusNode(),
    'area': FocusNode(),
    'role': FocusNode(),
    'org': FocusNode(),
    'bio': FocusNode(),
    'esewa': FocusNode(),
    'khalti': FocusNode(),
    'acc': FocusNode(),
  };

  bool _isLoading = false;
  bool _isLocating = false;
  String? _avatarUrl;
  String? _qrCodeUrl;
  String? _studentIdUrl;
  File? _imageFile;
  File? _qrFile;
  File? _idFile;
  final ImagePicker _picker = ImagePicker();

  double? _latitude;
  double? _longitude;
  String _kycStatus = 'not_verified';

  // 🎨 COLOR PALETTE (60-30-10 Rule)
  static const Color colorPrimary = Colors.white; // 60%
  static const Color colorSecondary = Color(0xFFF7F7F7); // 30%
  static const Color colorAccent = AppTheme.brandColor; // 10%
  static const Color colorTextPrimary = Color(0xFF222222);
  static const Color colorTextSecondary = Color(0xFF717171);

  @override
  void initState() {
    super.initState();
    SecurityUtils.setSecure(true);
    _loadUserData();
  }

  @override
  void dispose() {
    SecurityUtils.setSecure(false);
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _esewaController.dispose();
    _khaltiController.dispose();
    _accountNameController.dispose();
    _areaController.dispose();
    _userTypeController.dispose();
    _bioController.dispose();
    _orgController.dispose();
    _focusNodes.forEach((key, node) => node.dispose());
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      setState(() => _isLoading = true);
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('*')
            .eq('id', user!.id)
            .maybeSingle();

        final kyc = await Supabase.instance.client
            .from('kyc_verifications')
            .select('latitude, longitude, status')
            .eq('user_id', user!.id)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (mounted) {
          final String profStatus = (profile?['kyc_status'] ?? '').toString();
          final bool isProfileVerified =
              profStatus == 'verified' ||
              profStatus == 'approved' ||
              (profile?['is_verified'] as bool? ?? false);

          setState(() {
            _fullNameController.text = profile?['full_name'] ?? '';
            _emailController.text = profile?['email'] ?? user?.email ?? '';
            _phoneController.text = profile?['phone_number'] ?? '';
            _avatarUrl = AppTheme.sanitizeAvatarUrl(
              profile?['avatar_url'] ??
                  user?.userMetadata?['avatar_url'] ??
                  user?.userMetadata?['picture'],
            );
            _esewaController.text = profile?['esewa_number'] ?? '';
            _khaltiController.text = profile?['khalti_number'] ?? '';
            _accountNameController.text = profile?['account_holder_name'] ?? '';
            _qrCodeUrl = profile?['qr_code_url'];
            _areaController.text = profile?['area_name'] ?? '';
            _userTypeController.text = profile?['user_type'] ?? '';
            _bioController.text = profile?['bio'] ?? '';
            _orgController.text = profile?['organization'] ?? '';
            _studentIdUrl = profile?['student_id_url'];

            if (kyc != null) {
              _latitude = (kyc['latitude'] as num?)?.toDouble();
              _longitude = (kyc['longitude'] as num?)?.toDouble();
              _kycStatus = (isProfileVerified || kyc['status'] == 'verified')
                  ? 'verified'
                  : (kyc['status'] ?? 'pending');
            } else if (isProfileVerified) {
              _kycStatus = 'verified';
            }
          });
        }
      } catch (e) {
        debugPrint('Error loading profile: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateLocation() async {
    if (user == null) return;
    setState(() => _isLocating = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Save ONLY location coordinates — do NOT touch kyc_status here.
      // Verification is done through the full KYC document flow only.
      try {
        final existingKyc = await Supabase.instance.client
            .from('kyc_verifications')
            .select('id')
            .eq('user_id', user!.id)
            .maybeSingle();

        if (existingKyc != null) {
          await Supabase.instance.client
              .from('kyc_verifications')
              .update({
                'latitude': position.latitude,
                'longitude': position.longitude,
              })
              .eq('user_id', user!.id);
        } else {
          await Supabase.instance.client.from('kyc_verifications').insert({
            'user_id': user!.id,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'status': 'pending',
          });
        }
      } catch (kycErr) {
        debugPrint('Location save warning: $kycErr');
      }

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          // Do NOT change _kycStatus here — only KYC document review can verify
        });

        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Location saved!',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.brandColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location update failed: $e',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _imageFile = File(image.path));
  }

  Future<void> _pickQrCode() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _qrFile = File(image.path));
  }

  Future<void> _pickStudentId() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _idFile = File(image.path));
  }

  Future<void> _updateProfile() async {
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      String? avatar = _avatarUrl;
      String? qr = _qrCodeUrl;
      String? idCard = _studentIdUrl;

      if (_imageFile != null)
        avatar = await CloudinaryService.uploadImage(_imageFile!);
      if (_qrFile != null) qr = await CloudinaryService.uploadImage(_qrFile!);
      if (_idFile != null)
        idCard = await CloudinaryService.uploadImage(_idFile!);

      await Supabase.instance.client
          .from('profiles')
          .update({
            'full_name': _fullNameController.text.trim(),
            'avatar_url': avatar,
            'phone_number': _phoneController.text.trim(),
            'esewa_number': _esewaController.text.trim(),
            'khalti_number': _khaltiController.text.trim(),
            'account_holder_name': _accountNameController.text.trim(),
            'qr_code_url': qr,
            'area_name': _areaController.text.trim(),
            'user_type': _userTypeController.text.trim(),
            'bio': _bioController.text.trim(),
            'organization': _orgController.text.trim(),
            'student_id_url': idCard,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user!.id);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Profile saved permanently!',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.brandColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Update error: $e');
      if (mounted) {
        String friendlyMsg = 'Failed to save profile. Please try again.';
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('profiles_phone_number_key') ||
            (errStr.contains('duplicate key') && errStr.contains('phone'))) {
          friendlyMsg = 'This phone number is already linked to another account. Please use a different number.';
        } else if (errStr.contains('duplicate key') || errStr.contains('unique constraint')) {
          friendlyMsg = 'One of your details is already in use by another account.';
        } else if (errStr.contains('socketexception') || errStr.contains('failed host lookup')) {
          friendlyMsg = 'Network error. Please check your internet connection.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    friendlyMsg,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFE11D48),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorPrimary,
      appBar: _buildAirbnbAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildProfilePhotoSection(),
                const SizedBox(height: 32),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildKycHeaderBanner(),
                      _buildAirbnbHeader('Public profile'),
                      const SizedBox(height: 24),
                      _buildAirbnbField(
                        'Full Name / पूरा नाम',
                        _fullNameController,
                        focusNode: _focusNodes['name'],
                      ),
                      _buildAirbnbField(
                        'Email Address',
                        _emailController,
                        enabled: false,
                      ),
                      _buildAirbnbField(
                        'Phone Number / फोन नम्बर',
                        _phoneController,
                        keyboardType: TextInputType.phone,
                        focusNode: _focusNodes['phone'],
                      ),

                      const SizedBox(height: 24),
                      _buildAirbnbHeader('Tell your story'),
                      const SizedBox(height: 24),
                      _buildAirbnbField(
                        'Role',
                        _userTypeController,
                        focusNode: _focusNodes['role'],
                      ),
                      _buildAirbnbField(
                        'Organization',
                        _orgController,
                        focusNode: _focusNodes['org'],
                      ),
                      _buildAirbnbField(
                        'Bio / आफ्नो बारेमा',
                        _bioController,
                        maxLines: 4,
                        focusNode: _focusNodes['bio'],
                      ),

                      const SizedBox(height: 24),
                      _buildLocationSection(),
                      const SizedBox(height: 32),

                      _buildAirbnbHeader('Payout options'),
                      const SizedBox(height: 24),
                      _buildAirbnbField(
                        'eSewa ID',
                        _esewaController,
                        focusNode: _focusNodes['esewa'],
                      ),
                      _buildAirbnbField(
                        'Khalti ID',
                        _khaltiController,
                        focusNode: _focusNodes['khalti'],
                      ),
                      _buildAirbnbField(
                        'Legal Name / कानूनी नाम',
                        _accountNameController,
                        focusNode: _focusNodes['acc'],
                      ),

                      const SizedBox(height: 16),
                      _buildPremiumMediaGrid(),

                      const SizedBox(height: 48),
                      _buildAirbnbSaveButton(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) _buildPremiumLoadingOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAirbnbAppBar() {
    return AppBar(
      backgroundColor: colorPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.close_rounded,
          color: colorTextPrimary,
          size: 22,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        TextButton(
          onPressed: _updateProfile,
          child: Text(
            'Save',
            style: GoogleFonts.plusJakartaSans(
              color: colorAccent,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildKycHeaderBanner() {
    final bool isVerified = _kycStatus == 'verified';
    if (isVerified) return const SizedBox.shrink();

    final bool isPending = _kycStatus == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPending ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? const Color(0xFFFDE68A) : const Color(0xFFFCA5A5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPending ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPending ? Icons.hourglass_top_rounded : Icons.shield_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPending ? 'KYC Verification Under Review' : 'KYC Verification Required',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isPending ? const Color(0xFF92400E) : const Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPending
                          ? 'Your identity documents are currently being reviewed by admin.'
                          : 'Verify your identity to unlock owner features & instant booking.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isPending ? const Color(0xFFB45309) : const Color(0xFFB91C1C),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isPending) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KycScreen()),
                  );
                  if (result == true) _loadUserData();
                },
                icon: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 18),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Verify Identity Now (KYC)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAirbnbHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: colorTextPrimary,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildAirbnbField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    FocusNode? focusNode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: enabled,
            focusNode: focusNode,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: enabled ? colorTextPrimary : colorTextSecondary,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: enabled
                  ? colorPrimary
                  : colorSecondary.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: colorTextPrimary,
                  width: 1.5,
                ),
              ),
              suffixIcon: !enabled
                  ? const Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: colorTextSecondary,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              _imageFile != null
                  ? Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : AppTheme.buildAvatarWidget(
                      avatarUrl: _avatarUrl,
                      radius: 60,
                      name: _fullNameController.text,
                    ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorTextPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorPrimary, width: 3),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: colorPrimary,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAvatarChip(
              label: '👨 Man Avatar',
              isSelected:
                  _avatarUrl == 'assets/images/man avatar.jpeg' &&
                  _imageFile == null,
              onTap: () {
                setState(() {
                  _imageFile = null;
                  _avatarUrl = 'assets/images/man avatar.jpeg';
                });
                HapticFeedback.lightImpact();
              },
            ),
            const SizedBox(width: 10),
            _buildAvatarChip(
              label: '👩 Woman Avatar',
              isSelected:
                  _avatarUrl == 'assets/images/women avatar.jpeg' &&
                  _imageFile == null,
              onTap: () {
                setState(() {
                  _imageFile = null;
                  _avatarUrl = 'assets/images/women avatar.jpeg';
                });
                HapticFeedback.lightImpact();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.brandColor : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : colorTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppTheme.brandColor, size: 22),
              const SizedBox(width: 10),
              Text(
                'Location / ठेगाना',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pin your exact GPS location to enable distance calculation for guests and nearby services.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colorTextSecondary,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLocating ? null : _updateLocation,
              icon: _isLocating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorTextPrimary,
                      ),
                    )
                  : Icon(
                      _latitude != null
                          ? Icons.refresh_rounded
                          : Icons.my_location_rounded,
                      size: 18,
                    ),
              label: Text(
                _isLocating
                    ? 'Capturing GPS...'
                    : (_latitude != null
                          ? 'Update GPS Location'
                          : 'Pin My Location'),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorTextPrimary,
                side: const BorderSide(color: colorTextPrimary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (_latitude != null && _longitude != null) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                '📍 Location saved: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.brandColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPremiumMediaGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildAirbnbMediaTile(
            'PAYMENT QR',
            _qrFile,
            _qrCodeUrl,
            _pickQrCode,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAirbnbMediaTile(
            'STUDENT ID',
            _idFile,
            _studentIdUrl,
            _pickStudentId,
          ),
        ),
      ],
    );
  }

  Widget _buildAirbnbMediaTile(
    String label,
    File? file,
    String? url,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: colorTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.transparent),
            ),
            child: (file != null || url != null)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: file != null
                        ? Image.file(file, fit: BoxFit.cover)
                        : KhoznaImage(imageUrl: url!, fit: BoxFit.cover),
                  )
                : const Icon(Icons.add_rounded, color: colorTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAirbnbSaveButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        color: colorAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Update Profile',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
    );
  }

  Widget _buildPremiumLoadingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.8),
      child: const Center(
        child: CircularProgressIndicator(
          color: colorTextPrimary,
          strokeWidth: 3,
        ),
      ),
    );
  }
}
