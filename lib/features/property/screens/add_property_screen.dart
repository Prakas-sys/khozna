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
import 'package:khozna/core/services/cloudinary_service.dart';
import 'package:khozna/core/services/upload_manager.dart';

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
  final TextEditingController _bedroomsController = TextEditingController();
  final TextEditingController _bathroomsController = TextEditingController();
  final TextEditingController _guestsController = TextEditingController(text: '1');
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
  final bool _isGeneratingVideoCaption = false;
  bool _showLocationNudge = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    UploadManager.instance.addListener(_onUploadStatusChanged);
    _loadExistingPayoutDetails();
  }

  void _onUploadStatusChanged() {
    if (mounted) setState(() {});
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
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _guestsController.dispose();
    _floorController.dispose();
    _sqftController.dispose();
    _payoutAccountController.dispose();
    _videoCaptionController.dispose();
    _pageController.dispose();
    _mainScrollController.dispose();
    UploadManager.instance.removeListener(_onUploadStatusChanged);
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
      final newFiles = images.map((x) => File(x.path)).toList();
      setState(() => _selectedImages.addAll(newFiles));
      // Start background uploads immediately
      for (var file in newFiles) {
        UploadManager.instance.startUpload(file);
      }
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      final file = File(video.path);
      setState(() => _selectedVideo = file);
      // Start background upload for video (includes compression)
      UploadManager.instance.startUpload(file, isVideo: true);
    }
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
      // 1. Wait for Payout Screenshot if it exists
      String? qrUrl;
      if (_payoutQrImage != null) {
        qrUrl = UploadManager.instance.getUrl(_payoutQrImage!.path);
        if (qrUrl == null) {
          // If not uploaded yet, do it now
          qrUrl = await CloudinaryService.uploadImage(_payoutQrImage!);
        }
      }

      // 2. Update Profile with Payout Details
      Map<String, dynamic> payoutUpdates = {};
      if (_selectedPayoutMethod == 'esewa') {
        payoutUpdates['esewa_number'] = _payoutAccountController.text.trim();
      } else if (_selectedPayoutMethod == 'khalti') {
        payoutUpdates['khalti_number'] = _payoutAccountController.text.trim();
      } else if (_selectedPayoutMethod == 'bank') {
        payoutUpdates['account_holder_name'] = '${_selectedBank}: ${_payoutAccountController.text.trim()}';
      }
      if (qrUrl != null) payoutUpdates['qr_code_url'] = qrUrl;

      if (payoutUpdates.isNotEmpty) {
        await Supabase.instance.client
            .from('profiles')
            .update(payoutUpdates)
            .eq('id', user.id);
      }

      // 3. Collect uploaded media URLs
      // If they are not in UploadManager, they will be uploaded in createProperty (fallback)
      final List<String> preUploadedImageUrls = [];
      for (var file in _selectedImages) {
        final url = UploadManager.instance.getUrl(file.path);
        if (url != null) preUploadedImageUrls.add(url);
      }
      
      final String? preUploadedVideoUrl = _selectedVideo != null 
          ? UploadManager.instance.getUrl(_selectedVideo!.path) 
          : null;

      // 4. Create Property
      await PropertyRepository.createProperty(
        title: _titleController.text,
        category: (_selectedCategory == 'Other' ? _otherCategoryController.text.trim() : _selectedCategory) ?? 'Room',
        areaName: _areaController.text,
        landmark: _landmarkController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        bedrooms: int.tryParse(_bedroomsController.text) ?? 0,
        bathrooms: int.tryParse(_bathroomsController.text) ?? 0,
        guests: int.tryParse(_guestsController.text) ?? 0,
        floor: _floorController.text,
        sqFt: _sqftController.text,
        isNegotiable: _isNegotiable,
        amenities: _selectedAmenities,
        houseRules: _selectedRules,
        images: _selectedImages,
        description: '', // Description removed as requested
        latitude: _latitude,
        longitude: _longitude,
        videoFile: _selectedVideo,
        preUploadedVideoUrl: preUploadedVideoUrl,
        preUploadedImageUrls: preUploadedImageUrls,
        videoCaption: _videoCaptionController.text.trim(),
        priceNight: double.tryParse(_priceNightController.text) ?? 0.0,
        priceMonth: double.tryParse(_priceController.text) ?? 0.0,
      );

      _confettiController.play();
      UploadManager.instance.clear(); // Clear cache after success
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Publishing failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
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
          Flexible(
            child: Text(
              'Property type',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: '',
      content: [
        const SizedBox(height: 8),
        Column(
          children: [
            CategoryCard(
              label: 'कोठा / Room',
              imagePath: 'assets/images/Room New.png',
              value: 'Room',
              imageScale: 1.3,
              selectedValue: _selectedCategory,
              onSelect: (v) {
                setState(() => _selectedCategory = v);
                HapticFeedback.mediumImpact();
              },
            ),
            const SizedBox(height: 12),
            CategoryCard(
              label: 'फ्ल्याट / Flat',
              imagePath: 'assets/images/flat (2).png',
              value: 'Flat',
              imageScale: 1.3,
              selectedValue: _selectedCategory,
              onSelect: (v) {
                setState(() => _selectedCategory = v);
                HapticFeedback.mediumImpact();
              },
            ),
            const SizedBox(height: 12),
            CategoryCard(
              label: 'कटेज / Cottage',
              imagePath: 'assets/images/cottage (2).png',
              value: 'Cottage',
              imageScale: 1.3,
              selectedValue: _selectedCategory,
              onSelect: (v) {
                setState(() => _selectedCategory = v);
                HapticFeedback.mediumImpact();
              },
            ),
            const SizedBox(height: 12),
            CategoryCard(
              label: 'होस्टल / Hostel',
              imagePath: 'assets/images/Hotel.png',
              value: 'Hostel',
              imageScale: 1.3,
              selectedValue: _selectedCategory,
              onSelect: (v) {
                setState(() => _selectedCategory = v);
                HapticFeedback.mediumImpact();
              },
            ),
            const SizedBox(height: 12),
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
      titleWidget: Text(
        'सम्पत्तिको ठेगाना',
        style: GoogleFonts.notoSansDevanagari(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1E293B),
        ),
      ),
      subtitle: 'तपाईंको घर वा कोठा रहेको टोल र मुख्य ठाउँ उल्लेख गर्नुहोस्।',
      content: [
        // Clean GPS Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _latitude != null ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _latitude != null ? Icons.check_circle_rounded : Icons.my_location_rounded,
                    color: _latitude != null ? const Color(0xFF16A34A) : AppTheme.brandColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _latitude != null ? 'GPS स्थान सेभ भयो' : 'हालको GPS स्थान सेभ गर्नुहोस्',
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'नक्सामा सही स्थान जोड्दा ग्राहकलाई तपाईंको सम्पत्ति भेटाउन सजिलो हुन्छ।',
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              if (_showLocationNudge && _latitude == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'कृपया नक्सामा लोकेशन सेट गर्नुहोस्!',
                    style: GoogleFonts.notoSansDevanagari(
                      color: const Color(0xFFDC2626),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _latitude != null ? Icons.verified_rounded : Icons.near_me_rounded,
                          size: 18,
                        ),
                  label: Text(
                    _isLocating
                        ? 'लोकेशन खोज्दै छ...'
                        : (_latitude != null ? 'स्थान प्रमाणित गरियो ✓' : 'मेरो हालको स्थान प्रयोग गर्नुहोस्'),
                    style: GoogleFonts.notoSansDevanagari(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _latitude != null ? const Color(0xFF16A34A) : AppTheme.brandColor,
                    side: BorderSide(
                      color: _latitude != null ? const Color(0xFF16A34A) : AppTheme.brandColor,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Form Fields
        PropertyFormField(
          label: 'टोल वा क्षेत्रको नाम (Area / Tole)',
          hint: 'उदा: ललितपुर, सानेपा-२',
          controller: _areaController,
          isRequired: true,
          prefixIcon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 18),
        PropertyFormField(
          label: 'नजिकैको मुख्य ठाउँ (Landmark)',
          hint: 'उदा: स्टार अस्पताल नजिकै / Civil Bank',
          controller: _landmarkController,
          isRequired: true,
          prefixIcon: Icons.near_me_outlined,
        ),
        const SizedBox(height: 24),

        // Simple Privacy Text
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'गोपनीयताका कारण सटीक घर नम्बर सार्वजनिक गरिने छैन।',
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                  height: 1.3,
                ),
              ),
            ),
          ],
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
        const SizedBox(height: 16),
        CounterField(
          label: 'अतिथि संख्या (Guests)',
          icon: Icons.people_outline_rounded,
          value: _guestsController.text,
          onIncrement: () => _updateCount(_guestsController, 1),
          onDecrement: () => _updateCount(_guestsController, -1),
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
      subtitle: 'मासिक भाडा र घर/कोठाका नियमहरू उल्लेख गर्नुहोस्।',
      content: [
        // ── Pricing Section ────────────────────────────────────────────────
        PriceInputField(
          label: 'मासिक भाडा (Monthly Rent)',
          controller: _priceController,
          suffix: 'प्रति महिना',
        ),
        const SizedBox(height: 16),
        PriceInputField(
          label: 'प्रति रात भाडा (Per Night - Optional)',
          controller: _priceNightController,
          suffix: 'प्रति रात',
        ),
        const SizedBox(height: 20),

        // Negotiable Switch (Clean Human UI)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isNegotiable ? AppTheme.brandColor : const Color(0xFFE2E8F0),
              width: _isNegotiable ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isNegotiable ? AppTheme.brandColor.withOpacity(0.1) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.handshake_outlined,
                  color: _isNegotiable ? AppTheme.brandColor : const Color(0xFF64748B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'भाडा मिलाउन सकिने (Negotiable)',
                      style: GoogleFonts.notoSansDevanagari(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'भाडामा छलफल वा मोलमोलाई गर्न मिल्नेछ।',
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isNegotiable,
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  setState(() => _isNegotiable = v);
                },
                activeColor: AppTheme.brandColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // ── House Rules Section ─────────────────────────────────────────────
        Text(
          'घर/कोठाका नियमहरू (House Rules)',
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 14),
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
    final bool isGoalMet = photoCount >= 5;

    return StepLayout(
      title: 'फोटोहरू थप्नुहोस् (Add Photos)',
      subtitle: 'उज्यालो र सफा फोटोहरूले ग्राहकलाई छिटो आकर्षित गर्छ।',
      content: [
        // Clean Counter Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isGoalMet ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isGoalMet ? Icons.check_circle_rounded : Icons.photo_library_outlined,
                    color: isGoalMet ? const Color(0xFF16A34A) : AppTheme.brandColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isGoalMet ? 'कम्तिमा ५ फोटो पूरा भयो ✓' : 'अपलोड गरिएका फोटो: $photoCount / ५',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isGoalMet ? const Color(0xFF16A34A) : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Text(
                '$photoCount वटा',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Clean Photo Upload Area
        DottedBorder(
          options: RoundedRectDottedBorderOptions(
            radius: const Radius.circular(16),
            strokeWidth: 1.5,
            color: const Color(0xFF94A3B8),
            dashPattern: const [6, 4],
            padding: EdgeInsets.zero,
          ),
          child: GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppTheme.brandColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'फोटोहरू छान्नुहोस्',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'कम्तिमा ५ वटा सफा फोटो राख्नुहोस्',
                    style: GoogleFonts.notoSansDevanagari(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'पहिलो फोटो मुख्य कभर फोटो हुनेछ (Thumbnails):',
            style: GoogleFonts.notoSansDevanagari(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          ReorderableGridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _selectedImages.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                final item = _selectedImages.removeAt(oldIndex);
                _selectedImages.insert(newIndex, item);
              });
              HapticFeedback.lightImpact();
            },
            itemBuilder: (context, index) {
              return ClipRRect(
                key: ValueKey(_selectedImages[index].path),
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_selectedImages[index], fit: BoxFit.cover),
                    if (index == 0)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          color: const Color(0xFF0F172A).withOpacity(0.75),
                          child: Text(
                            'कभर फोटो',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.notoSansDevanagari(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImages.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
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
      title: 'विज्ञापनको शीर्षक र भिडियो',
      subtitle: 'आफ्नो सम्पत्तिको आकर्षक शीर्षक र छोटो भिडियो थप्नुहोस्।',
      content: [
        // Title Input
        PropertyFormField(
          label: 'विज्ञापनको शीर्षक (Property Title)',
          hint: 'उदा: सानेपामा घाम लाग्ने १ BHK फ्ल्याट भाडामा',
          controller: _titleController,
          isRequired: true,
          prefixIcon: Icons.title_rounded,
        ),
        const SizedBox(height: 14),

        // Quick Title Chips
        Text(
          'सुझाव गरिएका शीर्षकहरू (QUICK SUGGESTIONS):',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSmartTitleChip('कोठा भाडामा (Room for Rent)'),
            _buildSmartTitleChip('१ BHK फ्ल्याट भाडामा'),
            _buildSmartTitleChip('Best Room in ${_areaController.text.isNotEmpty ? _areaController.text : 'Location'}'),
          ],
        ),
        const SizedBox(height: 32),

        // Video Upload Box (Clean Human UI)
        Text(
          'सम्पत्तिको छोटो भिडियो (Property Reel / Video)',
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'भिडियो राख्दा ग्राहकले विश्वास गर्छन् र छिटो सम्पर्क गर्छन्।',
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _pickVideo,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedVideo != null ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _selectedVideo != null ? const Color(0xFF16A34A).withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedVideo != null ? Icons.check_circle_rounded : Icons.videocam_outlined,
                    color: _selectedVideo != null ? const Color(0xFF16A34A) : AppTheme.brandColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedVideo != null ? 'भिडियो सेभ भयो ✓' : 'भिडियो छान्नुहोस् (Choose Video)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedVideo != null 
                            ? 'भिडियो फेर्न पुनः थिच्नुहोस्' 
                            : 'मोवाइलबाट १-२ मिनेटको छोटो भिडियो राख्नुहोस्',
                        style: GoogleFonts.notoSansDevanagari(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
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
      subtitle: 'सम्पत्ति भाडामा जाँदा रकम प्राप्त गर्ने खाता छान्नुहोस्।',
      content: [
        // Payout Method Selector
        Text(
          'भुक्तानी माध्यम (Payout Method)',
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildPayoutTypeSelector('eSewa', 'esewa', Icons.account_balance_wallet_rounded, const Color(0xFF60BB46), 'assets/images/esewa.webp'),
            const SizedBox(width: 8),
            _buildPayoutTypeSelector('Khalti', 'khalti', Icons.account_balance_wallet_rounded, const Color(0xFF5C2D91), 'assets/images/khalti.png'),
            const SizedBox(width: 8),
            _buildPayoutTypeSelector('Bank', 'bank', Icons.account_balance_rounded, Colors.blue),
          ],
        ),
        const SizedBox(height: 24),

        // Bank Name Selector (Only if Bank Method is chosen)
        if (_selectedPayoutMethod == 'bank') ...[
          GestureDetector(
            onTap: _showBankPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_rounded, color: AppTheme.brandColor, size: 20),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'बैंकको नाम (Bank Name)',
                          style: GoogleFonts.notoSansDevanagari(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedBank,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Account Number Input
        PropertyFormField(
          label: _selectedPayoutMethod == 'bank' 
            ? 'खाता वा फोन नम्बर (Account or Phone Number)'
            : '${_selectedPayoutMethod == 'esewa' ? 'eSewa' : 'Khalti'} ID / नम्बर',
          hint: _selectedPayoutMethod == 'bank' 
            ? 'खाता वा मोबाइल नम्बर राख्नुहोस्'
            : 'मोबाइल नम्बर राख्नुहोस्',
          controller: _payoutAccountController,
          isRequired: true,
          keyboardType: TextInputType.text,
          onChanged: (_) => setState(() {}),
          prefixIcon: _selectedPayoutMethod == 'bank' ? Icons.account_balance_outlined : Icons.phone_android_outlined,
        ),
        const SizedBox(height: 20),

        // Optional QR Screenshot Upload
        GestureDetector(
          onTap: _pickPayoutImage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _payoutQrImage != null ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _payoutQrImage != null ? Icons.check_circle_rounded : Icons.qr_code_scanner_rounded,
                  color: _payoutQrImage != null ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _payoutQrImage != null ? 'QR फोटो थपियो ✓' : 'QR कोड / फोटो (ऐच्छिक)',
                        style: GoogleFonts.notoSansDevanagari(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'बैंक वा eSewa QR स्क्यानर फोटो राख्न सक्नुहुन्छ',
                        style: GoogleFonts.notoSansDevanagari(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_payoutQrImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_payoutQrImage!, width: 36, height: 36, fit: BoxFit.cover),
                  ),
              ],
            ),
          ),
        ),
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
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
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
  
  final List<Map<String, String>> _suggestions = [
    {'name': 'Villa', 'icon': '🏰'},
    {'name': 'Hotel', 'icon': '🛎️'},
    {'name': 'Office Space', 'icon': '🏢'},
    {'name': 'Shutter', 'icon': '🏬'},
    {'name': 'Godown/Warehouse', 'icon': '📦'},
    {'name': 'Farm Cottage', 'icon': '🌾'},
    {'name': 'Event Hall', 'icon': '🏛️'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'অন্য सम्पत्ति प्रकार / Other Type',
          style: GoogleFonts.inter(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What type of property is this?',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Specify or select the exact property type for better search visibility.',
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              
              // Custom Type Text Field
              TextField(
                controller: _customController,
                autofocus: true,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: 'Type your custom property type...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 15),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.brandColor, width: 1.8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  prefixIcon: const Icon(Icons.edit_note_rounded, color: AppTheme.brandColor, size: 24),
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) Navigator.pop(context, v.trim());
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 32),

              // Popular Categories Header
              Text(
                'POPULAR SUGGESTIONS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),

              // Rich Suggestion Chips
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _suggestions.map((item) {
                  final String name = item['name']!;
                  final String emoji = item['icon']!;
                  final bool isTypedMatch = _customController.text.trim().toLowerCase() == name.toLowerCase();

                  return Material(
                    color: isTypedMatch ? AppTheme.brandColor.withOpacity(0.08) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => Navigator.pop(context, name),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isTypedMatch ? AppTheme.brandColor : const Color(0xFFE2E8F0),
                            width: isTypedMatch ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: isTypedMatch ? FontWeight.w700 : FontWeight.w600,
                                color: isTypedMatch ? AppTheme.brandColor : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (_customController.text.trim().isNotEmpty) {
                  Navigator.pop(context, _customController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _customController.text.trim().isNotEmpty
                    ? AppTheme.brandColor
                    : AppTheme.brandColor.withOpacity(0.5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              child: Text(
                'Confirm Property Type',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
