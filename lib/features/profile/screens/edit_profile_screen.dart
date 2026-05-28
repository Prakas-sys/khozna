import 'package:khozna/widgets/khozna_image.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/services/cloudinary_service.dart';
import 'package:khozna/features/profile/screens/kyc_screen.dart';
import 'package:khozna/core/security/security_utils.dart';
import 'package:khozna/core/utils/offline_storage.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  @override
  void initState() {
    super.initState();
    SecurityUtils.setSecure(
      true,
    ); // 🔐 Screen Shield: blocks screenshots on profile data
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
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      setState(() => _isLoading = true);
      try {
        // Load Profile
        final profile = await Supabase.instance.client
            .from('profiles')
            .select(
              'full_name, email, phone_number, avatar_url, esewa_number, khalti_number, account_holder_name, qr_code_url, area_name, user_type, bio, organization, student_id_url',
            )
            .eq('id', user!.id)
            .maybeSingle();

        // Load KYC Location
        final kyc = await Supabase.instance.client
            .from('kyc_verifications')
            .select('latitude, longitude, status')
            .eq('user_id', user!.id)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (mounted) {
          setState(() {
            _fullNameController.text =
                profile?['full_name'] ??
                user?.userMetadata?['full_name'] ??
                user?.userMetadata?['name'] ??
                '';
            _emailController.text = profile?['email'] ?? user?.email ?? '';
            _phoneController.text =
                profile?['phone_number'] ?? user?.phone ?? '';
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
        debugPrint('Error loading profile data: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Attempt reverse geocoding to pre-fill area name if empty
      String? localityName;
      try {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          localityName = [p.subLocality, p.locality].where((e) => e != null && e.isNotEmpty).join(', ');
        }
      } catch (_) {
        debugPrint('Geocoding failed');
      }

      // Update in DB (kyc_verifications)
      await Supabase.instance.client
          .from('kyc_verifications')
          .update({
            'latitude': position.latitude,
            'longitude': position.longitude,
          })
          .eq('user_id', user!.id);

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          
          if (_areaController.text.trim().isEmpty && localityName != null && localityName.isNotEmpty) {
            _areaController.text = localityName;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPS Location updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating location: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickQrCode() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _qrFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickStudentId() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _idFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (user != null) {
        String? newImageUrl = _avatarUrl;
        String? newQrUrl = _qrCodeUrl;
        String? newIdUrl = _studentIdUrl;

        if (_imageFile != null) {
          newImageUrl = await CloudinaryService.uploadImage(_imageFile!);
        }

        if (_qrFile != null) {
          newQrUrl = await CloudinaryService.uploadImage(_qrFile!);
        }

        if (_idFile != null) {
          newIdUrl = await CloudinaryService.uploadImage(_idFile!);
        }

        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: {
              'full_name': SecurityUtils.sanitizeInput(
                _fullNameController.text,
              ),
              'avatar_url': newImageUrl,
            },
          ),
        );

        // Update Table
        await Supabase.instance.client
            .from('profiles')
            .update({
              'full_name': SecurityUtils.sanitizeInput(
                _fullNameController.text,
              ),
              'avatar_url': newImageUrl,
              'esewa_number': SecurityUtils.sanitizeInput(
                _esewaController.text,
              ),
              'khalti_number': SecurityUtils.sanitizeInput(
                _khaltiController.text,
              ),
              'account_holder_name': SecurityUtils.sanitizeInput(
                _accountNameController.text,
              ),
              'qr_code_url': newQrUrl,
              'phone_number': SecurityUtils.sanitizeInput(_phoneController.text),
              'area_name': SecurityUtils.sanitizeInput(_areaController.text),
              'user_type': SecurityUtils.sanitizeInput(_userTypeController.text),
              'bio': SecurityUtils.sanitizeInput(_bioController.text),
              'organization':
                  SecurityUtils.sanitizeInput(_orgController.text),
              'student_id_url': newIdUrl,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', user!.id);

        // Sync local cache
        final updatedCache = {
          'full_name': _fullNameController.text,
          'avatar_url': newImageUrl,
          'phone_number': _phoneController.text,
          'esewa_number': _esewaController.text,
          'khalti_number': _khaltiController.text,
          'area_name': _areaController.text,
          'user_type': _userTypeController.text,
          'bio': _bioController.text,
          'organization': _orgController.text,
        };
        profileCache.value = {...(profileCache.value ?? {}), ...updatedCache};
        await OfflineStorage.saveProfileCache(profileCache.value!);

        // Sync phone number to KYC record if it exists
        final phone = SecurityUtils.sanitizeInput(_phoneController.text);
        if (phone.isNotEmpty) {
          await Supabase.instance.client
              .from('kyc_verifications')
              .update({'phone_number': phone})
              .eq('user_id', user!.id);
        }

        if (mounted) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfilePhotoSection(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('PERSONAL DETAILS'),
                  const SizedBox(height: 16),
                  _buildFieldCard([
                    _buildInputField(
                      'Full Name',
                      _fullNameController,
                      null,
                      svgPath: 'assets/icons/Vector profile.svg',
                    ),
                    const Divider(height: 1),
                    _buildInputField(
                      'Email Address',
                      _emailController,
                      Icons.email_outlined,
                      enabled: false,
                      subtitle: 'Contact support to change email',
                    ),
                    const Divider(height: 1),
                    _buildInputField(
                      'Phone Number',
                      _phoneController,
                      Icons.phone_android_rounded,
                      subtitle: 'Direct contact number for guests/owners',
                      keyboardType: TextInputType.phone,
                    ),
                    const Divider(height: 1),
                    _buildInputField(
                      'Current Area (बस्ने ठाउँ)',
                      _areaController,
                      Icons.location_on_outlined,
                      subtitle: 'Example: Baneshwor, Kathmandu',
                    ),
                    const Divider(height: 1),
                    _buildInputField(
                      'User Type (पेशा / स्थिति)',
                      _userTypeController,
                      Icons.badge_outlined,
                      subtitle: 'Example: Student, Family, Professional',
                    ),
                    const Divider(height: 1),
                    _buildInputField(
                      'College / Organization (कलेज वा अफिस)',
                      _orgController,
                      Icons.business_rounded,
                      subtitle: 'Example: Pulchowk Campus, TUTH, or Company Name',
                    ),
                    const Divider(height: 1),
                    _buildInputField(
                      'About You (आफ्नो बारेमा छोटो जानकारी)',
                      _bioController,
                      Icons.description_outlined,
                      subtitle: 'Help owners trust you! Mention your study/hobbies.',
                      maxLines: 3,
                    ),
                    const Divider(height: 1),
                    _buildIdCardPicker(),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionTitle('PAYMENT INFORMATION (OWNER ONLY)'),
                  const SizedBox(height: 16),
                  _buildFieldCard([
                    _buildInputField(
                      'eSewa Number',
                      _esewaController,
                      Icons.account_balance_wallet_outlined,
                      subtitle: 'Guests will pay to this number',
                      keyboardType: TextInputType.phone,
                    ),
                    const Divider(height: 1),
                    _buildInputField(
                      'Khalti Number',
                      _khaltiController,
                      Icons.account_balance_wallet_rounded,
                      subtitle: 'Optional alternative payment',
                      keyboardType: TextInputType.phone,
                    ),
                    const Divider(height: 1),
                    _buildInputField(
                      'Account Holder Name',
                      _accountNameController,
                      Icons.badge_outlined,
                      subtitle: 'Name as seen on Bank/eSewa',
                    ),
                    const Divider(height: 1),
                    _buildQrPicker(),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionTitle('VERIFIED LOCATION'),
                  const SizedBox(height: 16),
                  _buildLocationCard(),
                  const SizedBox(height: 40),
                  _buildSaveButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (!_isLoading)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _updateProfile,
              child: Text(
                'Save',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.brandColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: ClipOval(
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                    ? KhoznaImage(imageUrl: _avatarUrl!, fit: BoxFit.cover)
                    : Container(
                        color: AppTheme.brandColor.withOpacity(0.1),
                        padding: const EdgeInsets.all(24),
                        child: SvgPicture.asset(
                          'assets/icons/Vector profile.svg',
                          colorFilter: const ColorFilter.mode(
                            AppTheme.brandColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.brandColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.brandColor.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF64748B),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildFieldCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData? icon, {
    String? svgPath,
    bool enabled = true,
    String? subtitle,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.brandColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: svgPath != null
                ? SvgPicture.asset(
                    svgPath,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      AppTheme.brandColor,
                      BlendMode.srcIn,
                    ),
                  )
                : Icon(icon ?? Icons.help_outline, color: AppTheme.brandColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextField(
                  controller: controller,
                  enabled: enabled,
                  maxLines: maxLines,
                  keyboardType: keyboardType,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: enabled ? Colors.black87 : Colors.grey[600],
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: 'Not provided',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.grey[400],
                    ),
                  ),
              ],
            ),
          ),
          if (!enabled)
            const Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: Colors.grey,
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final bool hasLocation = _latitude != null && _longitude != null;
    final bool isVerified = _kycStatus == 'verified';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isVerified
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isVerified
                      ? Icons.verified_user_rounded
                      : Icons.location_on_outlined,
                  color: isVerified ? Colors.green : Colors.orange,
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
                          ? 'Verified GPS Location'
                          : 'Current GPS Status',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      hasLocation
                          ? '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                          : 'Location not set yet',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SECURE',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLocating ? null : _updateLocation,
              icon: _isLocating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                hasLocation
                    ? 'Update Current Location'
                    : 'Link Current Location',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.brandColor,
                side: BorderSide(color: AppTheme.brandColor.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (!isVerified)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Complete KYC to verify your permanent address.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.brandColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          shadowColor: AppTheme.brandColor.withOpacity(0.5),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'Save Changes',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }

  Widget _buildQrPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'eSewa QR Code',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (_qrFile != null ||
                    (_qrCodeUrl != null && _qrCodeUrl!.isNotEmpty))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: _qrFile != null
                          ? Image.file(_qrFile!, fit: BoxFit.cover)
                          : KhoznaImage(
                              imageUrl: _qrCodeUrl!,
                              fit: BoxFit.cover,
                            ),
                    ),
                  )
                else
                  Text(
                    'No QR code uploaded',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _pickQrCode,
            child: Text(
              _qrFile != null || _qrCodeUrl != null ? 'Change' : 'Upload',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.brandColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdCardPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.badge_rounded,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'College ID Card (Student Proof)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'कलेज आइडी (परिचय पत्र)',
                  style: GoogleFonts.mukta(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_idFile != null ||
                    (_studentIdUrl != null && _studentIdUrl!.isNotEmpty))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: _idFile != null
                          ? Image.file(_idFile!, fit: BoxFit.cover)
                          : KhoznaImage(
                              imageUrl: _studentIdUrl!,
                              fit: BoxFit.cover,
                            ),
                    ),
                  )
                else
                  Text(
                    'No ID uploaded yet',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: _pickStudentId,
            child: Text(
              _idFile != null || _studentIdUrl != null ? 'Change' : 'Upload',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.brandColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
