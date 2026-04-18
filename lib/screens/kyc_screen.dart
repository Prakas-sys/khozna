import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../utils/security_utils.dart';
import '../utils/cloudinary_service.dart';
import '../utils/kyc_ai_analyser.dart';

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
  bool _isPickerActive = false;
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
    SecurityUtils.setSecure(false);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = supabase.Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final metadata = user.userMetadata ?? {};
      if (mounted) {
        setState(() {
          _nameController.text =
              metadata['full_name'] ?? metadata['name'] ?? '';
          _emailController.text = user.email ?? '';
          _phoneController.text = user.phone ?? '';

          if (user.email != null) _isEmailVerified = true;
          if (user.phone != null && user.phone!.isNotEmpty)
            _isPhoneVerified = true;
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
            if (profile['full_name'] != null)
              _nameController.text = profile['full_name'];
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
    SecurityUtils.setSecure(false);
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _citizenshipController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _pickImage(String type) async {
    if (_isPickerActive) return;
    _isPickerActive = true;
    try {
      if (type == 'selfie') {
        final status = await Permission.camera.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'क्यामेरा अनुमति आवश्यक छ (Camera permission required)',
                ),
                backgroundColor: Colors.orange[800],
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Settings',
                  textColor: Colors.white,
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
          return;
        }
      }

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
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (e.toString().contains('already_active')) return; // Ignore double taps silently
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _isPickerActive = false;
    }
  }

  void _showAiRejectionDialog(List<String> redFlags) {
    HapticFeedback.vibrate();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 60),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'AI Rejection (अस्वीकृत)',
                textAlign: TextAlign.center,
                style: GoogleFonts.mukta(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.red[800],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Our AI detected the following issues with your documents. Please fix them and try again:',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ...redFlags.map((flag) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.red, fontSize: 16)),
                      Expanded(
                        child: Text(
                          flag,
                          style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Try Again (फेरि प्रयास गर्नुहोस्)',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(bool isVerified) {
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 24),
            Text(
              isVerified ? 'Verification Complete! 🎉' : 'प्रमाणिकरणको लागि प्राप्त भयो!',
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isVerified 
                  ? 'Our AI has instantly verified your identity. You can now post properties!'
                  : 'तपाईको कागजातहरू प्राप्त भएका छन्। हामी ४८ घण्टा भित्र प्रमाणीकरण गर्नेछौं।',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'ठीक छ (Okay)',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
      final results = await Future.wait([
        CloudinaryService.uploadImage(_frontImage!).timeout(const Duration(minutes: 2)),
        CloudinaryService.uploadImage(_backImage!).timeout(const Duration(minutes: 2)),
        CloudinaryService.uploadImage(_selfieImage!).timeout(const Duration(minutes: 2)),
      ]);

      final frontUrl = results[0];
      final backUrl = results[1];
      final selfieUrl = results[2];

      if (frontUrl == null || backUrl == null || selfieUrl == null) {
        throw Exception('Image upload failed (नेटवर्क वा क्लाउडिनरी समस्या)');
      }

      // ─── CLOUD AUTO-PILOT (PRO) ───
      // The backend now automatically handles the AI scan via a DB trigger.
      // We just need to submit the data and wait for the real-time notification!
      
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
        'status': 'pending', // Backend will update this automatically
      });

      await supabase.Supabase.instance.client
          .from('profiles')
          .update({
            'kyc_status': 'pending',
            'email_verified': _isEmailVerified,
            'phone_verified': _isPhoneVerified,
          })
          .eq('id', user.id);

      if (mounted) {
        setState(() => _isSubmitting = false);
        HapticFeedback.mediumImpact();
        
        // Show a professional dialog informing the user about the cloud scan
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'कागजातहरू बुझाइयो', 
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)
                  ),
                ),
              ],
            ),
            content: Text(
              'तपाइँको कागजातहरू सफलतापूर्वक बुझाइएको छ! हाम्रो टोलीले आगामी ४८ घण्टा भित्र यी कागजातहरू प्रमाणीकरण गर्नेछ।\n\nप्रक्रिया पूरा भएपछि तपाइँलाई मोबाइलमा सूचना (Notification) पठाइनेछ।',
              style: GoogleFonts.inter(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (mounted) Navigator.pop(context); // Go back to profile
                },
                child: Text(
                  'हुन्छ, बुझें',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
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
      backgroundColor: Colors.white, // Pure white base
      body: Stack(
        children: [
          Column(
            children: [
              _buildPremiumHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 24.0,
                    bottom: 120.0, // Space for sticky bottom bar
                  ),
                  child: Form(
                    key: _formKey,
                    child: _currentStep == 1
                        ? _buildBasicInfoStep()
                        : _buildDocumentStep(),
                  ),
                ),
              ),
            ],
          ),
          
          // Sticky Bottom Glass Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: _currentStep == 1
                      ? _buildStepButton('Next Step (अर्को चरण)', _nextStep)
                      : _buildSubmitButton(),
                ),
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
        _buildSectionHeader('Basic Information (व्यक्तिगत विवरण)'),
        const SizedBox(height: 24),
        _buildTextField(
          _nameController,
          'Full Name (पूरा नाम)',
          Icons.person_outline_rounded,
          (v) => v!.isEmpty ? 'आवश्यक (Required)' : null,
        ),
        const SizedBox(height: 20),
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
        const SizedBox(height: 20),
        _buildTextField(
          _phoneController,
          'Phone Number (फोन नम्बर)',
          Icons.phone_android_rounded,
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
        const SizedBox(height: 20),
        _buildTextField(
          _citizenshipController,
          'Citizenship Number (नागरिकता नम्बर)',
          Icons.badge_outlined,
          (v) => v!.isEmpty ? 'Required' : null,
          inputFormatters: [CitizenshipFormatter()],
        ),
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
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        readOnly: isVerified,
        enabled: !isVerified,
        onChanged: (v) => setState(() {}),
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isVerified ? Colors.grey[600] : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            color: Colors.grey[500],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: GoogleFonts.inter(
            color: AppTheme.brandColor,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: providerLogo != null
              ? Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Image.network(providerLogo, width: 22, height: 22),
                )
              : Icon(
                  icon,
                  color: controller.text.isNotEmpty ? AppTheme.brandColor : Colors.grey[400],
                  size: 22,
                ),
          suffixIcon: isVerified
              ? Container(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Verified',
                        style: GoogleFonts.inter(
                          color: Colors.green[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified_rounded,
                        color: Colors.green[600],
                        size: 16,
                      ),
                    ],
                  ),
                )
              : null,
          filled: true,
          fillColor: isVerified
              ? Colors.grey[50]
              : (controller.text.isNotEmpty ? Colors.blue[50]!.withOpacity(0.3) : Colors.white),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: controller.text.isNotEmpty ? AppTheme.brandColor.withOpacity(0.3) : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.brandColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
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
        _buildSectionHeader('Citizenship Front (नागरिकताको अगाडि)'),
        const SizedBox(height: 12),
        _buildPhotoUploadBox(
          'front',
          'Upload Front',
          'PNG, JPG (max. 5MB)',
          _frontImage,
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Citizenship Back (नागरिकताको पछाडि)'),
        const SizedBox(height: 12),
        _buildPhotoUploadBox(
          'back',
          'Upload Back',
          'PNG, JPG (max. 5MB)',
          _backImage,
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Your Selfie (तपाईंको अनुहारको सेल्फी)'),
        const SizedBox(height: 12),
        _buildPhotoUploadBox(
          'selfie',
          'Upload Selfie',
          'A clear photo of your face',
          _selfieImage,
          isSelfie: true,
        ),
        const SizedBox(height: 32),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _currentStep = 1),
            icon: Icon(Icons.arrow_back_rounded, size: 16, color: Colors.grey[600]),
            label: Text(
              'Back to Details (विवरण सच्याउनुहोस्)',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.brandColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
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
        color: _isSubmitting ? Colors.grey[300] : AppTheme.brandColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isSubmitting
            ? null
            : [
                BoxShadow(
                  color: AppTheme.brandColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Submit Verification',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.brandColor,
            AppTheme.brandColor.withOpacity(0.85),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'VERIFY IDENTITY',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'पहिचान प्रमाणित गर्नुहोस्',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.mukta(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildStepperIndicator(_currentStep >= 1, true)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStepperIndicator(_currentStep >= 2, _currentStep >= 2)),
                  ],
                ),
              ],
            ),
          ),
          
          // Shield Icon (Left)
          Positioned(
            left: 16,
            top: 42,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 22),
            ),
          ),
          
          // Close Button (Right)
          Positioned(
            right: 12,
            top: 40,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),

          // Decorative glowing orb
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperIndicator(bool active, bool isCurrent) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 4,
      decoration: BoxDecoration(
        color: active
            ? Colors.white
            : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildLocationVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Location Verification (लोकेसन)'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _latitude != null ? Colors.green.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _latitude != null ? Colors.green.withOpacity(0.5) : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _latitude != null ? Colors.green : AppTheme.brandColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _latitude != null ? Icons.my_location_rounded : Icons.location_on_rounded,
                  color: _latitude != null ? Colors.white : AppTheme.brandColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _latitude != null ? 'GPS Verified' : 'Detect Location',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _latitude != null ? Colors.green[800] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _latitude != null
                          ? '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                          : 'Required for security',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (_latitude == null)
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _isLocating ? null : _detectLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLocating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text('Verify', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.mukta(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildPhotoUploadBox(
    String type,
    String title,
    String subtitle,
    File? image, {
    bool isSelfie = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _pickImage(type);
      },
      child: CustomPaint(
        painter: DashRectPainter(
          color: image != null ? Colors.green.withOpacity(0.5) : AppTheme.brandColor.withOpacity(0.4), 
          gap: 6,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: image != null ? Colors.green.withOpacity(0.04) : AppTheme.brandColor.withOpacity(0.02),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (image != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    image,
                    height: 120,
                    width: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Uploaded Successfully',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelfie ? Icons.face_retouching_natural_rounded : Icons.camera_alt_rounded,
                    color: AppTheme.brandColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[500],
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
      if (formatted.length >= 14) break;
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

  DashRectPainter({
    this.color = Colors.black,
    this.strokeWidth = 1.5,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path = Path();
    path.addRRect(
      RRect.fromLTRBR(0, 0, size.width, size.height, const Radius.circular(20)),
    );

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
