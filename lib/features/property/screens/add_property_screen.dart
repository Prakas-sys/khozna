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
  final int _totalSteps = 10;
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
  final TextEditingController _guestsController = TextEditingController(text: '0');
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _sqftController = TextEditingController();
  final TextEditingController _videoCaptionController = TextEditingController();

  // Payout State
  String _selectedPayoutMethod = 'esewa';
  String _selectedBank = 'Nepal Bank Ltd.';
  final TextEditingController _payoutAccountController =
      TextEditingController();
  final TextEditingController _payoutNameController =
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
          .select('esewa_number, full_name')
          .eq('id', user.id)
          .maybeSingle();
      if (profile != null) {
        final val = (profile['esewa_number'] as String?)?.trim() ?? '';
        final isDummyZeroes = RegExp(r'^0+$').hasMatch(val) || val == '000';
        if (val.isNotEmpty && !isDummyZeroes) {
          _payoutAccountController.text = val;
        }
        final name = (profile['full_name'] as String?)?.trim() ?? '';
        if (name.isNotEmpty && _payoutNameController.text.isEmpty) {
          _payoutNameController.text = name;
        }
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
    _payoutNameController.dispose();
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
                'Please enable location permission in settings.',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
              'Detecting location details...',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location detected & area auto-filled ✓',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          );
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
      case 5: // House Rules (Step 6)
        isValid = true;
        break;
      case 6: // Photos (Step 7)
        if (_selectedImages.length < 5) {
          errorMessage = 'कृपया कम्तिमा ५ वटा फोटोहरू राख्नुहोस्।';
        } else {
          isValid = true;
        }
        break;
      case 7: // Marketing (Title + Video)
        if (_titleController.text.trim().isEmpty) {
          errorMessage = 'कृपया एउटा आकर्षक शीर्षक राख्नुहोस्।';
        } else {
          isValid = true;
        }
        break;
      case 8: // Payout
        if (_payoutAccountController.text.trim().isEmpty) {
          errorMessage = 'कृपया आफ्नो पेमेन्ट खाता नम्बर राख्नुहोस्।';
        } else {
          isValid = true;
        }
        break;
      case 9: // Final Review & Publish
        isValid = true;
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
            style: GoogleFonts.inter(
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
                    _buildStepPricing(),
                    _buildStepHouseRules(),
                    _buildStepPhotos(),
                    _buildStepMarketing(),
                    _buildStepPayout(),
                    _buildStepReview(),
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
    final List<Map<String, String>> categories = [
      {
        'label': 'Room',
        'value': 'Room',
        'imagePath': 'assets/images/room.jpeg',
      },
      {
        'label': 'Flat',
        'value': 'Flat',
        'imagePath': 'assets/images/flat.jpeg',
      },
      {
        'label': 'Cottage',
        'value': 'Cottage',
        'imagePath': 'assets/images/cottage.jpeg',
      },
      {
        'label': 'Villa',
        'value': 'Villa',
        'imagePath': 'assets/images/villa.jpeg',
      },
      {
        'label': 'Hotel',
        'value': 'Hotel',
        'imagePath': 'assets/images/hotel.jpeg',
      },
      {
        'label': 'Other',
        'value': 'Other',
        'imagePath': 'assets/images/other propterty.jpeg',
      },
    ];

    return StepLayout(
      controller: _mainScrollController,
      title: 'Property Type',
      subtitle: 'Which of these best describes your place?',
      content: [
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.88,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return CategoryCard(
              label: cat['label']!,
              imagePath: cat['imagePath']!,
              value: cat['value']!,
              selectedValue: _selectedCategory,
              onSelect: (v) async {
                if (v == 'Other') {
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
                } else {
                  setState(() => _selectedCategory = v);
                  HapticFeedback.mediumImpact();
                }
              },
            );
          },
        ),
        if (_selectedCategory == 'Other' && _otherCategoryController.text.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
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
                          color: AppTheme.brandColor.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        _otherCategoryController.text,
                        style: GoogleFonts.inter(
                          fontSize: 16,
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
                  child: Text(
                    'Change',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.brandColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepLocation() {
    final bool hasLocation = _latitude != null;

    return StepLayout(
      title: 'Property Location',
      subtitle: 'Auto-detect your location with GPS or type details below.',
      content: [
        // ── High-Attention GPS Auto-Detect Card ──────────────────────
        GestureDetector(
          onTap: _isLocating
              ? null
              : () {
                  setState(() => _showLocationNudge = false);
                  _detectLocation();
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
            decoration: BoxDecoration(
              color: hasLocation
                  ? const Color(0xFFF0FDF4)
                  : AppTheme.brandColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasLocation
                    ? const Color(0xFF22C55E)
                    : AppTheme.brandColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasLocation
                        ? const Color(0xFFDCFCE7)
                        : AppTheme.brandColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: _isLocating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppTheme.brandColor,
                          ),
                        )
                      : Icon(
                          Icons.my_location_rounded,
                          color: hasLocation
                              ? const Color(0xFF16A34A)
                              : AppTheme.brandColor,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLocating
                            ? 'Detecting Location...'
                            : (hasLocation
                                ? 'Location Auto-Detected'
                                : 'Auto-Detect Location (GPS)'),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: hasLocation
                              ? const Color(0xFF15803D)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isLocating
                            ? 'Finding area and landmark automatically...'
                            : (hasLocation
                                ? 'GPS coordinates set • Tap to update'
                                : 'Tap to auto-fill area name & map position'),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: hasLocation
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: hasLocation
                      ? const Color(0xFF16A34A)
                      : AppTheme.brandColor,
                ),
              ],
            ),
          ),
        ),
        if (_showLocationNudge && !hasLocation)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              '⚠️ Please detect your location or enter area details below',
              style: GoogleFonts.inter(
                color: const Color(0xFFDC2626),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 24),

        // ── Or Manual Entry Section ──────────────────────────────────
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR ENTER MANUALLY',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
          ],
        ),
        const SizedBox(height: 20),

        // Area / Tole Name Field
        PropertyFormField(
          label: 'Area / Tole Name',
          hint: 'e.g. Sanepa-2, Lalitpur',
          controller: _areaController,
          isRequired: true,
          prefixIcon: Icons.location_on_outlined,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),

        // Landmark Field
        PropertyFormField(
          label: 'Nearby Landmark',
          hint: 'e.g. Near Star Hospital / Civil Bank',
          controller: _landmarkController,
          isRequired: true,
          prefixIcon: Icons.near_me_outlined,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),

        // Privacy Guarantee Note
        Row(
          children: [
            const Icon(Icons.lock_outline_rounded, size: 15, color: Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'For guest safety, exact house numbers are kept confidential.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
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
      title: 'Property Details',
      subtitle: 'Specify room count, floor level, and area size.',
      content: [
        CounterField(
          label: 'Bedrooms',
          icon: Icons.bed_outlined,
          value: _bedroomsController.text,
          onIncrement: () => _updateCount(_bedroomsController, 1),
          onDecrement: () => _updateCount(_bedroomsController, -1),
        ),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        CounterField(
          label: 'Bathrooms',
          icon: Icons.shower_outlined,
          value: _bathroomsController.text,
          onIncrement: () => _updateCount(_bathroomsController, 1),
          onDecrement: () => _updateCount(_bathroomsController, -1),
        ),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        CounterField(
          label: 'Guests Allowed',
          icon: Icons.people_outline_rounded,
          value: _guestsController.text,
          onIncrement: () => _updateCount(_guestsController, 1),
          onDecrement: () => _updateCount(_guestsController, -1),
        ),
        const SizedBox(height: 24),
        FloorSelector(
          label: 'Floor Level',
          selectedFloor: _floorController.text,
          onSelect: (val) => setState(() => _floorController.text = val),
        ),
        const SizedBox(height: 24),
        PropertyFormField(
          label: 'Total Area (sq. ft.)',
          hint: 'e.g. 400',
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
    final categories = const [
      AmenityCategory(
        title: 'ESSENTIAL AMENITIES',
        items: [
          AmenityItem(id: 'water_24_7', label: '24/7 Water', icon: Icons.water_damage_rounded),
          AmenityItem(id: 'drinking_water', label: 'Drinking Water', icon: Icons.water_drop_rounded),
          AmenityItem(id: 'internet', label: 'Wi-Fi', icon: Icons.wifi_rounded),
          AmenityItem(id: 'kitchen', label: 'Kitchen', icon: Icons.kitchen_rounded),
          AmenityItem(id: 'furnished', label: 'Furnished', icon: Icons.chair_rounded),
          AmenityItem(id: 'unfurnished', label: 'Unfurnished', icon: Icons.chair_outlined),
          AmenityItem(id: 'laundry', label: 'Washing Machine', icon: Icons.local_laundry_service_rounded),
          AmenityItem(id: 'ac', label: 'Air Conditioning', icon: Icons.ac_unit_rounded),
        ],
      ),
      AmenityCategory(
        title: 'BUILDING & PROPERTY',
        items: [
          AmenityItem(id: 'parking_car', label: 'Car Parking', icon: Icons.directions_car_rounded),
          AmenityItem(id: 'parking_bike', label: 'Bike Parking', icon: Icons.two_wheeler_rounded),
          AmenityItem(id: 'elevator', label: 'Elevator', icon: Icons.elevator_rounded),
          AmenityItem(id: 'security', label: 'Security', icon: Icons.security_rounded),
          AmenityItem(id: 'balcony', label: 'Balcony', icon: Icons.balcony_rounded),
          AmenityItem(id: 'rooftop', label: 'Rooftop', icon: Icons.roofing_rounded),
          AmenityItem(id: 'solar', label: 'Solar / Backup', icon: Icons.solar_power_rounded),
          AmenityItem(id: 'public_transport', label: 'Public Transport', icon: Icons.directions_bus_rounded),
        ],
      ),
    ];

    return StepLayout(
      title: 'Amenities',
      subtitle: 'Select key amenities available at your property.',
      content: [
        CategorizedAmenitiesGrid(
          selectedItems: _selectedAmenities,
          categories: categories,
          onToggle: _toggleAmenity,
        ),
      ],
    );
  }

  Widget _buildStepPricing() {
    return StepLayout(
      title: 'Set Your Price',
      subtitle: 'Set your monthly rent and nightly rate for your property.',
      content: [
        // ── Pricing Section ────────────────────────────────────────────────
        PriceInputField(
          label: 'Monthly Rent',
          controller: _priceController,
          suffix: '/ month',
        ),
        const SizedBox(height: 16),
        PriceInputField(
          label: 'Nightly Rent',
          controller: _priceNightController,
          suffix: '/ night',
        ),
        const SizedBox(height: 24),

        // Negotiable Switch
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.handshake_outlined,
                  size: 18,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rent Negotiable',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Allow guests to discuss or negotiate rent',
                      style: GoogleFonts.inter(
                        fontSize: 12,
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
      ],
    );
  }

  Widget _buildStepHouseRules() {
    // Rule definitions: id -> (icon, label, description, isAllowed)
    final List<Map<String, dynamic>> ruleGroups = [
      {
        'title': 'WHO CAN STAY',
        'rules': [
          {'id': 'family_only', 'icon': Icons.family_restroom_rounded, 'label': 'Family Only', 'desc': 'Only families with families accepted'},
          {'id': 'bachelors_allowed', 'icon': Icons.school_rounded, 'label': 'Students / Bachelors', 'desc': 'Students and single tenants welcome'},
          {'id': 'boys_only', 'icon': Icons.man_rounded, 'label': 'Boys Only', 'desc': 'Space reserved for male tenants'},
          {'id': 'girls_only', 'icon': Icons.woman_rounded, 'label': 'Girls Only', 'desc': 'Space reserved for female tenants'},
          {'id': 'couples_allowed', 'icon': Icons.favorite_border_rounded, 'label': 'Couples Welcome', 'desc': 'Couples can rent this property'},
        ],
      },
      {
        'title': 'HOUSE POLICIES',
        'rules': [
          {'id': 'no_smoking', 'icon': Icons.smoke_free_rounded, 'label': 'No Smoking', 'desc': 'Strictly no smoking inside premises'},
          {'id': 'no_parties', 'icon': Icons.nightlife_rounded, 'label': 'No Parties / Loud Noise', 'desc': 'Gatherings and loud noise not allowed'},
          {'id': 'no_alcohol', 'icon': Icons.no_drinks, 'label': 'No Alcohol', 'desc': 'Consumption of alcohol not permitted'},
          {'id': 'pets_allowed', 'icon': Icons.pets_rounded, 'label': 'Pets Allowed', 'desc': 'Cats, dogs or other pets welcome'},
          {'id': 'gate_closing', 'icon': Icons.door_front_door_rounded, 'label': 'Gate Closing Time', 'desc': 'Main gate closes at a set time daily'},
          {'id': 'visitors_allowed', 'icon': Icons.groups_2_rounded, 'label': 'Visitors Allowed', 'desc': 'Guests and visitors can visit tenants'},
        ],
      },
      {
        'title': 'INCLUDED SERVICES',
        'rules': [
          {'id': 'cleaning_service', 'icon': Icons.cleaning_services_rounded, 'label': 'Cleaning Service', 'desc': 'Regular room/common area cleaning'},
          {'id': 'meals_included', 'icon': Icons.restaurant_rounded, 'label': 'Meals Included', 'desc': 'Food provided (tiffin or full meals)'},
          {'id': 'internet_included', 'icon': Icons.wifi_rounded, 'label': 'Internet Included', 'desc': 'Wi-Fi cost included in rent'},
          {'id': 'electricity_included', 'icon': Icons.bolt_rounded, 'label': 'Electricity Included', 'desc': 'Electricity bill covered in rent'},
          {'id': 'water_included', 'icon': Icons.water_drop_rounded, 'label': 'Water Included', 'desc': 'Water bill covered in rent'},
        ],
      },
    ];

    return StepLayout(
      title: 'House Rules',
      subtitle: 'Set clear expectations — like Airbnb. Guests will see these before booking.',
      content: [
        ...ruleGroups.map((group) {
          final title = group['title'] as String;
          final rules = group['rules'] as List<Map<String, dynamic>>;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              ...rules.map((rule) {
                final id = rule['id'] as String;
                final icon = rule['icon'] as IconData;
                final label = rule['label'] as String;
                final desc = rule['desc'] as String;
                final isSelected = _selectedRules.contains(id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _toggleRule(id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.15)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              size: 18,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  desc,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.65)
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? Colors.white : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: Color(0xFF0F172A),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildStepPhotos() {
    final int photoCount = _selectedImages.length;
    final bool isGoalMet = photoCount >= 5;

    return StepLayout(
      title: 'Photos',
      subtitle: 'Add high quality photos of your property.',
      content: [
        // ── Main Upload Card ─────────────────────────────────────────
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isGoalMet ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_a_photo_rounded,
                    color: AppTheme.brandColor,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedImages.isEmpty ? 'Upload Property Photos' : 'Add More Photos',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isGoalMet
                      ? '$photoCount photos added ✓ (Minimum 5 reached)'
                      : 'Add at least 5 photos ($photoCount / 5 uploaded)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isGoalMet ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Photo Grid with Drag & Reorder ───────────────────────────
        if (_selectedImages.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.touch_app_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Press and drag to reorder. 1st photo is your main cover.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
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
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          color: const Color(0xFF0F172A).withOpacity(0.85),
                          child: Text(
                            'COVER PHOTO',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
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
    final locationName = _areaController.text.trim().isNotEmpty
        ? _areaController.text.trim()
        : 'Sanepa';

    return StepLayout(
      title: 'Title & Video Tour',
      subtitle: 'Create a catchy title and add a virtual video tour of your property.',
      content: [
        // Title Input
        PropertyFormField(
          label: 'Property Title',
          hint: 'e.g. Cozy 1 BHK Flat in $locationName',
          controller: _titleController,
          isRequired: true,
          prefixIcon: Icons.title_rounded,
        ),
        const SizedBox(height: 16),

        // Quick Title Chips
        Text(
          'QUICK TITLE IDEAS:',
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
            _buildSmartTitleChip('Cozy Room for Rent in $locationName'),
            _buildSmartTitleChip('Beautiful 1 BHK Flat in $locationName'),
            _buildSmartTitleChip('Modern Studio Apartment'),
            _buildSmartTitleChip('Sunny & Spacious Room'),
          ],
        ),
        const SizedBox(height: 28),

        // Video Tour Upload Card
        GestureDetector(
          onTap: _pickVideo,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedVideo != null ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _selectedVideo != null
                        ? const Color(0xFFDCFCE7)
                        : AppTheme.brandColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _selectedVideo != null
                        ? Icons.check_rounded
                        : Icons.video_camera_back_rounded,
                    color: _selectedVideo != null
                        ? const Color(0xFF16A34A)
                        : AppTheme.brandColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedVideo != null
                            ? 'Property Tour Video Added ✓'
                            : 'Add Property Tour Video',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedVideo != null
                            ? 'Tap to replace tour video'
                            : 'Upload a short walk-through video (Optional)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF94A3B8),
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
      title: 'Payout Details',
      subtitle: 'Choose how you would like to receive booking payments.',
      content: [
        // Payout Method Selector List
        Text(
          'SELECT PAYOUT METHOD',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),

        Column(
          children: [
            _buildPayoutTile('eSewa Wallet', 'esewa', 'Instant mobile wallet transfer', 'assets/images/esewa.webp', Icons.account_balance_wallet_outlined),
            const SizedBox(height: 10),
            _buildPayoutTile('Khalti Wallet', 'khalti', 'Instant digital wallet payout', 'assets/images/khalti.png', Icons.account_balance_wallet_outlined),
            const SizedBox(height: 10),
            _buildPayoutTile('Bank Transfer', 'bank', 'Direct transfer to your bank account', null, Icons.account_balance_rounded),
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
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_rounded, color: Color(0xFF0F172A), size: 20),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bank Name',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedBank,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
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
          const SizedBox(height: 16),
        ],

        // Account Holder Name Input
        PropertyFormField(
          label: 'Account Holder Name',
          hint: 'e.g. Ram Bahadur Shrestha',
          controller: _payoutNameController,
          isRequired: true,
          keyboardType: TextInputType.name,
          prefixIcon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 16),

        // Account Number Input
        PropertyFormField(
          label: _selectedPayoutMethod == 'bank' 
            ? 'Bank Account Number'
            : '${_selectedPayoutMethod == 'esewa' ? 'eSewa' : 'Khalti'} ID / Mobile Number',
          hint: _selectedPayoutMethod == 'bank' 
            ? 'Enter account number'
            : 'Enter registered mobile number',
          controller: _payoutAccountController,
          isRequired: true,
          keyboardType: TextInputType.text,
          onChanged: (_) => setState(() {}),
          prefixIcon: _selectedPayoutMethod == 'bank' ? Icons.badge_outlined : Icons.phone_android_outlined,
        ),
        const SizedBox(height: 24),

        // Optional QR Code Card
        GestureDetector(
          onTap: _pickPayoutImage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _payoutQrImage != null ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _payoutQrImage != null
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _payoutQrImage != null ? Icons.check_rounded : Icons.qr_code_scanner_rounded,
                    color: _payoutQrImage != null ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _payoutQrImage != null
                            ? 'Payment QR Image Added ✓'
                            : 'Upload Payment QR Code (Optional)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _payoutQrImage != null
                            ? 'Tap to change QR image'
                            : 'Upload eSewa, Khalti, or Fonepay QR code',
                        style: GoogleFonts.inter(
                          fontSize: 12,
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
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepReview() {
    final String categoryName = (_selectedCategory == 'Other'
            ? _otherCategoryController.text.trim()
            : _selectedCategory) ??
        'Property';
    final String titleText = _titleController.text.trim().isEmpty
        ? 'Untitled Property'
        : _titleController.text.trim();
    final String areaText = _areaController.text.trim().isEmpty
        ? 'Location not set'
        : _areaController.text.trim();
    final String landmarkText = _landmarkController.text.trim();
    final String priceText = _priceController.text.trim().isEmpty
        ? '0'
        : _priceController.text.trim();

    return StepLayout(
      title: 'Review Listing',
      subtitle: 'Double-check your property details before publishing.',
      content: [
        // ── Main Listing Preview Card ──────────────────
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Header Stack
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: _selectedImages.isNotEmpty
                        ? Image.file(
                            _selectedImages.first,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            height: 200,
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: Icon(Icons.image_outlined, size: 48, color: Color(0xFF94A3B8)),
                            ),
                          ),
                  ),
                  // Category Badge
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        categoryName.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Photo Count Badge
                  Positioned(
                    bottom: 12,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_outlined, color: Colors.white, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            '${_selectedImages.length} Photos',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Property Card Content Body
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Edit Button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            titleText,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              height: 1.25,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.brandColor),
                          onPressed: () => _jumpToStep(7), // Marketing step (Title)
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 15, color: AppTheme.brandColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            landmarkText.isNotEmpty ? '$areaText ($landmarkText)' : areaText,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _jumpToStep(1), // Location step
                          child: Text(
                            'Edit',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.brandColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Price Pill Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF86EFAC), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Rent:',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF166534),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'रु $priceText',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                              Text(
                                ' / month',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF166534),
                                ),
                              ),
                            ],
                          ),
                          if (_isNegotiable)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Negotiable',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Key Specs Grid Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_bedroomsController.text.isNotEmpty && _bedroomsController.text != '0')
                          _buildReviewSpecChip(Icons.bed_outlined, '${_bedroomsController.text} Beds'),
                        if (_bathroomsController.text.isNotEmpty && _bathroomsController.text != '0')
                          _buildReviewSpecChip(Icons.bathtub_outlined, '${_bathroomsController.text} Baths'),
                        if (_floorController.text.isNotEmpty)
                          _buildReviewSpecChip(Icons.apartment_rounded, '${_floorController.text} Floor'),
                        if (_sqftController.text.isNotEmpty)
                          _buildReviewSpecChip(Icons.square_foot_rounded, '${_sqftController.text} Sqft'),
                        if (_guestsController.text.isNotEmpty && _guestsController.text != '0')
                          _buildReviewSpecChip(Icons.people_outline_rounded, 'Max ${_guestsController.text} Guests'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ── Amenities Summary Block ──────────────────
        if (_selectedAmenities.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AMENITIES INCLUDED (${_selectedAmenities.length})',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.6,
                ),
              ),
              InkWell(
                onTap: () => _jumpToStep(3),
                child: Text(
                  'Edit',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.brandColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedAmenities.map((amenityId) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF16A34A)),
                    const SizedBox(width: 5),
                    Text(
                      amenityId.replaceAll('_', ' ').toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
        ],

        // ── Payout Method Summary Block ──────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PAYMENT METHOD FOR RENT',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF94A3B8),
                letterSpacing: 0.6,
              ),
            ),
            InkWell(
              onTap: () => _jumpToStep(8),
              child: Text(
                'Edit',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brandColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.brandColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.brandColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedPayoutMethod.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _payoutAccountController.text,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 20),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Ready Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: Row(
            children: [
              const Icon(Icons.rocket_launch_rounded, color: Color(0xFF16A34A), size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to Publish!',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF14532D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your listing will be instantly live for thousands of tenants.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildReviewSpecChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF475569)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  void _jumpToStep(int stepIndex) {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      stepIndex,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = stepIndex);
  }

  Widget _buildPayoutTile(
    String title,
    String type,
    String subtitle,
    String? assetIcon,
    IconData fallbackIcon,
  ) {
    bool isSelected = _selectedPayoutMethod == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedPayoutMethod = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: assetIcon != null
                  ? Image.asset(
                      assetIcon,
                      fit: BoxFit.contain,
                    )
                  : Icon(fallbackIcon, color: const Color(0xFF0F172A), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                  width: isSelected ? 6 : 1.5,
                ),
              ),
            ),
          ],
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
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentStep > 0)
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                  setState(() => _currentStep--);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  foregroundColor: const Color(0xFF111827),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
            ElevatedButton(
              onPressed: isLastStep
                  ? (_isPublishing ? null : _nextStep)
                  : () {
                      HapticFeedback.mediumImpact();
                      _nextStep();
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: AppTheme.brandColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: AppTheme.brandColor.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isPublishing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isLastStep ? 'Publish' : 'Next',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
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
    {'name': 'Office Space', 'icon': '🏢'},
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
          'Other Type',
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
                    color: Colors.white,
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
