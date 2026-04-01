import 'dart:io';
import 'dart:ui';
// firebase_auth removed
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../theme/app_theme.dart';
import '../utils/security_utils.dart';
import '../utils/cloudinary_service.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _citizenshipController = TextEditingController();
  
  int _currentStep = 1; // 1: Basic Info, 2: Documents
  bool _isSubmitting = false;
  bool _isLocating = false;
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  double? _latitude;
  double? _longitude;

  File? _frontImage;
  File? _backImage;
  File? _selfieImage;
  final ImagePicker _picker = ImagePicker();

  String? _authProvider;

  @override
  void initState() {
    super.initState();
    // Use a small delay to ensure the window is ready for flag changes on Android
    Future.delayed(const Duration(milliseconds: 500), () {
      SecurityUtils.setSecure(false);
    });
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = supabase.Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final metadata = user.userMetadata ?? {};
      if (mounted) {
        setState(() {
          _nameController.text = metadata['full_name'] ?? metadata['name'] ?? '';
          _emailController.text = user.email ?? '';
          _phoneController.text = user.phone ?? '';
          
          if (user.email != null) _isEmailVerified = true;
          if (user.phone != null && user.phone!.isNotEmpty) _isPhoneVerified = true;
        });
      }

      try {
        final profile = await supabase.Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();
        
        if (mounted) {
          setState(() {
            if (profile['full_name'] != null) _nameController.text = profile['full_name'];
            if (profile['email'] != null) {
              _emailController.text = profile['email'];
              _isEmailVerified = true;
            }
            if (profile['phone'] != null) {
              _phoneController.text = profile['phone'];
              _isPhoneVerified = true;
            }
          });
        }
      } catch (e) {
        debugPrint('Profile error during KYC load: $e');
      }
    }
  }

  @override
  void dispose() {
    SecurityUtils.setSecure(false); // Ensure it's unlocked when leaving
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _citizenshipController.dispose();
    super.dispose();
  }

// Removed local redundant secure screen method


  Future<void> _detectLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _isLocating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(
      source: type == 'selfie' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        if (type == 'front') _frontImage = File(image.path);
        if (type == 'back') _backImage = File(image.path);
        if (type == 'selfie') _selfieImage = File(image.path);
      });
    }
  }

  void _showSuccessDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            Text(
              'प्रमाणिकरणको लागि प्राप्त भयो!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'तपाईको कागजातहरू प्राप्त भएका छन्। हामी ४८ घण्टा भित्र प्रमाणीकरण गर्नेछौं।',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ठीक छ (Okay)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep = 2);
      }
    }
  }

  Future<void> _submit() async {
    if (_latitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your location first')),
      );
      return;
    }

    if (_frontImage == null || _backImage == null || _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required photos')),
      );
      return;
    }

    final user = supabase.Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      debugPrint('--- KYC: Starting Parallel Uploads ---');
      // 1. Upload Images to Cloudinary in Parallel (Speed Boost! 🚀)
      final results = await Future.wait([
        CloudinaryService.uploadImage(_frontImage!).timeout(const Duration(minutes: 2)),
        CloudinaryService.uploadImage(_backImage!).timeout(const Duration(minutes: 2)),
        CloudinaryService.uploadImage(_selfieImage!).timeout(const Duration(minutes: 2)),
      ]);
      
      final frontUrl = results[0];
      final backUrl = results[1];
      final selfieUrl = results[2];

      if (frontUrl == null || backUrl == null || selfieUrl == null) {
        debugPrint('KYC: Image upload returned null. Check network or Cloudinary.');
        throw Exception('Image upload failed (नेटवर्क वा क्लाउडिनरी समस्या)');
      }

      debugPrint('--- KYC: Images Uploaded, saving to Supabase ---');
      // 2. Save to Supabase
      await supabase.Supabase.instance.client.from('kyc_verifications').insert({
        'user_id': user.id,
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'citizenship_number': _citizenshipController.text.trim(),
        'front_image_url': frontUrl,
        'back_image_url': backUrl,
        'selfie_image_url': selfieUrl,
        'latitude': _latitude,
        'longitude': _longitude,
        'is_email_verified': _isEmailVerified,
        'is_phone_verified': _isPhoneVerified,
        'status': 'pending',
      });

      // 3. Update Profile Status
      await supabase.Supabase.instance.client.from('profiles').update({
        'kyc_status': 'pending',
        'email_verified': _isEmailVerified,
        'phone_verified': _isPhoneVerified,
      }).eq('id', user.id);

      debugPrint('--- KYC: Submission Successful ---');
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint('KYC Submission Error: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildPremiumHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
              child: Form(
                key: _formKey,
                child: _currentStep == 1 ? _buildBasicInfoStep() : _buildDocumentStep(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Basic Information (व्यक्तिगत विवरण)', false),
        const SizedBox(height: 20),
        _buildTextField(_nameController, 'Full Name (पूरा नाम)', Icons.person_outline, (v) => v!.isEmpty ? 'आवश्यक (Required)' : null),
        const SizedBox(height: 24),
        _buildTextField(
          _emailController,
          'Email Address (इमेल)',
          Icons.email_outlined,
          (v) => v!.isEmpty ? 'Required' : null,
          isVerified: _isEmailVerified,
          providerLogo: _authProvider == 'google' 
              ? 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png'
              : null,
        ),
        const SizedBox(height: 24),
        _buildTextField(
          _phoneController,
          'Phone Number (फोन नम्बर)',
          Icons.phone_android_outlined,
          (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (v.length != 10) return 'Must be 10 digits';
            return null;
          },
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          isVerified: _isPhoneVerified,
        ),
        const SizedBox(height: 24),
        _buildTextField(
          _citizenshipController,
          'Citizenship Number (नागरिकता नम्बर)',
          Icons.badge_outlined,
          (v) => v!.isEmpty ? 'Required' : null,
          inputFormatters: [
            CitizenshipFormatter(),
          ],
        ),
        const SizedBox(height: 40),
        _buildStepButton('Next Step (अर्को चरण)', _nextStep),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, 
    String? Function(String?)? validator, {
    TextInputType? keyboardType, 
    List<TextInputFormatter>? inputFormatters, 
    bool isVerified = false,
    String? providerLogo,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      readOnly: isVerified,
      enabled: !isVerified,
      onChanged: (v) => setState(() {}),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isVerified ? Colors.grey[600] : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w600),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(color: AppTheme.brandColor, fontWeight: FontWeight.bold),
        prefixIcon: providerLogo != null 
          ? Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.network(providerLogo, width: 20, height: 20),
            )
          : Icon(icon, color: AppTheme.brandColor.withValues(alpha: 0.8), size: 22),
        suffixIcon: isVerified
            ? Container(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Auto-filled (स्वत: भरियो)',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF00B4F5),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF00B4F5), size: 16),
                  ],
                ),
              )
            : null,
        filled: true,
        fillColor: isVerified ? const Color(0xFFF1F5F9) : (controller.text.isNotEmpty ? Colors.white : const Color(0xFFF8FAFC)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), 
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), 
          borderSide: BorderSide(
            color: controller.text.isNotEmpty ? AppTheme.brandColor.withValues(alpha: 0.4) : Colors.grey.shade200,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), 
          borderSide: const BorderSide(color: AppTheme.brandColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), 
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), 
          borderSide: const BorderSide(color: Colors.red, width: 1.8),
        ),
      ),
    );
  }

  Widget _buildDocumentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLocationVerification(),
        const SizedBox(height: 32),
        _buildSectionHeader('Citizenship Front (नागरिकताको अगाडि)', false),
        const SizedBox(height: 12),
        _buildPhotoUploadBox('front', 'Upload Front (अगाडिको फोटो)', 'PNG, JPG (max. 5MB)', _frontImage),
        const SizedBox(height: 32),
        _buildSectionHeader('Citizenship Back (नागरिकताको पछाडि)', false),
        const SizedBox(height: 12),
        _buildPhotoUploadBox('back', 'Upload Back (पछाडिको फोटो)', 'PNG, JPG (max. 5MB)', _backImage),
        const SizedBox(height: 32),
        _buildSectionHeader('Selfie with Document (नागरिकता समातेको सेल्फी)', false),
        const SizedBox(height: 12),
        _buildPhotoUploadBox('selfie', 'Upload Selfie (सेल्फी)', 'Hold ID clearly', _selfieImage, isSelfie: true),
        const SizedBox(height: 40),
        _buildSubmitButton(),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Back to Details (विवरण सच्याउनुहोस्)',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStepButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppTheme.brandColor,
        boxShadow: [BoxShadow(color: AppTheme.brandColor.withValues(alpha: 0.25), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 12, 24),
      decoration: const BoxDecoration(color: AppTheme.brandColor),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Verify Your Identity', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5), textAlign: TextAlign.center),
                    const SizedBox(height: 2),
                    Text('(पहिचान प्रमाणित गर्नुहोस्)', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.95), letterSpacing: -0.2, height: 1.1), textAlign: TextAlign.center),
                  ],
                ),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white, size: 22)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildStepperIndicator(_currentStep >= 1)),
              const SizedBox(width: 12),
              Expanded(child: _buildStepperIndicator(_currentStep >= 2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperIndicator(bool active) {
    return Container(
      height: 3.5,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildLocationVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location Verification (लोकेसन प्रमाणीकरण) *',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 14),
        CustomPaint(
          painter: DashRectPainter(color: Colors.grey.shade300, gap: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _latitude != null ? Icons.location_on_rounded : Icons.location_on_rounded,
                    color: _latitude != null ? const Color(0xFF00B4F5) : Colors.grey[400],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detect Location (लोकेसन पत्ता लगाउनुहोस्)',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _latitude != null 
                          ? 'GPS Verified: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                          : 'Required for security (सुरक्षाका लागि आवश्यक)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF888888),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: _isLocating ? null : _detectLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B4F5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLocating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          _latitude != null ? 'Verify Location\n(प्रमाणित)' : 'Verify Location\n(प्रमाणित)',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, height: 1.1),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_latitude == null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                const Icon(Icons.touch_app, color: Color(0xFF00B4F5), size: 18),
                const SizedBox(width: 6),
                Text(
                  'Click here to verify (यहाँ क्लिक गर्नुहोस्)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF00B4F5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool required) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF2D2D2D),
      ),
    );
  }

  Widget _buildPhotoUploadBox(String type, String title, String subtitle, File? image, {bool isSelfie = false}) {
    return GestureDetector(
      onTap: () => _pickImage(type),
      child: CustomPaint(
        painter: DashRectPainter(color: Colors.grey.shade300, gap: 4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (image != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(image, height: 100, width: 160, fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),
                Text(
                  'Uploaded Successfully (सफलतापूर्वक अपलोड भयो)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B4F5).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelfie ? Icons.camera_alt_outlined : Icons.file_upload_outlined,
                    color: const Color(0xFF00B4F5),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF888888),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: _isSubmitting ? Colors.grey[300] : AppTheme.brandColor,
        boxShadow: _isSubmitting ? null : [
          BoxShadow(
            color: AppTheme.brandColor.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.grey[600],
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isSubmitting
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : Text(
              'Submit Verification (सबमिट गर्नुहोस्)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
      ),
    );
  }
}

class CitizenshipFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('-', '');
    String formatted = '';

    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4 || i == 6) {
        formatted += '-';
      }
      formatted += text[i];
      if (formatted.length >= 14) break; // Limit to XX-XX-XX-XXXXX format
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
class DashRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashRectPainter({this.color = Colors.black, this.strokeWidth = 1.0, this.gap = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path = Path();
    path.addRRect(RRect.fromLTRBR(0, 0, size.width, size.height, const Radius.circular(12)));

    Path dashPath = Path();
    for (PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
