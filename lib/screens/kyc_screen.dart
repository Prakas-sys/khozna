import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

// Method channel for security (blocks screenshots on KYC screen)
const _channel = MethodChannel('khozna/security');

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _citizenshipController = TextEditingController();
  
  bool _isSubmitting = false;
  bool _isLocating = false;
  double? _latitude;
  double? _longitude;

  File? _frontImage;
  File? _backImage;
  File? _selfieImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _setSecureScreen(true);
  }

  @override
  void dispose() {
    _setSecureScreen(false);
    _nameController.dispose();
    _phoneController.dispose();
    _citizenshipController.dispose();
    super.dispose();
  }

  Future<void> _setSecureScreen(bool secure) async {
    try {
      await _channel.invokeMethod('setSecure', secure);
    } catch (_) {}
  }

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
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

    setState(() => _isSubmitting = true);
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // PREMIUM BLUE CONTEXT HEADER
          _buildPremiumHeader(),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LOCATION VERIFICATION CARD
                    _buildLocationCard(),
                    const SizedBox(height: 32),

                    // DOCUMENT SECTION
                    _buildSectionHeader('Citizenship Front (नागरिकताको अगाडि)', true),
                    const SizedBox(height: 12),
                    _buildPhotoUploadBox('front', 'Upload Front (अगाडि राख्नुहोस्)', 'PNG, JPG (max. 5MB)', _frontImage),
                    
                    const SizedBox(height: 32),
                    _buildSectionHeader('Citizenship Back (नागरिकताको पछाडि)', true),
                    const SizedBox(height: 12),
                    _buildPhotoUploadBox('back', 'Upload Back (पछाडि राख्नुहोस्)', 'PNG, JPG (max. 5MB)', _backImage),
                    
                    const SizedBox(height: 32),
                    _buildSectionHeader('Selfie with Document (नागरिकता समातेको सेल्फी)', true),
                    const SizedBox(height: 12),
                    _buildPhotoUploadBox('selfie', 'Upload Selfie (सेल्फी राख्नुहोस्)', 'Hold ID clearly (नागरिकता हातमा लिएर)', _selfieImage, isSelfie: true),

                    const SizedBox(height: 48),
                    
                    // SUBMIT BUTTON
                    _buildSubmitButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 54, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0099E5), Color(0xFF00B4F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Verify Your Identity (पहचान प्रमाणित गर्नुहोस्)',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Required to post properties (घर जगा राख्नको लागि अनिवार्य)',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildStepperIndicator(true)),
              const SizedBox(width: 8),
              Expanded(child: _buildStepperIndicator(false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperIndicator(bool active) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F1F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFECECEC), style: BorderStyle.none),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _latitude != null ? Icons.location_on : Icons.my_location_rounded,
                    color: _latitude != null ? Colors.green : Colors.grey[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _latitude != null ? 'Location Verified!' : 'Detect Location (लोकेसन पत्ता लगाउनुहोस्)',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _latitude != null 
                          ? 'GPS: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                          : 'Required for security (सुरक्षाका लागि आवश्यक)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF9E9E9E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLocating ? null : _detectLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B4F5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    minimumSize: const Size(100, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLocating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _latitude != null ? 'Verified (प्रमाणित)' : 'Verify Location (प्रमाणित)',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool required) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        if (required)
          const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPhotoUploadBox(String type, String title, String subtitle, File? image, {bool isSelfie = false}) {
    return GestureDetector(
      onTap: () => _pickImage(type),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: image != null ? Colors.green.withOpacity(0.5) : const Color(0xFFECECEC),
            width: 1.5,
            style: image != null ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: image != null
            ? Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(image, height: 120, width: 200, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Uploaded Successfully',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B4F5).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSelfie ? Icons.camera_alt_outlined : Icons.file_upload_outlined,
                      color: const Color(0xFF00B4F5),
                      size: 28,
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
                      color: const Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0099E5), Color(0xFF00B4F5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B4F5).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (_isSubmitting) ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isSubmitting
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
          : Text(
              'Submit Verification (सबमिट गर्नुहोस्)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
      ),
    );
  }
}
