import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';
import 'package:geocoding/geocoding.dart' as geo;
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
  final int _totalSteps = 10;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController();
  final ScrollController _mainScrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  late ConfettiController _confettiController;

  // Form State
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
  bool _isEstimatingPrice = false;
  String? _aiPriceSuggestion;
  double _distanceFromLandmark = 0.0;
  bool _isDistanceVerified = false;
  bool _isAnalyzingLocation = false;
  bool _isGeneratingDescription = false;
  bool _isGeneratingVideoCaption = false;
  bool _showLocationNudge = false;

  // AI Insights Step
  bool _isLoadingAiInsights = false;
  bool _aiInsightsLoaded = false;
  String? _aiPriceAnalysis;
  String? _aiNeighborhoodVibe;

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
      if (_selectedAmenities.contains(amenity))
        _selectedAmenities.remove(amenity);
      else
        _selectedAmenities.add(amenity);
    });
  }

  void _toggleRule(String rule) {
    setState(() {
      if (_selectedRules.contains(rule))
        _selectedRules.remove(rule);
      else
        _selectedRules.add(rule);
    });
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
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('कृपया सेटिङ्सबाट लोकेशन अन गर्नुहोस्।'),
            ),
          );
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
          const SnackBar(content: Text('एआईले तपाईंको ठाउँ खोज्दैछ... 🤖')),
        );
        final locData = await _aiService.autoDetectLocationArea(
          position.latitude,
          position.longitude,
        );
        if (mounted) {
          setState(() {
            if (locData['area']?.isNotEmpty == true)
              _areaController.text = locData['area']!;
            if (locData['landmark']?.isNotEmpty == true)
              _landmarkController.text = locData['landmark']!;
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
    String errorMessage = "";
    FocusScope.of(context).unfocus();

    switch (_currentStep) {
      case 0:
        if (_selectedCategory == null)
          errorMessage = "कृपया सम्पत्तिको प्रकार छान्नुहोस्।";
        else
          isValid = true;
        break;
      case 1:
        if (_areaController.text.trim().isEmpty)
          errorMessage = "कृपया टोलको नाम राख्नुहोस्।";
        else if (_landmarkController.text.trim().isEmpty)
          errorMessage = "कृपया नजिकैको प्रख्यात ठाउँ राख्नुहोस्।";
        else if (_latitude == null) {
          setState(() => _showLocationNudge = true);
          errorMessage = "कृपया नक्सामा लोकेशन सेट गर्नुहोस्।";
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
        if (_selectedImages.length < 5)
          errorMessage =
              "कृपया कम्तिमा ५ वटा फोटोहरू राख्नुहोस्। (At least 5 photos required)";
        else
          isValid = true;
        break;
      case 5:
        isValid = true; // Video is optional
        break;
      case 6:
        if (_titleController.text.trim().isEmpty)
          errorMessage = "कृपया प्रोपर्टीको आकर्षक शीर्षक राख्नुहोस्।";
        else
          isValid = true;
        break;
      case 7:
        if (_priceController.text.trim().isEmpty &&
            _priceNightController.text.trim().isEmpty) {
          errorMessage = "कृपया मासिक वा दैनिक भाडा राख्नुहोस्।";
        } else {
          isValid = true;
          // Auto-trigger AI insights on price page exit
          if (!_aiInsightsLoaded) _runAiInsights();
        }
        break;
      case 8: // AI Insights — always passable
        isValid = true;
        break;
      case 9: // Payout
        if (_payoutAccountController.text.trim().isEmpty) {
          errorMessage = "तपाईंले पेमेन्ट पाउनको लागि खाता नम्बर राख्नुहोस्।";
        } else
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
          content: Text(errorMessage),
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
        category: _selectedCategory ?? 'Room',
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
              category: _selectedCategory ?? 'Property',
              price: _priceController.text,
              submittedAt: DateTime.now(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Publishing failed: $e')));
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
        title: Transform.translate(
          offset: const Offset(0, 2),
          child: Text(
            'सम्पत्ति राख्नुहोस्',
            style: GoogleFonts.notoSansDevanagari(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
        ),
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.brandColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentStep + 1} / $_totalSteps',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.brandColor,
                  fontSize: 16,
                  letterSpacing: -0.5,
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
                    _buildStepAiInsights(),
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
      title: 'तपाईंको सम्पत्ति कस्तो प्रकारको हो?',
      subtitle: 'Choose your property type',
      content: [
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
              imagePath: 'assets/images/single room (2).png',
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
              label: 'घर / House',
              imagePath: 'assets/images/tiny house.png',
              value: 'House',
              imageScale: 1.8,
              selectedValue: _selectedCategory,
              onSelect: (v) => setState(() => _selectedCategory = v),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepLocation() {
    return StepLayout(
      title: 'तपाईंको सम्पत्ति कहाँ छ?',
      subtitle:
          'सही जानकारीले ग्राहकको विश्वास जित्न सजिलो हुन्छ। (Accurate location builds trust)',
      content: [
        PremiumFeatureCard(
          icon: _latitude != null ? Icons.location_on : Icons.my_location,
          title: _latitude != null
              ? 'लोकेशन प्रमाणित भयो'
              : 'नक्सामा ठाउँ देखाउनुहोस्',
          subtitle: _latitude != null
              ? 'GPS verified location detected'
              : 'Use GPS for maximum listing trust',
          accentColor: _latitude != null ? Colors.green : AppTheme.brandColor,
          isLoading: _isLocating,
          child: Column(
            children: [
              if (_showLocationNudge && _latitude == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.back_hand,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'पहिला यहाँ क्लिक गर्नुहोस्!',
                        style: GoogleFonts.notoSansDevanagari(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ElevatedButton.icon(
                onPressed: _isLocating
                    ? null
                    : () {
                        setState(() => _showLocationNudge = false);
                        _detectLocation();
                      },
                icon: _isLocating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        _latitude != null ? Icons.refresh : Icons.gps_fixed,
                        size: 20,
                        color: Colors.white,
                      ),
                label: Text(
                  _isLocating
                      ? 'खोज्दै छ...'
                      : _latitude != null
                      ? 'फेरि खोज्नुहोस्'
                      : 'मेरो ठाउँ खोज्नुहोस्',
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _latitude != null
                      ? Colors.green
                      : AppTheme.brandColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        PropertyFormField(
          label: 'टोल वा ठाउँको नाम (Area Name)',
          hint: 'उदा: ललितपुर, सानेपा-२',
          controller: _areaController,
          isRequired: true,
        ),
        const SizedBox(height: 24),
        PropertyFormField(
          label: 'चिनिने ठाउँ (Landmark)',
          hint: 'उदा: सिभिल हस्पिटलको पछाडि',
          controller: _landmarkController,
          isRequired: true,
        ),
      ],
    );
  }

  Widget _buildStepBasics() {
    return StepLayout(
      title: 'कोठाको विवरण राख्नुहोस्',
      subtitle:
          'यसले मानिसहरूलाई तपाईंको ठाउँको बारेमा जान्न मद्दत गर्छ। (Share the basics)',
      content: [
        Row(
          children: [
            Expanded(
              child: PropertyFormField(
                label: 'कतिवटा बेडरुम? (Beds)',
                hint: 'उदा: २',
                controller: _bedroomsController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PropertyFormField(
                label: 'कतिवटा बाथरुम? (Baths)',
                hint: 'उदा: १',
                controller: _bathroomsController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: PropertyFormField(
                label: 'कुन तलामा छ? (Floor)',
                hint: 'उदा: १',
                controller: _floorController,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PropertyFormField(
                label: 'क्षेत्रफल (Area sq.ft)',
                hint: 'उदा: ४००',
                controller: _sqftController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepAmenities() {
    return StepLayout(
      title: 'के-के सुविधाहरू छन्?',
      subtitle:
          'राम्रो सुविधाहरूले धेरै ग्राहक आकर्षित गर्छ। (Amenities attract better tenants)',
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
    return StepLayout(
      title: 'केही राम्रा फोटोहरू राख्नुहोस्',
      subtitle:
          'राम्रो उज्यालोमा खिचेको फोटोले छिटो भाडामा जान्छ। (Add at least 5 high-quality photos)',
      content: [
        GestureDetector(
          onTap: _pickImages,
          child: _buildMediaUploadBox(
            icon: Icons.add_a_photo_outlined,
            title: 'फोटोहरू थप्नुहोस् (Add Photos)',
            desc: '५ वा सोभन्दा बढी फोटो राख्नुहोस्।',
            isBlue: false,
          ),
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'छानिएका फोटोहरू (${_selectedImages.length})',
            style: GoogleFonts.notoSansDevanagari(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(_selectedImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedImages.removeAt(index)),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
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
      subtitle:
          'कोठाको छोटो भिडियो (Reel) राख्नुहोस्। (Optional but highly recommended)',
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
          PremiumFeatureCard(
            icon: Icons.auto_awesome_rounded,
            title: 'भिडियो क्याप्सन (AI Reel Caption)',
            subtitle: 'भिडियोको लागि आकर्षक विवरण लेख्नुहोस्',
            isLoading: _isGeneratingVideoCaption,
            accentColor: Colors.blue,
            child: Column(
              children: [
                TextField(
                  controller: _videoCaptionController,
                  maxLines: 3,
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'भिडियोको बारेमा केही लेख्नुहोस्...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingVideoCaption
                        ? null
                        : () async {
                            HapticFeedback.mediumImpact();
                            setState(() => _isGeneratingVideoCaption = true);
                            final caption = await _aiService.generateVideoCaption(
                              category: _selectedCategory ?? 'Room',
                              area: _areaController.text,
                              landmark: _landmarkController.text,
                              price: _priceController.text.isNotEmpty 
                                  ? _priceController.text 
                                  : _priceNightController.text,
                            );
                            setState(() {
                              _videoCaptionController.text = caption;
                              _isGeneratingVideoCaption = false;
                            });
                          },
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Text(
                      'AI बाट क्याप्सन लेख्नुहोस्',
                      style: GoogleFonts.notoSansDevanagari(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

  Widget _buildStepTitleDesc() {
    return StepLayout(
      title: 'आकर्षक शीर्षक र विवरण',
      subtitle:
          'तपाईंको प्रोपर्टीको बारेमा बताउनुहोस्। (Give it a catchy title and description)',
      content: [
        PropertyFormField(
          label: 'आकर्षक शीर्षक राख्नुहोस् (Title)',
          hint: 'e.g. Cozy 2-bedroom flat in Sanepa',
          controller: _titleController,
          isRequired: true,
        ),
        const SizedBox(height: 32),
        PremiumFeatureCard(
          icon: Icons.auto_awesome_rounded,
          title: 'आकर्षक विवरण (AI Description)',
          subtitle: 'एकै क्लिकमा राम्रो विवरण लेख्नुहोस्',
          isLoading: _isGeneratingDescription,
          accentColor: AppTheme.brandColor,
          child: Column(
            children: [
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText:
                      'आफ्नो प्रोपर्टीको बारेमा लेख्नुहोस् वा तल क्लिक गर्नुहोस्...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.brandColor,
                      width: 1.5,
                    ),
                  ),
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
                            bedrooms: _bedroomsController.text,
                            bathrooms: _bathroomsController.text,
                            floor: _floorController.text,
                            sqft: _sqftController.text,
                            isNegotiable: _isNegotiable,
                            amenities: [
                              ..._selectedAmenities,
                              ..._selectedRules,
                            ],
                          );
                          setState(() {
                            _descriptionController.text = desc;
                            _isGeneratingDescription = false;
                          });
                        },
                  icon: const Icon(Icons.flash_on_rounded, size: 18),
                  label: Text(
                    'AI बाट लेख्नुहोस् (Auto Generate)',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepPricingRules() {
    return StepLayout(
      title: 'भाडा र नियमहरू',
      subtitle: 'Set your price and house rules.',
      content: [
        PropertyFormField(
          label: 'मासिक भाडा (Monthly Rent)',
          hint: 'उदा: ५०००',
          controller: _priceController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        PropertyFormField(
          label: 'प्रति रात भाडा (Price Per Night)',
          hint: 'उदा: ८०० (Optional)',
          controller: _priceNightController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        StatefulBuilder(
          builder: (context, setInternalState) {
            return GestureDetector(
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
                        : Colors.grey.shade200,
                    width: _isNegotiable ? 2.5 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isNegotiable
                            ? AppTheme.brandColor
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.handshake_rounded,
                        color: _isNegotiable ? Colors.white : Colors.grey[400],
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'भाडा मिलाउन सकिने',
                            style: GoogleFonts.notoSansDevanagari(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: const Color(0xFF111827),
                              height: 1.2,
                            ),
                          ),
                          Text(
                            'Price is Negotiable',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
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
            );
          },
        ),
        const SizedBox(height: 40),
        Text(
          'घरका नियमहरू (House Rules)',
          style: GoogleFonts.notoSansDevanagari(fontSize: 18, fontWeight: FontWeight.w800),
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

  // ─── AI Insights Helpers ─────────────────────────────────────────────────

  Future<void> _runAiInsights() async {
    if (_aiInsightsLoaded) return;
    setState(() => _isLoadingAiInsights = true);
    final price = _priceController.text.isNotEmpty
        ? _priceController.text
        : _priceNightController.text;
    final bedrooms = int.tryParse(_bedroomsController.text) ?? 1;

    final results = await Future.wait([
      _aiService.estimatePrice(_areaController.text, bedrooms, _selectedCategory ?? 'Room'),
      _aiService.verifyLocation(_areaController.text, _landmarkController.text),
    ]);

    if (mounted) {
      setState(() {
        _aiPriceAnalysis = results[0];
        _aiNeighborhoodVibe = results[1];
        _isLoadingAiInsights = false;
        _aiInsightsLoaded = true;
      });
    }
  }

  int _calcListingScore() {
    int score = 0;
    if (_titleController.text.trim().length > 10) score += 15;
    if (_descriptionController.text.trim().length > 50) score += 20;
    if (_selectedImages.length >= 5) score += 20;
    if (_selectedImages.length >= 8) score += 5;
    if (_selectedVideo != null) score += 15;
    if (_selectedAmenities.length >= 4) score += 10;
    if (_latitude != null) score += 10;
    if (_priceController.text.isNotEmpty || _priceNightController.text.isNotEmpty) score += 5;
    return score.clamp(0, 100);
  }

  // ─── AI Insights Step ────────────────────────────────────────────────────

  Widget _buildStepAiInsights() {
    final score = _calcListingScore();
    final Color scoreColor = score >= 80
        ? const Color(0xFF22C55E)
        : score >= 55
        ? Colors.orange
        : Colors.redAccent;

    return StepLayout(
      title: 'तपाईंको लिस्टिङ AI विश्लेषण',
      subtitle: 'AI Review — Listing Quality, Price Check & Neighborhood Vibe',
      content: [
        // ── Listing Score Card ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scoreColor.withOpacity(0.08),
                scoreColor.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: scoreColor.withOpacity(0.25), width: 1.5),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome_rounded, color: scoreColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Listing Quality Score',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: score / 100),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(value * 100).round()}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: scoreColor,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          score >= 80
                              ? '🌟 Excellent!'
                              : score >= 55
                              ? '👍 Good'
                              : '⚡ Needs Work',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: scoreColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Tips
              ...[
                if (_selectedImages.length < 5)
                  _buildTip('📸', 'Add at least 5 photos to boost visibility'),
                if (_selectedVideo == null)
                  _buildTip('🎬', 'Add a video reel for 3× more enquiries'),
                if (_descriptionController.text.trim().length < 50)
                  _buildTip('✍️', 'Write a longer description to build trust'),
                if (_selectedAmenities.length < 4)
                  _buildTip('✅', 'Select more amenities guests look for'),
                if (_latitude == null)
                  _buildTip('📍', 'Set GPS location to unlock map directions'),
                if (score >= 80)
                  _buildTip('🎉', 'Your listing looks great! Ready to publish.'),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── AI Price Analysis Card ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppTheme.brandColor.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.price_check_rounded, color: AppTheme.brandColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Price Analysis',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Based on your area & room type',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  if (!_aiInsightsLoaded)
                    GestureDetector(
                      onTap: _runAiInsights,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.brandColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Run AI',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (_isLoadingAiInsights)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const CircularProgressIndicator(
                        color: AppTheme.brandColor,
                        strokeWidth: 2.5,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Analyzing market prices...',
                        style: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_aiPriceAnalysis != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _aiPriceAnalysis!,
                    style: GoogleFonts.notoSansDevanagari(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                )
              else
                Text(
                  'Tap "Run AI" above to get a price recommendation.',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Neighborhood Vibe Card ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_city_rounded, color: Colors.purple, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Neighborhood Vibe',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Nearby schools, hospitals & more',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_isLoadingAiInsights)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const CircularProgressIndicator(
                        color: Colors.purple,
                        strokeWidth: 2.5,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Scanning neighborhood...',
                        style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                )
              else if (_aiNeighborhoodVibe != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _aiNeighborhoodVibe!,
                    style: GoogleFonts.notoSansDevanagari(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                )
              else
                Text(
                  'AI neighborhood analysis will appear here.',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Skip hint ───────────────────────────────────────────────────────
        Center(
          child: Text(
            'Tap "Continue" to proceed to payment setup →',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTip(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPayout() {
    return StepLayout(
      title: 'तपाईं कसरी पैसा लिन चाहनुहुन्छ?',
      subtitle:
          'Choose how you want to receive payments from bookings. (Payout Method)',
      content: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'अतिथिले बुकिङ गर्दा, तपाईंको पैसा सिधै यो खातामा आउनेछ। (Booking payouts will go to this account automatically)',
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.blue[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            _buildPayoutTypeSelector(
              'eSewa',
              'esewa',
              Icons.account_balance_wallet,
              const Color(0xFF60BB46),
              'assets/images/esewa.webp',
            ),
            const SizedBox(width: 16),
            _buildPayoutTypeSelector(
              'Khalti',
              'khalti',
              Icons.account_balance_wallet,
              const Color(0xFF5C2D91),
              'assets/images/khalti.png',
            ),
            const SizedBox(width: 16),
            _buildPayoutTypeSelector(
              'Bank',
              'bank',
              Icons.account_balance,
              Colors.blueGrey,
            ),
          ],
        ),
        const SizedBox(height: 32),
        PropertyFormField(
          label: _selectedPayoutMethod == 'bank'
              ? 'बैंक खाता नम्बर (Bank Account No.)'
              : 'खाताको नम्बर (${_selectedPayoutMethod.toUpperCase()} ID)',
          hint: _selectedPayoutMethod == 'bank'
              ? 'Account Number'
              : 'e.g. 98XXXXXXXX',
          controller: _payoutAccountController,
          isRequired: true,
          keyboardType: TextInputType.text,
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
