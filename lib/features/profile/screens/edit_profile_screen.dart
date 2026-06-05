import 'package:khozna/widgets/khozna_image.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/services/cloudinary_service.dart';
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
      backgroundColor: const Color(0xFFFBFBFC),
      extendBodyBehindAppBar: true,
      appBar: _buildPremiumAppBar(),
      body: Stack(
        children: [
          _buildBackgroundAccents(),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 140),
                _buildProfilePhotoSection(),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildSectionHeader('IDENTITY', 'Essential account info'),
                      const SizedBox(height: 16),
                      _buildModernCard([
                        _buildSophisticatedField('Full Name', _fullNameController, Icons.person_outline_rounded),
                        _buildSophisticatedField('Email Address', _emailController, Icons.alternate_email_rounded, enabled: false),
                        _buildSophisticatedField('Phone Number', _phoneController, Icons.phone_iphone_rounded, keyboardType: TextInputType.phone),
                      ]),
                      const SizedBox(height: 32),
                      _buildSectionHeader('SITUATION', 'Role and location details'),
                      const SizedBox(height: 16),
                      _buildModernCard([
                        _buildSophisticatedField('Neighborhood', _areaController, Icons.explore_outlined),
                        _buildSophisticatedField('Profile Role', _userTypeController, Icons.work_outline_rounded),
                        _buildSophisticatedField('Organization', _orgController, Icons.apartment_rounded),
                        _buildSophisticatedField('Brief Bio', _bioController, Icons.auto_awesome_rounded, maxLines: 3),
                      ]),
                      const SizedBox(height: 24),
                      _buildVerificationCard(),
                      const SizedBox(height: 32),
                      _buildSectionHeader('PAYMENTS', 'Withdrawal information'),
                      const SizedBox(height: 16),
                      _buildModernCard([
                        _buildSophisticatedField('eSewa ID', _esewaController, Icons.account_balance_wallet_outlined),
                        _buildSophisticatedField('Khalti ID', _khaltiController, Icons.account_balance_wallet_rounded),
                        _buildSophisticatedField('Legal Name', _accountNameController, Icons.verified_user_outlined),
                        _buildMediaTile('PAYMENT QR', _qrFile, _qrCodeUrl, _pickQrCode),
                        _buildMediaTile('STUDENT ID', _idFile, _studentIdUrl, _pickStudentId),
                      ]),
                      const SizedBox(height: 48),
                      _buildPremiumSaveButton(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildPremiumAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 19, color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: _updateProfile,
            child: Text('Done', style: GoogleFonts.plusJakartaSans(color: AppTheme.brandColor, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildBackgroundAccents() {
    return Positioned(
      top: -100,
      right: -50,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [AppTheme.brandColor.withOpacity(0.05), Colors.transparent]),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.5)),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildModernCard(List<Widget> children) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSophisticatedField(String label, TextEditingController controller, IconData icon, {bool enabled = true, int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.05)))),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.black, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.w900)),
                TextField(
                  controller: controller,
                  enabled: enabled,
                  maxLines: maxLines,
                  keyboardType: keyboardType,
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: enabled ? Colors.black : Colors.grey[500]),
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4), border: InputBorder.none),
                ),
              ],
            ),
          ),
          if (!enabled) const Icon(Icons.lock_rounded, size: 14, color: Color(0xFFD1D5DB)),
        ],
      ),
    );
  }

  Widget _buildMediaTile(String label, File? file, String? url, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.camera_alt_outlined, color: Colors.black, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.w900)),
                  Text(file != null || url != null ? 'Selected ✓' : 'Upload Image', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.brandColor)),
                ],
              ),
            ),
            if (file != null || url != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: file != null ? Image.file(file, width: 36, height: 36, fit: BoxFit.cover) : KhoznaImage(imageUrl: url!, width: 36, height: 36, fit: BoxFit.cover),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.brandColor.withOpacity(0.1), width: 1))),
          Container(
            width: 115,
            height: 115,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 25, offset: const Offset(0, 10))]),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: _imageFile != null ? Image.file(_imageFile!, fit: BoxFit.cover) : (_avatarUrl != null ? KhoznaImage(imageUrl: _avatarUrl!, fit: BoxFit.cover) : Container(color: const Color(0xFFF3F4F6), child: Icon(Icons.person_rounded, color: Colors.grey[300], size: 50))),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)),
                child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    bool isVerified = _kycStatus == 'verified';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isVerified ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(24), border: Border.all(color: isVerified ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1))),
      child: Column(
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isVerified ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(12)), child: Icon(isVerified ? Icons.verified_rounded : Icons.gpp_maybe_rounded, color: Colors.white, size: 20)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isVerified ? 'Identity Verified' : 'Verification Pending', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 15, color: isVerified ? Colors.green[900] : Colors.orange[900])),
                    Text(_latitude != null ? 'Secure GPS Linked' : 'Please link your GPS location.', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: isVerified ? Colors.green[700] : Colors.orange[700])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLocating ? null : _updateLocation,
              style: ElevatedButton.styleFrom(backgroundColor: isVerified ? Colors.green : Colors.orange, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(vertical: 12)),
              child: _isLocating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isVerified ? 'Refresh Location' : 'Security Check', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppTheme.brandColor.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateProfile,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
        child: Text('Save Configuration', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(color: Colors.white.withOpacity(0.5), child: const Center(child: CircularProgressIndicator(color: Colors.black)));
  }
}
