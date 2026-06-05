import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/services/khozna_ai_service.dart';
import 'package:khozna/features/property/widgets/add_property_widgets.dart';
import 'package:khozna/features/property/repositories/property_repository.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  int _currentStep = 0;
  final int _totalSteps = 8;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController();
  final ScrollController _mainScrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  late ConfettiController _confettiController;

  // Form State
  final TextEditingController _otherCategoryController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _priceNightController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _bedroomsController = TextEditingController();
  final TextEditingController _bathroomsController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _sqftController = TextEditingController();
  final TextEditingController _videoCaptionController = TextEditingController();

  // Payout State
  String _selectedPayoutMethod = 'esewa';
  String _selectedBank = 'Nepal Bank Ltd.';
  final TextEditingController _payoutAccountController =
      TextEditingController();
  File? _payoutQrImage;

  final List<String> _nepaliBanks = [
    'Nepal Bank Ltd.',
    'Rastriya Banijya Bank',
    'Nabil Bank',
    'Investment Mega Bank',
    'Standard Chartered Bank',
    'Himalayan Bank',
    'Nepal SBI Bank',
    'Everest Bank',
    'NIC Asia Bank',
    'Machhapuchhre Bank',
    'Kumari Bank',
    'Laxmi Sunrise Bank',
    'Siddhartha Bank',
    'Global IME Bank',
    'Citizens Bank International',
    'Prime Commercial Bank',
    'NMB Bank',
    'Prabhu Bank',
    'Sanima Bank',
  ];

  // Location State
  bool _isLocating = false;
  double? _latitude;
  double? _longitude;

  // Selected Data State
  String? _selectedCategory = 'Room';
  bool _isNegotiable = true;
  final List<String> _selectedAmenities = [];
  final List<String> _selectedRules = [];
  final List<File> _selectedImages = [];
  File? _selectedVideo;
  bool _isPublishing = false;

  // AI & Checks
  final KhoznaAiService _aiService = KhoznaAiService();
  final bool _isEstimatingPrice = false;
  String? _aiPriceSuggestion;
  final double _distanceFromLandmark = 0.0;
  final bool _isDistanceVerified = false;
  final bool _isAnalyzingLocation = false;
  bool _isGeneratingDescription = false;
  final bool _isGeneratingVideoCaption = false;
  bool _showLocationNudge = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _loadExistingPayoutDetails();
  }

  Future<void> _loadExistingPayoutDetails() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('esewa_number')
          .eq('id', user.id)
          .maybeSingle();
      if (profile != null && profile['esewa_number'] != null) {
        _payoutAccountController.text = profile['esewa_number'];
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _otherCategoryController.dispose();
    _titleController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _priceController.dispose();
    _priceNightController.dispose();
    _descriptionController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _floorController.dispose();
    _sqftController.dispose();
    _payoutAccountController.dispose();
    _videoCaptionController.dispose();
    _pageController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  void _toggleAmenity(String amenity) {
    setState(() {
      if (_selectedAmenities.contains(amenity)) {
        _selectedAmenities.remove(amenity);
      } else {
        _selectedAmenities.add(amenity);
      }
    });
  }

  void _toggleRule(String rule) {
    setState(() {
      if (_selectedRules.contains(rule)) {
        _selectedRules.remove(rule);
      } else {
        _selectedRules.add(rule);
      }
    });
  }

  void _updateCount(TextEditingController controller, int delta) {
    int current = int.tryParse(controller.text) ?? 0;
    int next = current + delta;
    if (next < 0) next = 0;
    if (next > 20) next = 20;
    setState(() => controller.text = next.toString());
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (images.isNotEmpty) {
      setState(() => _selectedImages.addAll(images.map((x) => File(x.path))));
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) setState(() => _selectedVideo = File(video.path));
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
            SnackBar(
              content: Text(
                'कृपया सेटिङ्सबाट लोकेशन अन गर्नुहोस्।',
                style: GoogleFonts.notoSansDevanagari(fontWeight: FontWeight.w600),
              ),
            ),
          );
        }
        setState(() => _isLocating = false);
        return;
      }
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'एआईले तपाईंको ठाउँ खोज्दैछ... 🤖',
              style: GoogleFonts.notoSansDevanagari(fontWeight: FontWeight.w600),
            ),
          ),
        );
        final locData = await _aiService.autoDetectLocationArea(
          position.latitude,
          position.longitude,
        );
        if (mounted) {
          setState(() {
            if (locData['area']?.isNotEmpty == true) {
              _areaController.text = locData['area']!;
            }
            if (locData['landmark']?.isNotEmpty == true) {
              _landmarkController.text = locData['landmark']!;
            }
            _isLocating = false;
          });
        }
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

  void _nextStep() {
    bool isValid = false;
    String errorMessage = '';
    FocusScope.of(context).unfocus();

    switch (_currentStep) {
      case 0:
        if (_selectedCategory == null) {
          errorMessage = 'कृपया सम्पत्तिको प्रकार छान्नुहोस्।';
        } else if (_selectedCategory == 'Other' && _otherCategoryController.text.trim().isEmpty) {
          errorMessage = 'कृपया सम्पत्तिको प्रकार लेख्नुहोस्।';
        } else {
          isValid = true;
        }
        break;
      case 1:
        if (_areaController.text.trim().isEmpty) {
          errorMessage = 'कृपया टोलको नाम राख्नुहोस्।';
        } else if (_landmarkController.text.trim().isEmpty)
          errorMessage = 'कृपया नजिकैको प्रख्यात ठाउँ राख्नुहोस्।';
        else if (_latitude == null) {
          setState(() => _showLocationNudge = true);
          errorMessage = 'कृपया नक्सामा लोकेशन सेट गर्नुहोस्।';
        } else
          isValid = true;
        break;
      case 2:
        isValid = true; // Basics
        break;
      case 3:
        isValid = true; // Amenities
        break;
      case 4: // Pricing (Step 5)
        if (_priceController.text.trim().isEmpty &&
            _priceNightController.text.trim().isEmpty) {
          errorMessage = 'कृपया मासिक वा दैनिक भाडा राख्नुहोस्।';
        } else {
          isValid = true;
        }
        break;
      case 5: // Photos (Step 6)
        if (_selectedImages.length < 5) {
          errorMessage = 'कृपया कम्तिमा ५ वटा फोटोहरू राख्नुहोस्।';
        } else {
          isValid = true;
        }
        break;
      case 6: // Marketing (Title + Video + Desc)
        if (_titleController.text.trim().isEmpty) {
          errorMessage = 'कृपया एउटा आकर्षक शीर्षक राख्नुहोस्।';
        } else {
          isValid = true;
        }
        break;
      case 7: // Payout
        if (_payoutAccountController.text.trim().isEmpty) {
          errorMessage = 'कृपया आफ्नो पेमेन्ट खाता नम्बर राख्नुहोस्।';
        } else {
          isValid = true;
        }
        break;
    }

    if (isValid) {
      if (_currentStep < _totalSteps - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep++);
      } else {
        _publishProperty();
      }
    } else if (errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: GoogleFonts.notoSansDevanagari(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _publishProperty() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _isPublishing = true);

    try {
      // 1. Upload Payout Screenshot if exists
      String? qrUrl;
      if (_payoutQrImage != null) {
        final cloudinary = CloudinaryService();
        qrUrl = await cloudinary.uploadImage(_payoutQrImage!.path);
      }

      // 2. Update Profile with Payout Details
      Map<String, dynamic> payoutUpdates = {
        'selected_payout_method': _selectedPayoutMethod,
      };

      if (_selectedPayoutMethod == 'esewa') {
        payoutUpdates['esewa_number'] = _payoutAccountController.text.trim();
      } else if (_selectedPayoutMethod == 'khalti') {
        payoutUpdates['khalti_number'] = _payoutAccountController.text.trim();
      } else if (_selectedPayoutMethod == 'bank') {
        payoutUpdates['bank_name'] = _selectedBank;
        payoutUpdates['bank_account_number'] = _payoutAccountController.text.trim();
      }
      
      if (qrUrl != null) {
        payoutUpdates['qr_code_url'] = qrUrl;
      }

      await Supabase.instance.client
          .from('profiles')
          .update(payoutUpdates)
          .eq('id', user.id);

      // 3. Create Property
      await PropertyRepository.createProperty(
        title: _titleController.text,
        category: (_selectedCategory == 'Other' ? _otherCategoryController.text.trim() : _selectedCategory) ?? 'Room',
        areaName: _areaController.text,
        landmark: _landmarkController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        bedrooms: int.tryParse(_bedroomsController.text) ?? 0,
        bathrooms: int.tryParse(_bathroomsController.text) ?? 0,
        floor: _floorController.text,
        sqFt: _sqftController.text,
        isNegotiable: _isNegotiable,
        amenities: _selectedAmenities,
        houseRules: _selectedRules,
        images: _selectedImages,
        description: _descriptionController.text,
        latitude: _latitude,
        longitude: _longitude,
        videoFile: _selectedVideo,
        videoCaption: _videoCaptionController.text.trim(),
        priceNight: double.tryParse(_priceNightController.text) ?? 0.0,
        priceMonth: double.tryParse(_priceController.text) ?? 0.0,
      );

      _confettiController.play();
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PropertySuccessScreen(
              ownerName: user.userMetadata?['full_name'] ?? 'Owner',
              title: _titleController.text,
              area: _areaController.text,
              landmark: _landmarkController.text,
              category: (_selectedCategory == 'Other' ? _otherCategoryController.text.trim() : _selectedCategory) ?? 'Property',
              price: _priceController.text,
              submittedAt: DateTime.now(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Publishing failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: null,
        centerTitle: true,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.black87,
                size: 18,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                   // Background track
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.withOpacity(0.1)),
                    ),
                   ),
                  // Active progress
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: (_currentStep + 1) / _totalSteps),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutBack,
                      builder: (context, value, _) => CircularProgressIndicator(
                        value: value,
                        strokeWidth: 2.5,
                        strokeCap: StrokeCap.round,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                      ),
                    ),
                  ),
                  Text(
                    '${_currentStep + 1}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF16A34A),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sleek Progress Line
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: (_currentStep + 1) / _totalSteps),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                backgroundColor: const Color(0xFF22C55E).withOpacity(0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                minHeight: 3.0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              children: [
                PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStepCategory(),
                    _buildStepLocation(),
                    _buildStepBasics(),
                    _buildStepAmenities(),
                    _buildStepPricingRules(),
                    _buildStepPhotos(),
                    _buildStepMarketing(),
                    _buildStepPayout(),
                  ],
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStepCategory() {
    return StepLayout(
      controller: _mainScrollController,
      title: 'सम्पत्तिको प्रकार?',
      titleWidget: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            'सम्पत्तिको प्रकार?',
            style: GoogleFonts.notoSansDevanagari(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Property type',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
      subtitle: '',
      content: [
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
          children: [
            CategoryCard(
              label: 'कोठा / Room',
              imagePath: 'assets/images/Room New.png',
              value: 'Room',
              imageScale: 1.6,
              selectedValue: _selectedCategory,
              onSelect: (v) {
                setState(() => _selectedCategory = v);
                HapticFeedback.mediumImpact();
                Future.delayed(const Duration(milliseconds: 300), () => _nextStep());
              },
            ),
            CategoryCard(
              label: 'फ्ल्याट / Flat',
              imagePath: 'assets/images/flat (2).png',
              value: 'Flat',
              imageScale: 1.5,
              selectedValue: _selectedCategory,
              onSelect: (v) {
                setState(() => _selectedCategory = v);
                HapticFeedback.mediumImpact();
                Future.delayed(const Duration(milliseconds: 300), () => _nextStep());
              },
            ),
            CategoryCard(
              label: 'कटेज / Cottage',
              imagePath: 'assets/images/cottage (2).png',
              value: 'Cottage',
              imageScale: 1.5,
              selectedValue: _selectedCategory,
              onSelect: (v) {
                setState(() => _selectedCategory = v);
                HapticFeedback.mediumImpact();
                Future.delayed(const Duration(milliseconds: 300), () => _nextStep());
              },
            ),
            CategoryCard(
              label: 'होस्टल / Hostel',
              imagePath: 'assets/images/Hotel.png',
              value: 'Hostel',
              imageScale: 1.5,
              selectedValue: _selectedCategory,
              onSelect: (v) {
                setState(() => _selectedCategory = v);
                HapticFeedback.mediumImpact();
                Future.delayed(const Duration(milliseconds: 300), () => _nextStep());
              },
            ),
            CategoryCard(
              label: 'अन्य / Other',
              imagePath: 'assets/images/other image.png',
              value: 'Other',
              imageScale: 1.1,
              selectedValue: _selectedCategory,
              onSelect: (v) async {
                HapticFeedback.lightImpact();
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const OtherCategoryScreen()),
                );
                if (result != null && result.isNotEmpty) {
                  setState(() {
                    _selectedCategory = 'Other';
                    _otherCategoryController.text = result;
                  });
                  Future.delayed(const Duration(milliseconds: 300), () => _nextStep());
                }
              },
            ),
          ],
        ),
        if (_selectedCategory == 'Other') ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.brandColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.brandColor.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppTheme.brandColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Type',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.brandColor.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        _otherCategoryController.text,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.brandColor,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final result = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(builder: (_) => const OtherCategoryScreen()),
                    );
                    if (result != null && result.isNotEmpty) {
                      setState(() => _otherCategoryController.text = result);
                    }
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepLocation() {
    return StepLayout(
      title: 'स्थान छान्नुहोस्',
      titleWidget: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            'स्थान छान्नुहोस्',
            style: GoogleFonts.notoSansDevanagari(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Location',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
      subtitle: 'सही लोकेसनले ग्राहकलाई तपाईंको कोठा भेटाउन सजिलो बनाउँछ।',
      content: [
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9), // Light grayish for map background
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Custom map lines background
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: CustomPaint(
                    painter: _MapPatternPainter(),
                  ),
                ),
              ),
              // Location pin in center
              Positioned(
                top: 40,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brandColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.home_rounded, color: Colors.white, size: 28),
                ),
              ),
              // The bottom card
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.brandColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.gps_fixed_rounded, color: AppTheme.brandColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'हालको स्थान प्रयोग गर्नुहोस्',
                                  style: GoogleFonts.notoSansDevanagari(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'GPS प्रयोग गर्दा तपाईंको सूचीमा विश्वास बढ्छ र ग्राहकलाई सजिलो भेटिन्छ।',
                                  style: GoogleFonts.notoSansDevanagari(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_showLocationNudge && _latitude == null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'कृपया नक्सामा लोकेशन सेट गर्नुहोस्!',
                            style: GoogleFonts.notoSansDevanagari(
                              color: Colors.orange[800],
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isLocating
                              ? null
                              : () {
                                  setState(() => _showLocationNudge = false);
                                  _detectLocation();
                                },
                          icon: _isLocating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Icon(
                                  _latitude != null ? Icons.check_circle_outline_rounded : Icons.near_me_outlined, 
                                  size: 18, 
                                  color: Colors.white
                                ),
                          label: Text(
                            _isLocating ? 'खोज्दै छ...' : (_latitude != null ? 'स्थान प्रमाणित भयो' : 'मेरो हालको स्थान प्रयोग गर्नुहोस्'),
                            style: GoogleFonts.notoSansDevanagari(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _latitude != null ? const Color(0xFF22C55E) : AppTheme.brandColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1.2)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'वा',
                style: GoogleFonts.notoSansDevanagari(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1.2)),
          ],
        ),
        const SizedBox(height: 24),
        PropertyFormField(
          label: 'टोल वा ठाउँको नाम (Area Name)',
          hint: 'उदा: ललितपुर, सानेपा-२',
          controller: _areaController,
          isRequired: true,
          prefixIcon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 24),
        PropertyFormField(
          label: 'चिनिने ठाउँ (Landmark)',
          hint: 'उदा: सिभिल अस्पतालको पछाडि',
          controller: _landmarkController,
          isRequired: true,
          prefixIcon: Icons.business_outlined,
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.brandColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.security_rounded, color: AppTheme.brandColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'आफ्नो ठेगाना सुरक्षित छ। यो जानकारी सार्वजनिक गरिने छैन।',
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 12,
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepBasics() {
    return StepLayout(
      title: 'कोठा र तल्लाको विवरण',
      subtitle: 'बेडरुम, बाथरुम र क्षेत्रफलको जानकारी दिनुहोस्।',
      content: [
        Row(
          children: [
            Expanded(
              child: CounterField(
                label: 'बेडरुम (Beds)',
                icon: Icons.bed_rounded,
                value: _bedroomsController.text,
                onIncrement: () => _updateCount(_bedroomsController, 1),
                onDecrement: () => _updateCount(_bedroomsController, -1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CounterField(
                label: 'बाथरुम (Baths)',
                icon: Icons.shower_rounded,
                value: _bathroomsController.text,
                onIncrement: () => _updateCount(_bathroomsController, 1),
                onDecrement: () => _updateCount(_bathroomsController, -1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FloorSelector(
          label: 'कुन तलामा छ? (Floor Level)',
          selectedFloor: _floorController.text,
          onSelect: (val) => setState(() => _floorController.text = val),
        ),
        const SizedBox(height: 24),
        PropertyFormField(
          label: 'क्षेत्रफल (Total Area sq.ft)',
          hint: 'उदा: ४००',
          controller: _sqftController,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.straighten_rounded,
        ),
        const SizedBox(height: 12),
        QuickSizeSelector(
          currentValue: _sqftController.text,
          onSelect: (val) => setState(() => _sqftController.text = val),
        ),
      ],
    );
  }

  Widget _buildStepAmenities() {
    return StepLayout(
      title: 'के-के सुविधाहरू छन्?',
      subtitle: 'राम्रो सुविधाहरूले धेरै ग्राहक आकर्षित गर्छ।',
      content: [
        AmenitiesGrid(
          selectedItems: _selectedAmenities,
          icons: const {
            'water_24_7': Icons.water_drop_rounded,
            'internet': Icons.wifi_rounded,
            'parking_bike': Icons.motorcycle_rounded,
            'parking_car': Icons.directions_car_rounded,
            'ac': Icons.ac_unit_rounded,
            'furnished': Icons.chair_rounded,
            'attached_bathroom': Icons.bathtub_rounded,
            'kitchen': Icons.kitchen_rounded,
            'hot_water': Icons.hot_tub_rounded,
            'sunny_room': Icons.wb_sunny_rounded,
            'balcony': Icons.balcony_rounded,
            'swimming_pool': Icons.pool_rounded,
            'gym': Icons.fitness_center_rounded,
            'garden': Icons.yard_rounded,
            'cctv': Icons.videocam_rounded,
            'security': Icons.security_rounded,
            'elevator': Icons.elevator_rounded,
            'power_backup': Icons.electric_bolt_rounded,
            'solar': Icons.solar_power_rounded,
            'laundry': Icons.local_laundry_service_rounded,
            'waste_mgmt': Icons.delete_outline_rounded,
            'peaceful': Icons.nature_people_rounded,
            'rooftop': Icons.roofing_rounded,
          },
          labels: const {
            'water_24_7': '२४ सै घण्टा पानी',
            'internet': 'इन्टरनेट (WiFi)',
            'parking_bike': 'बाइक पार्किङ',
            'parking_car': 'कार पार्किङ',
            'ac': 'एसी (AC)',
            'furnished': 'फर्निचर सहित',
            'attached_bathroom': 'एट्याच्ड बाथरुम',
            'kitchen': 'छुट्टै भान्सा',
            'hot_water': 'तातो पानी',
            'sunny_room': 'घाम लाग्ने कोठा',
            'balcony': 'बालकोनी (Balcony)',
            'swimming_pool': 'पौडी पोखरी (Pool)',
            'gym': 'जिम (Gym)',
            'garden': 'बगैचा / Garden',
            'cctv': 'CC क्यामेरा',
            'security': 'सेक्युरिटी गार्ड',
            'elevator': 'लिफ्ट (Elevator)',
            'power_backup': 'पावर ब्याकअप',
            'solar': 'सोलार सुबिधा',
            'laundry': 'लुगा धुने ठाउँ',
            'waste_mgmt': 'फोहोर उठाउने',
            'peaceful': 'शान्त वातावरण',
            'rooftop': 'छत (Rooftop)',
          },
          onToggle: _toggleAmenity,
        ),
      ],
    );
  }

  Widget _buildStepPricingRules() {
    return StepLayout(
      title: 'भाडा र नियमहरू (Pricing & Rules)',
      subtitle: 'मासिक भाडा तोक्नुहोस् र घरका नियमहरू मिलाउनुहोस्।',
      content: [
        // ── Pricing Section ────────────────────────────────────────────────
        PriceInputField(
          label: 'मासिक भाडा (Monthly Rent)',
          controller: _priceController,
          suffix: 'Per Month',
        ),
        const SizedBox(height: 20),
        PriceInputField(
          label: 'प्रति रात भाडा (Price Per Night)',
          controller: _priceNightController,
          suffix: 'Optional',
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() => _isNegotiable = !_isNegotiable);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _isNegotiable ? AppTheme.brandColor.withOpacity(0.04) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isNegotiable ? AppTheme.brandColor : const Color(0xFFE2E8F0),
                width: _isNegotiable ? 2 : 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isNegotiable ? AppTheme.brandColor : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.handshake_rounded,
                    color: _isNegotiable ? Colors.white : Colors.grey[400],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'भाडा मिलाउन सकिने (Negotiable)',
                        style: GoogleFonts.notoSansDevanagari(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'भाडामा मोलमोलाई गर्न मिल्ने छ।',
                        style: GoogleFonts.notoSansDevanagari(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _isNegotiable,
                  onChanged: (v) {
                    HapticFeedback.mediumImpact();
                    setState(() => _isNegotiable = v);
                  },
                  activeColor: AppTheme.brandColor,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 48),

        // ── Rules Section ──────────────────────────────────────────────────
        Row(
          children: [
            const Icon(Icons.rule_folder_rounded, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              'घरका नियमहरू (House Rules)',
              style: GoogleFonts.notoSansDevanagari(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AmenitiesGrid(
          selectedItems: _selectedRules,
          icons: const {
            'family_only': Icons.family_restroom_rounded,
            'boys_allowed': Icons.man_rounded,
            'girls_allowed': Icons.woman_rounded,
            'pets_allowed': Icons.pets_rounded,
            'smoking_allowed': Icons.smoke_free_rounded,
            'alcohol_allowed': Icons.local_bar_rounded,
          },
          labels: const {
            'family_only': 'परिवार मात्र',
            'boys_allowed': 'केटा मात्र',
            'girls_allowed': 'केटी मात्र',
            'pets_allowed': 'जनावर राख्न पाईने',
            'smoking_allowed': 'चुरोट पिउन पाईने',
            'alcohol_allowed': 'मदिरा पिउन पाईने',
          },
          onToggle: _toggleRule,
        ),
      ],
    );
  }

  Widget _buildStepPhotos() {
    final int photoCount = _selectedImages.length;
    final double progress = (photoCount / 5).clamp(0.0, 1.0);
    final bool isGoalMet = photoCount >= 5;

    return StepLayout(
      title: 'फोटोहरू थप्नुहोस् (Add Photos)',
      subtitle: 'राम्रो उज्यालोमा खिचिएका फोटोहरू प्रयोग गर्नुहोस्।',
      content: [
        // ── Photo Progress Tracker ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isGoalMet ? const Color(0xFF22C55E).withOpacity(0.3) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isGoalMet ? const Color(0xFF22C55E) : AppTheme.brandColor).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isGoalMet ? Icons.check_circle_rounded : Icons.photo_library_rounded,
                          color: isGoalMet ? const Color(0xFF22C55E) : AppTheme.brandColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isGoalMet ? 'फोटो पुग्यो! ✓' : 'फोटो: $photoCount / ५',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: isGoalMet ? const Color(0xFF16A34A) : const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  if (photoCount > 0)
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: isGoalMet ? const Color(0xFF22C55E) : AppTheme.brandColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isGoalMet ? const Color(0xFF22C55E) : AppTheme.brandColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        DottedBorder(
          options: RoundedRectDottedBorderOptions(
            radius: const Radius.circular(24),
            strokeWidth: 2,
            color: AppTheme.brandColor.withOpacity(0.3),
            dashPattern: const [8, 4],
            padding: EdgeInsets.zero,
          ),
          child: GestureDetector(
            onTap: _pickImages,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: AppTheme.brandColor.withOpacity(0.04),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_rounded,
                        color: AppTheme.brandColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'फोटो अपलोड गर्नुहोस्',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppTheme.brandColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'कम्तिमा ५ वटा फोटो राख्नुहोस्',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 32),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.grey, size: 16),
              const SizedBox(width: 8),
              Text(
                'फोटो थिचेर सार्नुहोस् — पहिलो फोटो मुख्य कभर हुनेछ',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ReorderableGridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _selectedImages.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                final item = _selectedImages.removeAt(oldIndex);
                _selectedImages.insert(newIndex, item);
              });
              HapticFeedback.mediumImpact();
            },
            itemBuilder: (context, index) {
              return ClipRRect(
                key: ValueKey(_selectedImages[index].path),
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_selectedImages[index], fit: BoxFit.cover),
                    // Glass Overlay for Main Photo
                    if (index == 0)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF22C55E).withOpacity(0.8),
                                const Color(0xFF22C55E).withOpacity(0.0),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'मुख्य कभर',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Delete Button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImages.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                    // Multi-select Indicator
                    if (index == 0)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStepMarketing() {
    return StepLayout(
      title: 'अन्तिम सजावट (Final Touches)',
      subtitle: 'आफ्नो विज्ञापनलाई अझ आकर्षक बनाउनुहोस्।',
      content: [
        // ── Title Section ──────────────────────────────────────────────────
        Text(
          'एक राम्रो शीर्षक छान्नुहोस् (Property Title)',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSmartTitleChip('कोठा भाडामा (Room for Rent)'),
            _buildSmartTitleChip('बबाल फ्ल्याट (Awesome Flat)'),
            _buildSmartTitleChip('Best Place in ${_areaController.text}'),
            _buildSmartTitleChip('Beautiful Room near ${_landmarkController.text}'),
          ],
        ),
        const SizedBox(height: 20),
        PropertyFormField(
          label: 'शीर्षक (Title)',
          hint: 'उदा: सानेपामा राम्रो कोठा भाडामा',
          controller: _titleController,
          isRequired: true,
          prefixIcon: Icons.title_rounded,
        ),
        const SizedBox(height: 40),

        // ── Video Section ──────────────────────────────────────────────────
        Row(
          children: [
            const Icon(Icons.videocam_rounded, color: Colors.redAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              'भिडियो राख्नुहोस् (Upload Reel)',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickVideo,
          child: _buildMediaUploadBox(
            icon: Icons.videocam_outlined,
            title: _selectedVideo != null
                ? 'भिडियो छानियो ✓'
                : 'Upload Property Reel',
            desc: _selectedVideo != null
                ? 'भिडियो परिवर्तन गर्न क्लिक गर्नुहोस्'
                : 'भिडियो राख्दा ३ गुणा बढी ग्राहक आउँछन्!',
            isBlue: true,
            hasFile: _selectedVideo != null,
          ),
        ),
        if (_selectedVideo != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.video_file, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Video: ${_selectedVideo!.path.split('/').last}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.blue[900],
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 22),
                  onPressed: () => setState(() => _selectedVideo = null),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 40),

        // ── Description Section ──────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: AppTheme.brandColor.withOpacity(0.05),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppTheme.brandColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Professional Description',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppTheme.brandColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _descriptionController,
                      maxLines: 5,
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 15,
                        color: const Color(0xFF1F2937),
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'आफ्नो प्रोपर्टीको बारेमा केही लेख्नुहोस्...',
                        hintStyle: GoogleFonts.notoSansDevanagari(color: Colors.grey[400], fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isGeneratingDescription
                            ? null
                            : () async {
                                HapticFeedback.mediumImpact();
                                setState(() => _isGeneratingDescription = true);
                                  final desc = await _aiService.generateDescription(
                                    title: _titleController.text,
                                    category: _selectedCategory ?? 'Room',
                                    area: _areaController.text,
                                    landmark: _landmarkController.text,
                                    price: _priceController.text,
                                    priceNight: _priceNightController.text,
                                    bedrooms: _bedroomsController.text,
                                    bathrooms: _bathroomsController.text,
                                    floor: _floorController.text,
                                    sqft: _sqftController.text,
                                    isNegotiable: _isNegotiable,
                                    amenities: [..._selectedAmenities, ..._selectedRules],
                                  );
                                setState(() {
                                  _descriptionController.text = desc;
                                  _isGeneratingDescription = false;
                                });
                              },
                        icon: _isGeneratingDescription 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_fix_high_rounded, size: 18),
                        label: Text(
                          _isGeneratingDescription ? 'लेख्दै छ...' : 'AI ले विवरण लेख्नुहोस्',
                          style: GoogleFonts.notoSansDevanagari(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSmartTitleChip(String title) {
    bool isSelected = _titleController.text == title;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _titleController.text = title);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.brandColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  size: 14, color: AppTheme.brandColor),
            if (isSelected) const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppTheme.brandColor : const Color(0xFF4B5563),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBankPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Your Bank',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _nepaliBanks.length,
                itemBuilder: (context, index) {
                  final bank = _nepaliBanks[index];
                  bool isSelected = _selectedBank == bank;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    title: Text(
                      bank,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? AppTheme.brandColor : Colors.black87,
                      ),
                    ),
                    trailing: isSelected 
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.brandColor)
                      : null,
                    onTap: () {
                      setState(() => _selectedBank = bank);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPayoutImage() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        HapticFeedback.mediumImpact();
        setState(() {
          _payoutQrImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Widget _buildStepPayout() {
    return StepLayout(
      title: 'भुक्तानी विवरण (Payout Details)',
      subtitle: 'आफुले पैसा प्राप्त गर्ने भुक्तानी पद्धति रोज्नुहोस्।',
      content: [
        const SizedBox(height: 24),

        // ── Payout Method Selection ──────────────────────────────────────────
        PremiumFeatureCard(
          icon: Icons.account_balance_wallet_rounded,
          title: 'भुक्तानी पद्धति',
          subtitle: 'Choose your preferred payout method',
          accentColor: AppTheme.brandColor,
          child: Column(
            children: [
              Row(
                children: [
                   _buildPayoutTypeSelector('eSewa', 'esewa', Icons.account_balance_wallet_rounded, const Color(0xFF60BB46), 'assets/images/esewa.webp'),
                  const SizedBox(width: 8),
                  _buildPayoutTypeSelector('Khalti', 'khalti', Icons.account_balance_wallet_rounded, const Color(0xFF5C2D91), 'assets/images/khalti.png'),
                  const SizedBox(width: 8),
                  _buildPayoutTypeSelector('Bank', 'bank', Icons.account_balance_rounded, Colors.blue),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),

        // ── Bank Name Selector (Only if Bank Method is chosen) ───────────────
        if (_selectedPayoutMethod == 'bank') ...[
          GestureDetector(
            onTap: _showBankPicker,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'बैंकको नाम (Bank Name)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          _selectedBank,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Account Number Input ─────────────────────────────────────────────
        PropertyFormField(
          label: _selectedPayoutMethod == 'bank' 
            ? 'खाता वा फोन नम्बर (Account or Phone Number)'
            : '${_selectedPayoutMethod == 'esewa' ? 'eSewa' : 'Khalti'} नम्बर (Number)',
          hint: _selectedPayoutMethod == 'bank' 
            ? 'Enter account or mobile number'
            : 'Enter mobile number',
          controller: _payoutAccountController,
          isRequired: true,
          keyboardType: TextInputType.text,
          prefixIcon: _selectedPayoutMethod == 'bank' ? Icons.numbers_rounded : Icons.phone_android_rounded,
        ),
        
        const SizedBox(height: 24),

        // ── Screenshot Upload (User Request) ─────────────────────────────────
        GestureDetector(
          onTap: _pickPayoutImage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _payoutQrImage != null ? AppTheme.brandColor : Colors.grey.shade200,
                width: 1.5,
                style: _payoutQrImage != null ? BorderStyle.solid : BorderStyle.none,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _payoutQrImage != null ? AppTheme.brandColor.withOpacity(0.1) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _payoutQrImage != null ? Icons.check_circle_rounded : Icons.add_photo_alternate_rounded,
                    color: _payoutQrImage != null ? AppTheme.brandColor : Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _payoutQrImage != null ? 'Screenshot Added' : 'Add Screenshot (Optional)',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Upload QR or Bank details screenshot',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_payoutQrImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_payoutQrImage!, width: 40, height: 40, fit: BoxFit.cover),
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildPayoutTypeSelector(
    String title,
    String type,
    IconData icon,
    Color color, [
    String? assetIcon,
  ]) {
    bool isSelected = _selectedPayoutMethod == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedPayoutMethod = type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.06) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (assetIcon != null)
                Image.asset(
                  assetIcon,
                  height: 20,
                  width: 20,
                  fit: BoxFit.contain,
                )
              else
                Icon(icon, color: isSelected ? color : Colors.grey[500], size: 20),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: isSelected ? color : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaUploadBox({
    required IconData icon,
    required String title,
    required String desc,
    required bool isBlue,
    bool hasFile = false,
  }) {
    Color activeColor = isBlue ? Colors.blue : AppTheme.brandColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: hasFile
            ? activeColor.withOpacity(0.04)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: hasFile ? activeColor : const Color(0xFFE5E7EB),
          width: hasFile ? 2.5 : 1.5,
        ),
      ),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: hasFile ? activeColor : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (hasFile ? activeColor : Colors.black).withOpacity(
                    0.08,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              hasFile ? Icons.check_rounded : icon,
              color: hasFile ? Colors.white : Colors.grey[400],
              size: 34,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansDevanagari(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansDevanagari(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    bool isLastStep = _currentStep == (_totalSteps - 1);
    
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
        ),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    setState(() => _currentStep--);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4B5563),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: isLastStep
                    ? (_isPublishing ? null : _nextStep)
                    : () {
                        HapticFeedback.mediumImpact();
                        _nextStep();
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: _isPublishing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastStep ? 'Publish' : 'Next',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLastStep ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
                            size: 18,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Horizontal-ish lines
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.2, size.width, size.height * 0.4);

    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.8, size.width, size.height * 0.6);

    // Vertical-ish lines
    path.moveTo(size.width * 0.3, 0);
    path.quadraticBezierTo(size.width * 0.4, size.height * 0.5, size.width * 0.2, size.height);

    path.moveTo(size.width * 0.7, 0);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.5, size.width * 0.8, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OtherCategoryScreen extends StatefulWidget {
  const OtherCategoryScreen({super.key});

  @override
  State<OtherCategoryScreen> createState() => _OtherCategoryScreenState();
}

class _OtherCategoryScreenState extends State<OtherCategoryScreen> {
  final TextEditingController _customController = TextEditingController();
  final List<String> _suggestions = [
    'Villa',
    'Hotel',
    'Office Space',
    'Shutter',
    'Godown/Warehouse',
    'Farm House',
    'Event Hall',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'अन्य सङ्कुल (Other Type)',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What type of property is this?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Specify the exact type for better matching.',
              style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _customController,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Enter property type...',
                hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(20),
                prefixIcon: const Icon(Icons.edit_note_rounded, color: AppTheme.brandColor),
              ),
              onSubmitted: (v) {
                if (v.isNotEmpty) Navigator.pop(context, v);
              },
            ),
            const SizedBox(height: 40),
            Text(
              'Suggestions',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey[400],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _suggestions.map((s) => InkWell(
                onTap: () => Navigator.pop(context, s),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    s,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton(
            onPressed: () {
              if (_customController.text.isNotEmpty) {
                Navigator.pop(context, _customController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: Text(
              'Confirm Type',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
