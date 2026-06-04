import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:permission_handler/permission_handler.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/security/security_utils.dart';
import 'package:khozna/core/services/cloudinary_service.dart';
import 'package:khozna/features/profile/widgets/kyc_widgets.dart';
import 'package:khozna/widgets/khozna_feedback.dart';

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

  int _currentStep = 1;
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
    SecurityUtils.setSecure(
      true,
    ); // 🔐 Screen Shield: blocks screenshots on KYC documents
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

          if (user.email != null && user.email!.isNotEmpty) {
            _isEmailVerified = true;
          }
          if (user.phone != null && user.phone!.isNotEmpty) {
            _isPhoneVerified = true;
          }
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
            if (profile['full_name'] != null &&
                profile['full_name'].toString().isNotEmpty) {
              _nameController.text = profile['full_name'];
            }
            if (profile['email'] != null &&
                profile['email'].toString().isNotEmpty) {
              _emailController.text = profile['email'];
              _isEmailVerified = true;
            }
            if (profile['phone'] != null &&
                profile['phone'].toString().isNotEmpty) {
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
          KhoznaFeedback.showError(context, 'कृपया लोकेसन अनुमति दिनुहोस्। (Location permission denied)');
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
        KhoznaFeedback.showError(context, 'Location Error: $e');
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
      if (e.toString().contains('already_active')) return;

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

  void _nextStep() {
    if (_currentStep == 1) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep = 2);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_latitude == null) {
      KhoznaFeedback.showError(context, 'लोकेसन प्रमाणित गर्नुहोस् (Please verify your location first)');
      return;
    }

    if (_frontImage == null || _backImage == null || _selfieImage == null) {
      KhoznaFeedback.showError(context, 'सबै फोटोहरू अपलोड गर्नुहोस् (Please upload all required photos)');
      return;
    }

    final user = supabase.Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      final results = await Future.wait([
        CloudinaryService.uploadImage(
          _frontImage!,
        ).timeout(const Duration(minutes: 2)),
        CloudinaryService.uploadImage(
          _backImage!,
        ).timeout(const Duration(minutes: 2)),
        CloudinaryService.uploadImage(
          _selfieImage!,
        ).timeout(const Duration(minutes: 2)),
      ]);

      final frontUrl = results[0];
      final backUrl = results[1];
      final selfieUrl = results[2];

      if (frontUrl == null || backUrl == null || selfieUrl == null) {
        throw Exception('Image upload failed');
      }

      await supabase.Supabase.instance.client.from('kyc_verifications').insert({
        'user_id': user.id,
        'full_name': SecurityUtils.sanitizeInput(_nameController.text),
        'email': SecurityUtils.sanitizeInput(_emailController.text),
        'phone_number': SecurityUtils.sanitizeInput(_phoneController.text),
        'citizenship_number': SecurityUtils.sanitizeInput(
          _citizenshipController.text,
        ),
        'front_image_url': frontUrl,
        'back_image_url': backUrl,
        'selfie_image_url': selfieUrl,
        'latitude': _latitude,
        'longitude': _longitude,
        'is_email_verified': _isEmailVerified,
        'is_phone_verified': _isPhoneVerified,
        'status': 'pending',
      });

      await supabase.Supabase.instance.client
          .from('profiles')
          .update({
            'full_name': SecurityUtils.sanitizeInput(_nameController.text),
            'kyc_status': 'pending',
            'email_verified': _isEmailVerified,
            'phone_verified': _isPhoneVerified,
          })
          .eq('id', user.id);

      if (mounted) {
        setState(() => _isSubmitting = false);
        KhoznaFeedback.showSuccess(
          context,
          'तपाइँको कागजातहरू सफलतापूर्वक बुझाइएको छ! हाम्रो टोलीले आगामी ४८ घण्टा भित्र प्रमाणीकरण गर्नेछ।',
        );
        // Delay pop slightly so they see the success message
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        KhoznaFeedback.showError(context, 'Submission failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              _buildPremiumHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
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
                      ? KycStepButton(
                          text: 'Next Step (अर्को चरण)',
                          onPressed: _nextStep,
                        )
                      : _buildSubmitButton(),
                ),
              ),
            ),
          ),

          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
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
        const KycSectionHeader(title: 'Basic Information (व्यक्तिगत विवरण)'),
        const SizedBox(height: 24),
        KycTextField(
          controller: _nameController,
          label: 'Full Name (पूरा नाम)',
          icon: Icons.person_outline_rounded,
          validator: (v) => v!.isEmpty ? 'आवश्यक (Required)' : null,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 20),
        KycTextField(
          controller: _emailController,
          label: 'Email Address (इमेल)',
          icon: Icons.email_outlined,
          validator: (v) => v!.isEmpty ? 'Required' : null,
          isVerified: _isEmailVerified,
          providerLogo: _authProvider == 'google'
              ? 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png'
              : null,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 20),
        KycTextField(
          controller: _phoneController,
          label: 'Phone Number (फोन नम्बर)',
          icon: Icons.phone_android_rounded,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            return null;
          },
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(30),
          ],
          isVerified: _isPhoneVerified,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 32),
        _buildLocationVerification(),
      ],
    );
  }

  Widget _buildDocumentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KycTextField(
          controller: _citizenshipController,
          label: 'Citizenship Number (नागरिकता नम्बर)',
          icon: Icons.badge_outlined,
          validator: (v) => v!.isEmpty ? 'Required' : null,
          inputFormatters: [CitizenshipFormatter()],
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 32),
        const KycSectionHeader(title: 'Citizenship Front (नागरिकताको अगाडि)'),
        const SizedBox(height: 12),
        PhotoUploadBox(
          title: 'Upload Front',
          subtitle: 'PNG, JPG (max. 5MB)',
          image: _frontImage,
          onTap: () => _pickImage('front'),
        ),
        const SizedBox(height: 24),
        const KycSectionHeader(title: 'Citizenship Back (नागरिकताको पछाडि)'),
        const SizedBox(height: 12),
        PhotoUploadBox(
          title: 'Upload Back',
          subtitle: 'PNG, JPG (max. 5MB)',
          image: _backImage,
          onTap: () => _pickImage('back'),
        ),
        const SizedBox(height: 24),
        const KycSectionHeader(title: 'Your Selfie (तपाईंको अनुहारको सेल्फी)'),
        const SizedBox(height: 12),
        PhotoUploadBox(
          title: 'Upload Selfie',
          subtitle: 'A clear photo of your face',
          image: _selfieImage,
          onTap: () => _pickImage('selfie'),
          isSelfie: true,
        ),
        const SizedBox(height: 32),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _currentStep = 1),
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 16,
              color: Colors.grey[600],
            ),
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.brandColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[200],
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Submit Verification',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
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
          colors: [AppTheme.brandColor, AppTheme.brandColor.withOpacity(0.85)],
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 4,
              24,
              20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'VERIFY IDENTITY',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
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
                    Expanded(child: _buildStepperIndicator(_currentStep >= 1)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStepperIndicator(_currentStep >= 2)),
                  ],
                ),
              ],
            ),
          ),

          Positioned(
            left: 16,
            top: MediaQuery.of(context).padding.top + 14,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),

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

  Widget _buildStepperIndicator(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 4,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildLocationVerification() {
    final bool isVerified = _latitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KycSectionHeader(title: 'Location Verification (लोकेसन)'),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: isVerified || _isLocating ? null : _detectLocation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isVerified ? Colors.green.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isVerified
                    ? Colors.green.withOpacity(0.5)
                    : AppTheme.brandColor.withOpacity(0.3),
                width: isVerified ? 1.5 : 2.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? Colors.green
                        : AppTheme.brandColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: _isLocating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppTheme.brandColor,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Icon(
                          isVerified
                              ? Icons.my_location_rounded
                              : Icons.fingerprint_rounded,
                          color: isVerified
                              ? Colors.white
                              : AppTheme.brandColor,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isVerified ? 'GPS Verified' : 'Tap to Verify Location',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isVerified
                              ? Colors.green[800]
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isVerified
                            ? '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                            : 'Required for security (लोकेसन दिनुहोस्)',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isVerified && !_isLocating)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.brandColor,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandColor.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.touch_app_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tap',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
