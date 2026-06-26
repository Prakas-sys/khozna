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
  static const Color colorPrimary = Colors.white;              // 60%
  static const Color colorSecondary = Color(0xFFF7F7F7);     // 30%
  static const Color colorAccent = AppTheme.brandColor;        // 10%
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
          setState(() {
            _fullNameController.text = profile?['full_name'] ?? '';
            _emailController.text = profile?['email'] ?? user?.email ?? '';
            _phoneController.text = profile?['phone_number'] ?? '';
            _avatarUrl = profile?['avatar_url'];
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
              _latitude = kyc['latitude'];
              _longitude = kyc['longitude'];
              _kycStatus = kyc['status'] ?? 'pending';
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
    setState(() => _isLocating = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await Supabase.instance.client
          .from('kyc_verifications')
          .update({'latitude': position.latitude, 'longitude': position.longitude})
          .eq('user_id', user!.id);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      debugPrint('Location error: $e');
    } finally {
      setState(() => _isLocating = false);
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
    setState(() => _isLoading = true);
    try {
      String? avatar = _avatarUrl;
      String? qr = _qrCodeUrl;
      String? idCard = _studentIdUrl;

      if (_imageFile != null) avatar = await CloudinaryService.uploadImage(_imageFile!);
      if (_qrFile != null) qr = await CloudinaryService.uploadImage(_qrFile!);
      if (_idFile != null) idCard = await CloudinaryService.uploadImage(_idFile!);

      await Supabase.instance.client.from('profiles').update({
        'full_name': _fullNameController.text,
        'avatar_url': avatar,
        'phone_number': _phoneController.text,
        'esewa_number': _esewaController.text,
        'khalti_number': _khaltiController.text,
        'account_holder_name': _accountNameController.text,
        'qr_code_url': qr,
        'area_name': _areaController.text,
        'user_type': _userTypeController.text,
        'bio': _bioController.text,
        'organization': _orgController.text,
        'student_id_url': idCard,
      }).eq('id', user!.id);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Update error: $e');
    } finally {
      setState(() => _isLoading = false);
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
                      _buildAirbnbHeader('Public profile'),
                      const SizedBox(height: 24),
                      _buildAirbnbField('Full Name / पूरा नाम', _fullNameController, focusNode: _focusNodes['name']),
                      _buildAirbnbField('Email Address', _emailController, enabled: false),
                      _buildAirbnbField('Phone Number / फोन नम्बर', _phoneController, keyboardType: TextInputType.phone, focusNode: _focusNodes['phone']),
                      
                      const SizedBox(height: 24),
                      _buildAirbnbHeader('Tell your story'),
                      const SizedBox(height: 24),
                      _buildAirbnbField('Neighborhood / छरछिमेक', _areaController, focusNode: _focusNodes['area']),
                      _buildAirbnbField('Role', _userTypeController, focusNode: _focusNodes['role']),
                      _buildAirbnbField('Organization', _orgController, focusNode: _focusNodes['org']),
                      _buildAirbnbField('Bio / आफ्नो बारेमा', _bioController, maxLines: 4, focusNode: _focusNodes['bio']),

                      const SizedBox(height: 24),
                      _buildSecuritySection(),
                      const SizedBox(height: 32),

                      _buildAirbnbHeader('Payout options'),
                      const SizedBox(height: 24),
                      _buildAirbnbField('eSewa ID', _esewaController, focusNode: _focusNodes['esewa']),
                      _buildAirbnbField('Khalti ID', _khaltiController, focusNode: _focusNodes['khalti']),
                      _buildAirbnbField('Legal Name / कानूनी नाम', _accountNameController, focusNode: _focusNodes['acc']),
                      
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
        icon: const Icon(Icons.close_rounded, color: colorTextPrimary, size: 22),
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

  Widget _buildAirbnbField(String label, TextEditingController controller, {bool enabled = true, int maxLines = 1, TextInputType keyboardType = TextInputType.text, FocusNode? focusNode}) {
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
              fillColor: enabled ? colorPrimary : colorSecondary.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                borderSide: const BorderSide(color: colorTextPrimary, width: 1.5),
              ),
              suffixIcon: !enabled ? const Icon(Icons.lock_outline_rounded, size: 16, color: colorTextSecondary) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorSecondary,
              image: _imageFile != null
                  ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                  : (_avatarUrl != null
                      ? DecorationImage(image: NetworkImage(_avatarUrl!), fit: BoxFit.cover)
                      : null),
            ),
            child: (_avatarUrl == null && _imageFile == null)
                ? const Icon(Icons.person_rounded, color: Colors.grey, size: 50)
                : null,
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
                child: const Icon(Icons.camera_alt_rounded, color: colorPrimary, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    // Treat as verified if status is verified OR if a location was JUST captured
    final bool isVerified = _kycStatus == 'verified' || (_latitude != null && _longitude != null);
    
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Identity & Trust',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorTextPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isVerified ? const Color(0xFFE7F6ED) : const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVerified ? Icons.verified_rounded : Icons.info_outline_rounded,
                      size: 14,
                      color: isVerified ? const Color(0xFF008A05) : const Color(0xFFC13511),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVerified ? 'Verified' : 'Action Required',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isVerified ? const Color(0xFF008A05) : const Color(0xFFC13511),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isVerified 
              ? 'Your identity is confirmed. This builds trust with other Khozna users.' 
              : 'Complete your profile security by pinning your location for local verification.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colorTextSecondary,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLocating ? null : _updateLocation,
              icon: _isLocating 
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: colorTextPrimary))
                : Icon(isVerified ? Icons.refresh_rounded : Icons.location_on_rounded, size: 18),
              label: Text(_isLocating ? 'Capturing...' : (isVerified ? 'Location Updated' : 'Pin My Location')),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorTextPrimary,
                side: const BorderSide(color: colorTextPrimary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (_latitude != null && _longitude != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Last synced: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: colorTextSecondary,
                  fontStyle: FontStyle.italic,
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
        Expanded(child: _buildAirbnbMediaTile('PAYMENT QR', _qrFile, _qrCodeUrl, _pickQrCode)),
        const SizedBox(width: 16),
        Expanded(child: _buildAirbnbMediaTile('STUDENT ID', _idFile, _studentIdUrl, _pickStudentId)),
      ],
    );
  }

  Widget _buildAirbnbMediaTile(String label, File? file, String? url, VoidCallback onTap) {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          'Update Profile',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumLoadingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.8),
      child: const Center(
        child: CircularProgressIndicator(color: colorTextPrimary, strokeWidth: 3),
      ),
    );
  }
}
