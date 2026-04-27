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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController();
  final ScrollController _step1ScrollController = ScrollController();
  final FocusNode _titleFocusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  late ConfettiController _confettiController;

  // Form State
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _bedroomsController = TextEditingController();
  final TextEditingController _bathroomsController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _sqftController = TextEditingController();

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
  bool _isPublishing = false;

  // AI Service (Using Khozna AI)
  final KhoznaAiService _aiService = KhoznaAiService();
  bool _isEstimatingPrice = false;
  String? _aiPriceSuggestion;

  // Media State
  File? _selectedVideo;
  final bool _isUploadingVideo = false;

  // Smart Check Radius State
  double _distanceFromLandmark = 0.0;
  bool _isDistanceVerified = false;

  // New Location Analysis State
  bool _isAnalyzingLocation = false;

  // AI Description State
  bool _isGeneratingDescription = false;

  // Visual Guides
  bool _showLocationNudge = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _titleController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _floorController.dispose();
    _sqftController.dispose();
    _pageController.dispose();
    _step1ScrollController.dispose();
    _titleFocusNode.dispose();
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

  Future<void> _pickImages() async {

    final List<XFile> images = await _picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideo = File(video.path);
      });
    }
  }

  Future<void> _publishProperty() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to post a property')));
      return;
    }

    if (_titleController.text.isEmpty || _priceController.text.isEmpty || _selectedImages.isEmpty || _areaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("कृपया सबै रित्तो ठाउँ भर्नुहोस् (Please fill all required fields)")));
      return;
    }

    setState(() => _isPublishing = true);

    try {
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
      );

      _confettiController.play();
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        final ownerName = user.userMetadata?['full_name'] ?? user.email ?? 'Property Owner';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PropertySuccessScreen(
              ownerName: ownerName,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Publishing failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
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
            const SnackBar(content: Text('Location permission denied. Please enable it in Settings.')),
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
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('एआईले तपाईंको ठाउँ खोज्दैछ... 🤖\n(AI is predicting your Area)')),
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

          if (locData['area']?.isNotEmpty == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('AI found your location: ${locData['area']}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
      }
    }
  }

  void _nextStep() {
    bool isValid = false;
    String errorMessage = "";

    FocusScope.of(context).unfocus();

    if (_currentStep == 0) {
      if (_titleController.text.trim().isEmpty) {
        errorMessage = "कृपया शीर्षक राख्नुहोस् (Please enter a title)";
      } else if (_selectedCategory == null) {
        errorMessage = "कृपया वर्ग छान्नुहोस् (Please select a category)";
      } else {
        isValid = true;
      }
    } else if (_currentStep == 1) {
      if (_areaController.text.trim().isEmpty) {
        errorMessage = "कृपया टोलको नाम राख्नुहोस् (Please enter Area Name)";
      } else if (_landmarkController.text.trim().isEmpty) {
        errorMessage = "कृपया चिनिने ठाउँ राख्नुहोस् (Please enter Landmark)";
      } else if (_latitude == null) {
        setState(() => _showLocationNudge = true);
        errorMessage = "कृपया नक्शामा लोकेशन सेट गर्नुहोस् (Please set location on Map)";
      } else {
        isValid = true;
      }
    } else if (_currentStep == 2) {
      if (_priceController.text.trim().isEmpty) {
        errorMessage = "कृपया भाडा दर राख्नुहोस् (Please enter Price)";
      } else {
        isValid = true;
      }
    } else {
      isValid = true;
    }

    if (isValid) {
      if (_currentStep < 5) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep++);
      }
    } else if (errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        title: Text(
          'प्रोपर्टी राख्नुहोस्',
          style: GoogleFonts.hind(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.brandColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.brandColor.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Text(
                '${_currentStep + 1} / 6',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.brandColor,
                  fontSize: 12,
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
                height: 14,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: (_currentStep + 1) / 6),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutCubic,
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandColor),
                    );
                  },
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
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildStep4(),
                    _buildStep5(),
                    _buildStep6(),
                  ],
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [AppTheme.brandColor, Colors.blue, Colors.green, Colors.orange, Colors.pink],
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

  Widget _buildStep1() {
    return StepLayout(
      controller: _step1ScrollController,
      title: 'तपाईं के भाडामा दिँदै हुनुहुन्छ?',
      subtitle: 'सुरु गरौं! (Let\'s start your listing)',
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
              label: 'कोठा\nRoom',
              icon: CupertinoIcons.bed_double_fill,
              value: 'Room',
              selectedValue: _selectedCategory,
              onSelect: (v) => setState(() => _selectedCategory = v),
            ),
            CategoryCard(
              label: 'फ्ल्याट\nFlat',
              icon: CupertinoIcons.house_fill,
              value: 'Flat',
              selectedValue: _selectedCategory,
              onSelect: (v) => setState(() => _selectedCategory = v),
            ),
            CategoryCard(
              label: 'सटर / पसल\nCommercial',
              icon: Icons.storefront_rounded,
              value: 'Shop',
              selectedValue: _selectedCategory,
              onSelect: (v) => setState(() => _selectedCategory = v),
            ),
            CategoryCard(
              label: 'अन्य\nOther',
              icon: CupertinoIcons.ellipsis,
              value: 'Other',
              selectedValue: _selectedCategory,
              onSelect: (v) => setState(() => _selectedCategory = v),
            ),
          ],
        ),
        const SizedBox(height: 24),
        PropertyFormField(
          label: 'विज्ञापनको नाम (Title)',
          hint: 'e.g. Cozy 2-bedroom flat',
          controller: _titleController,
          focusNode: _titleFocusNode,
          isRequired: true,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return StepLayout(
      title: 'प्रोपर्टी कहाँ छ?',
      subtitle: 'Accurate location builds trust',
      content: [
        PremiumFeatureCard(
          icon: _latitude != null ? Icons.location_on : Icons.my_location,
          title: _latitude != null ? 'लोकेशन सेट भयो! ✓' : 'लोकेशन राख्नुहोस्',
          subtitle: _latitude != null ? 'GPS verified location detected by AI' : 'Use GPS for maximum listing trust',
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
                      const Icon(Icons.back_hand, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'पहिला बटन थिच्नुहोस्! (Click here first)',
                        style: GoogleFonts.mukta(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
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
                          : 'मेरो लोकेशन पत्ता लगाउनुहोस्',
                  style: GoogleFonts.mukta(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _latitude != null ? Colors.green : AppTheme.brandColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        PropertyFormField(
          label: 'नगरपालिका / टोल (Area Name)',
          hint: 'उदा: ललितपुर, सानेपा-२',
          controller: _areaController,
          isRequired: true,
        ),
        const SizedBox(height: 24),
        PropertyFormField(
          label: 'नजिकैको चिनिने ठाउँ (Landmark)',
          hint: 'उदा: सिभिल हस्पिटलको पछाडि',
          controller: _landmarkController,
          isRequired: true,
        ),
        const SizedBox(height: 24),
        if (_areaController.text.isNotEmpty || _landmarkController.text.isNotEmpty)
          PremiumFeatureCard(
            icon: Icons.gps_fixed_rounded,
            title: 'Distance Check',
            subtitle: 'Must be within 250m for verification',
            isLoading: _isAnalyzingLocation,
            accentColor: _latitude == null ? Colors.grey : (_isDistanceVerified ? Colors.green : Colors.orange),
            child: Column(
              children: [
                if (_latitude != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (1.0 - (_distanceFromLandmark / 1000).clamp(0.0, 1.0)),
                      minHeight: 10,
                      backgroundColor: Colors.grey[100],
                      color: _isDistanceVerified ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isDistanceVerified ? 'Verified Accuracy' : 'Low Accuracy',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: _isDistanceVerified ? Colors.green[800] : Colors.orange[800],
                        ),
                      ),
                      Text(
                        '${_distanceFromLandmark.toStringAsFixed(0)}m away',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isAnalyzingLocation || _latitude == null)
                        ? null
                        : () async {
                            setState(() => _isAnalyzingLocation = true);
                            try {
                              List<geo.Location> locations = await geo.locationFromAddress(
                                  "${_landmarkController.text}, ${_areaController.text}");
                              if (locations.isNotEmpty) {
                                double dist = Geolocator.distanceBetween(
                                  _latitude!, _longitude!,
                                  locations.first.latitude, locations.first.longitude,
                                );
                                setState(() {
                                  _distanceFromLandmark = dist;
                                  _isDistanceVerified = dist <= 250;
                                });
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Verification failed. Use landmark name correctly.')),
                              );
                            } finally {
                              setState(() => _isAnalyzingLocation = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandColor.withOpacity(0.1),
                      foregroundColor: AppTheme.brandColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Start Smart Check'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStep3() {
    return StepLayout(
      title: 'भाडा र विवरण',
      subtitle: 'Almost halfway! High precision earns trust.',
      content: [
        PropertyFormField(
          label: 'महिनाको जम्मा भाडा (Monthly Rent)',
          hint: 'उदा: ५०००',
          controller: _priceController,
          keyboardType: TextInputType.number,
          isRequired: true,
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              QuickPriceChip(label: '५,०००', value: '5000', currentValue: _priceController.text, onTap: (v) => setState(() => _priceController.text = v)),
              const SizedBox(width: 8),
              QuickPriceChip(label: '८,०००', value: '8000', currentValue: _priceController.text, onTap: (v) => setState(() => _priceController.text = v)),
              const SizedBox(width: 8),
              QuickPriceChip(label: '१२,०००', value: '12000', currentValue: _priceController.text, onTap: (v) => setState(() => _priceController.text = v)),
              const SizedBox(width: 8),
              QuickPriceChip(label: '१५,०००', value: '15000', currentValue: _priceController.text, onTap: (v) => setState(() => _priceController.text = v)),
              const SizedBox(width: 8),
              QuickPriceChip(label: '२५,०००', value: '25000', currentValue: _priceController.text, onTap: (v) => setState(() => _priceController.text = v)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: PropertyFormField(
                label: 'Beds',
                hint: 'उदा: २',
                controller: _bedroomsController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PropertyFormField(
                label: 'Baths',
                hint: 'उदा: १',
                controller: _bathroomsController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: PropertyFormField(
                label: 'Floor',
                hint: 'उदा: १',
                controller: _floorController,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PropertyFormField(
                label: 'Area (sq.ft)',
                hint: 'उदा: ४००',
                controller: _sqftController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _isNegotiable = !_isNegotiable);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: _isNegotiable ? AppTheme.brandColor.withOpacity(0.05) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _isNegotiable ? AppTheme.brandColor : const Color(0xFFE5E7EB), width: 2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _isNegotiable ? AppTheme.brandColor : Colors.white, shape: BoxShape.circle),
                  child: Icon(Icons.handshake_rounded, color: _isNegotiable ? Colors.white : Colors.grey[400], size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('भाडा मिलाउन सकिन्छ', style: GoogleFonts.mukta(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF111827))),
                      Text('Price is Negotiable', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500])),
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
        ),
        const SizedBox(height: 32),
        PremiumFeatureCard(
          icon: Icons.insights_rounded,
          title: 'Price Guide',
          subtitle: 'AI neighborhood analysis',
          isLoading: _isEstimatingPrice,
          accentColor: Colors.purple,
          child: Column(
            children: [
              if (_aiPriceSuggestion != null)
                Text(_aiPriceSuggestion!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF4B5563), height: 1.5)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isEstimatingPrice
                      ? null
                      : () async {
                          if (_areaController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please set area in Step 2 first')));
                            return;
                          }
                          setState(() => _isEstimatingPrice = true);
                          final result = await _aiService.estimatePrice(_areaController.text, _selectedCategory == 'Room' ? 1 : 3, _selectedCategory ?? 'Room');
                          setState(() {
                            _aiPriceSuggestion = result;
                            _isEstimatingPrice = false;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    foregroundColor: Colors.purple,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Check Neighborhood Price'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return StepLayout(
      title: 'सुविधाहरू छान्नुहोस्',
      subtitle: 'Higher quality amenities attract better tenants.',
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
            'hot_water': Icons.solar_power_rounded,
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
            'hot_water': 'सोलार / तातो पानी',
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

  Widget _buildStep5() {
    return StepLayout(
      title: 'नियमहरू राख्नुहोस्',
      subtitle: 'Sets expectations for potential tenants.',
      content: [
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

  Widget _buildStep6() {
    return StepLayout(
      title: 'फोटो/भिडियो र विवरण',
      subtitle: 'Final step! Make it look irresistible.',
      content: [
        PremiumFeatureCard(
          icon: Icons.auto_awesome_rounded,
          title: 'AI Description Writer',
          subtitle: 'Professional text using your provided info',
          isLoading: _isGeneratingDescription,
          accentColor: AppTheme.brandColor,
          child: Column(
            children: [
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                style: GoogleFonts.mukta(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Describe your property or tap Generate...',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingDescription ? null : () async {
                    setState(() => _isGeneratingDescription = true);
                    final desc = await _aiService.generateDescription(
                      title: _titleController.text,
                      category: _selectedCategory ?? 'Room',
                      area: _areaController.text,
                      landmark: _landmarkController.text,
                      amenities: _selectedAmenities,
                    );
                    setState(() {
                      _descriptionController.text = desc;
                      _isGeneratingDescription = false;
                    });
                  },
                  icon: const Icon(Icons.flash_on_rounded, size: 16),
                  label: const Text('Generate with AI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandColor.withOpacity(0.1),
                    foregroundColor: AppTheme.brandColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _pickImages,
          child: _buildMediaUploadBox(icon: Icons.add_a_photo_outlined, title: 'Add Photos', desc: 'Adding 3 or more photos increases your chances of a quick rental.', isBlue: false),
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 100,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: FileImage(_selectedImages[index]), fit: BoxFit.cover)),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImages.removeAt(index)),
                      child: Container(margin: const EdgeInsets.all(4), padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _pickVideo,
          child: _buildMediaUploadBox(
            icon: Icons.videocam_outlined,
            title: _selectedVideo != null ? 'Video Selected ✓' : 'Upload Reel',
            desc: _selectedVideo != null ? 'Tap to change video' : 'Videos attract 3x more tenants!',
            isBlue: true,
            hasFile: _selectedVideo != null,
          ),
        ),
        if (_selectedVideo != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.video_file, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(child: Text('Video: ${_selectedVideo!.path.split('/').last}', style: GoogleFonts.inter(fontSize: 12, color: Colors.blue[900]), overflow: TextOverflow.ellipsis)),
                IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 20), onPressed: () => setState(() => _selectedVideo = null)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.verified_outlined, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(child: Text('Your listing will be published after our team verifies it.', style: GoogleFonts.inter(color: Colors.green[800], fontSize: 14, height: 1.4, fontWeight: FontWeight.w600))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaUploadBox({required IconData icon, required String title, required String desc, required bool isBlue, bool hasFile = false}) {
    Color activeColor = isBlue ? Colors.blue : AppTheme.brandColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: hasFile ? activeColor.withOpacity(0.05) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: hasFile ? activeColor : const Color(0xFFE5E7EB), width: 2),
        boxShadow: hasFile ? [BoxShadow(color: activeColor.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))] : [],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: hasFile ? activeColor : Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: (hasFile ? activeColor : Colors.black).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Icon(hasFile ? Icons.check_rounded : icon, color: hasFile ? Colors.white : Colors.grey[400], size: 32),
          ),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: GoogleFonts.mukta(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(desc, textAlign: TextAlign.center, style: GoogleFonts.mukta(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1))),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {
                    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    setState(() => _currentStep--);
                  },
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), side: BorderSide(color: Colors.grey.shade300, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text('Back', style: GoogleFonts.inter(color: const Color(0xFF4B5563), fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _currentStep == 5 ? (_isPublishing ? null : _publishProperty) : () {
                  HapticFeedback.lightImpact();
                  _nextStep();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  backgroundColor: _currentStep == 5 ? Colors.green : AppTheme.brandColor,
                  elevation: 4,
                  shadowColor: (_currentStep == 5 ? Colors.green : AppTheme.brandColor).withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isPublishing
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Text(_currentStep == 5 ? 'Publish Listing' : 'Next Step', textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
