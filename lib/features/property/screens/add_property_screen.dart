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

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  int _currentStep = 0;
  final int _totalSteps = 9;
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
  final TextEditingController _payoutAccountController =
      TextEditingController();

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
        isValid = true; // Basics are optional
        break;
      case 3:
        isValid = true; // Amenities are optional
        break;
      case 4:
        if (_selectedImages.length < 5) {
          errorMessage =
              'कृपया कम्तिमा ५ वटा फोटोहरू राख्नुहोस्। (At least 5 photos required)';
        } else {
          isValid = true;
        }
        break;
      case 5:
        isValid = true; // Video is optional
        break;
      case 6:
        if (_titleController.text.trim().isEmpty) {
          errorMessage = 'कृपया प्रोपर्टीको आकर्षक शीर्षक राख्नुहोस्।';
        } else {
          isValid = true;
        }
        break;
      case 7:
        if (_priceController.text.trim().isEmpty &&
            _priceNightController.text.trim().isEmpty) {
          errorMessage = 'कृपया मासिक वा दैनिक भाडा राख्नुहोस्।';
        } else {
          isValid = true;
        }
        break;
      case 8: // Payout & Description
        if (_payoutAccountController.text.trim().isEmpty) {
          errorMessage = 'तपाईंले पेमेन्ट पाउनको लागि खाता नम्बर राख्नुहोस्।';
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
      // Save payout details to profile
      if (_selectedPayoutMethod == 'esewa') {
        await Supabase.instance.client
            .from('profiles')
            .update({'esewa_number': _payoutAccountController.text.trim()})
            .eq('id', user.id);
      }

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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.brandColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_mosaic_rounded,
                      size: 14,
                      color: AppTheme.brandColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_currentStep + 1} / $_totalSteps',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.brandColor,
                        fontSize: 13,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 8,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0,
                    end: (_currentStep + 1) / _totalSteps,
                  ),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutCubic,
                  builder: (context, value, child) => LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.brandColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
                    _buildStepPhotos(),
                    _buildStepVideo(),
                    _buildStepTitleDesc(),
                    _buildStepPricingRules(),
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
              selectedValue: _selectedCategory,
              onSelect: (v) => setState(() => _selectedCategory = v),
            ),
            CategoryCard(
              label: 'फ्ल्याट / Flat',
              imagePath: 'assets/images/flat (2).png',
              value: 'Flat',
              selectedValue: _selectedCategory,
              onSelect: (v) => setState(() => _selectedCategory = v),
            ),
            CategoryCard(
              label: 'कटेज / Cottage',
              imagePath: 'assets/images/cottage (2).png',
              value: 'Cottage',
              selectedValue: _selectedCategory,
              onSelect: (v) => setState(() => _selectedCategory = v),
            ),
            CategoryCard(
              label: 'होस्टल / Hostel',
              imagePath: 'assets/images/Hotel.png',
              value: 'Hostel',
              selectedValue: _selectedCategory,
              onSelect: (v) => setState(() => _selectedCategory = v),
            ),
            CategoryCard(
              label: 'अन्य / Other',
              imagePath: 'assets/images/other image.png',
              value: 'Other',
              imageScale: 1.2, // Adjusted scale for new image
              selectedValue: _selectedCategory,
              onSelect: (v) => setState(() => _selectedCategory = v),
            ),
          ],
        ),
        if (_selectedCategory == 'Other') ...[
          const SizedBox(height: 24),
          PropertyFormField(
            label: 'सम्पत्तिको प्रकार लेख्नुहोस्',
            hint: 'उदा: सटर, गोदाम, आदि',
            controller: _otherCategoryController,
            prefixIcon: Icons.edit_note_rounded,
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
            'water_boring': Icons.waves_rounded,
            'ac': Icons.ac_unit_rounded,
            'internet': Icons.wifi_rounded,
            'sunny_room': Icons.wb_sunny_rounded,
            'balcony': Icons.balcony_rounded,
            'kitchen': Icons.kitchen_rounded,
            'furnished': Icons.chair_rounded,
            'parking_bike': Icons.motorcycle_rounded,
            'parking_car': Icons.directions_car_rounded,
            'security': Icons.security_rounded,
            'elevator': Icons.elevator_rounded,
            'power_backup': Icons.electric_bolt_rounded,
            'waste_mgmt': Icons.delete_outline_rounded,
            'peaceful': Icons.nature_people_rounded,
          },
          labels: const {
            'water_24_7': '२४ सै घण्टा पानी',
            'water_boring': 'बोरिङको पानी',
            'ac': 'एसी (AC)',
            'internet': 'इन्टरनेट',
            'sunny_room': 'घाम लाग्ने कोठा',
            'balcony': 'बालकोनी (Balcony)',
            'kitchen': 'छुट्टै भान्सा',
            'furnished': 'फर्निचर सहित',
            'parking_bike': 'बाइक पार्किङ',
            'parking_car': 'कार पार्किङ',
            'security': 'सेक्युरिटी / CCTV',
            'elevator': 'लिफ्ट (Elevator)',
            'power_backup': 'पावर ब्याकअप',
            'waste_mgmt': 'फोहोर उठाउने',
            'peaceful': 'शान्त वातावरण',
          },
          onToggle: _toggleAmenity,
        ),
      ],
    );
  }

  Widget _buildStepPhotos() {
    final int photoCount = _selectedImages.length;
    final double progress = (photoCount / 5).clamp(0.0, 1.0);
    final bool isGoalMet = photoCount >= 5;

    return StepLayout(
      title: 'केही राम्रा फोटोहरू राख्नुहोस्',
      subtitle: 'राम्रो उज्यालोमा खिचेको फोटोले छिटो भाडामा जान्छ।',
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
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
                        isGoalMet ? 'न्यूनतम फोटो पुग्यो!' : 'फोटोको संख्या: $photoCount/5',
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
              if (!isGoalMet)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'कम्तिमा ५ वटा फोटो भएमा कोठा छिटो भाडामा जान्छ।',
                    style: GoogleFonts.notoSansDevanagari(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Upload Button ──────────────────────────────────────────────────
        GestureDetector(
          onTap: _pickImages,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppTheme.brandColor.withOpacity(0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.brandColor.withOpacity(0.2),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandColor.withOpacity(0.15),
                          blurRadius: 12,
                        )
                      ],
                    ),
                    child: const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.brandColor, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'फोटोहरू थप्नुहोस् (Add Photos)',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTheme.brandColor,
                    ),
                  ),
                  Text(
                    'बहु-चयन (Multi-select) गर्न मिल्छ',
                    style: GoogleFonts.notoSansDevanagari(
                      fontSize: 12,
                      color: AppTheme.brandColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 32),
          Row(
            children: [
              Text(
                'तपाईंका फोटोहरू',
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_selectedImages.length}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              final isCover = index == 0;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        _selectedImages[index],
                        fit: BoxFit.cover,
                      ),
                      // Gradient overlay for buttons
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                              stops: const [0.0, 0.3, 0.7, 1.0],
                            ),
                          ),
                        ),
                      ),
                      if (isCover)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'MAIN',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            setState(() => _selectedImages.removeAt(index));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStepVideo() {
    return StepLayout(
      title: 'भिडियोले अझै धेरैलाई आकर्षित गर्छ',
      subtitle: 'कोठाको छोटो भिडियो (Reel) राख्नुहोस्।',
      content: [
        GestureDetector(
          onTap: _pickVideo,
          child: _buildMediaUploadBox(
            icon: Icons.videocam_outlined,
            title: _selectedVideo != null
                ? 'भिडियो छानियो ✓'
                : 'भिडियो राख्नुहोस् (Upload Reel)',
            desc: _selectedVideo != null
                ? 'भिडियो परिवर्तन गर्न यहाँ क्लिक गर्नुहोस्'
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
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildStepTitleDesc() {
    return StepLayout(
      title: 'शीर्षक र विवरण',
      subtitle: 'आफ्नो प्रोपर्टीको बारेमा बताउनुहोस्।',
      content: [
        Text(
          'आकर्षक शीर्षक छान्नुहोस् (Choose a Title)',
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildAiTitleChip('कोठा भाडामा (Room for Rent)'),
            _buildAiTitleChip('बबाल फ्ल्याट (Awesome Flat)'),
            _buildAiTitleChip('Best Place in ${_areaController.text}'),
            _buildAiTitleChip('Beautiful Room near ${_landmarkController.text}'),
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
      ],
    );
  }

  Widget _buildAiTitleChip(String title) {
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
          borderRadius: BorderRadius.circular(30),
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

  Widget _buildStepPricingRules() {
    return StepLayout(
      title: 'भाडा र नियमहरू',
      subtitle: 'मासिक भाडा र घरका नियमहरू तोक्नुहोस्।',
      content: [
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
              color: _isNegotiable
                  ? AppTheme.brandColor.withOpacity(0.04)
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isNegotiable
                    ? AppTheme.brandColor
                    : const Color(0xFFE2E8F0),
                width: _isNegotiable ? 2 : 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isNegotiable
                        ? AppTheme.brandColor
                        : const Color(0xFFF1F5F9),
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
        const SizedBox(height: 40),
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

  Widget _buildStepPayout() {
    return StepLayout(
      title: 'अन्तिम विवरण र भुक्तानी',
      subtitle: 'विवरण थप्नुहोस् र कसरी पैसा लिने रोज्नुहोस्।',
      content: [
        // ── AI Description Section ──────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
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
                    Text(
                      'AI विवरण (AI Description)',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTheme.brandColor,
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
                          : const Icon(Icons.flash_on_rounded, size: 16),
                        label: Text(
                          _isGeneratingDescription ? 'लेख्दै छ...' : 'AI बाट विवरण लेख्नुहोस्',
                          style: GoogleFonts.notoSansDevanagari(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // ── Payout Section ────────────────────────────────────────────────
        Text(
          'तपाईं कसरी पैसा लिन चाहनुहुन्छ?',
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildPayoutTypeSelector('eSewa', 'esewa', Icons.account_balance_wallet_rounded, const Color(0xFF60BB46)),
            const SizedBox(width: 16),
            _buildPayoutTypeSelector('Khalti', 'khalti', Icons.account_balance_wallet_rounded, const Color(0xFF5C2D91)),
          ],
        ),
        const SizedBox(height: 24),
        PropertyFormField(
          label: '${_selectedPayoutMethod == 'esewa' ? 'eSewa' : 'Khalti'} नम्बर राख्नुहोस्',
          hint: '98XXXXXXXX',
          controller: _payoutAccountController,
          isRequired: true,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_android_rounded,
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_outlined, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'सबै जानकारी सुरक्षित छ। तपाईंको विज्ञापन प्रमाणित भएपछि मात्र सार्वजनिक हुनेछ। (Your listing is secure and will be published after verification.)',
                  style: GoogleFonts.notoSansDevanagari(
                    color: Colors.green[800],
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              if (assetIcon != null)
                Image.asset(
                  assetIcon,
                  height: 24,
                  width: 24,
                  fit: BoxFit.contain,
                )
              else
                Icon(icon, color: isSelected ? color : Colors.grey[500]),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? color : Colors.grey[600],
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
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
        ),
        child: Row(
          children: [
            if (_currentStep > 0)
              SizedBox(
                width: 100,
                child: OutlinedButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    setState(() => _currentStep--);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF4B5563),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _currentStep == (_totalSteps - 1)
                    ? (_isPublishing ? null : _nextStep)
                    : () {
                        HapticFeedback.lightImpact();
                        _nextStep();
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: _currentStep == (_totalSteps - 1)
                      ? Colors.green
                      : AppTheme.brandColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isPublishing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        _currentStep == (_totalSteps - 1) ? 'Publish' : 'Next',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white,
                        ),
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
