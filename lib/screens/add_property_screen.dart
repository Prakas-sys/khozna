import 'dart:io';
// firebase_auth removed
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../theme/app_theme.dart';
import '../utils/cloudinary_service.dart';
import '../utils/khozna_ai_service.dart';

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
  bool _isUploadingVideo = false;

  // Smart Check Radius State
  double _distanceFromLandmark = 0.0;
  bool _isDistanceVerified = false;

  // New Location Analysis State
  bool _isAnalyzingLocation = false;
  String? _aiLocationAnalysis;

  // AI Description State
  bool _isGeneratingDescription = false;

  // Visual Guides
  bool _showLocationNudge = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
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

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage(
      imageQuality: 70, // ⚡ FAST UPLOAD: Drastically reduces file size before upload
      maxWidth: 1920,   // ⚡ FAST UPLOAD: Limits resolution to HD
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
    final client = Supabase.instance.client;
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to post a property')),
      );
      return;
    }

    if (_titleController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _selectedImages.isEmpty ||
        _areaController.text.isEmpty) {
      String msg = "कृपया सबै रित्तो ठाउँ भर्नुहोस्";
      if (_selectedImages.isEmpty)
        msg = "कम्तिमा एउटा फोटो राख्नुहोस् (Add at least one photo)";

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    setState(() => _isPublishing = true);

    try {
      // 0. AI Scam Detector Check
      final String scamResult = await _aiService.detectScam(
        _titleController.text,
        _priceController.text,
        _areaController.text,
      );

      if (scamResult.toLowerCase().contains("scam") ||
          scamResult.toLowerCase().contains("warning")) {
        debugPrint("AI SCAM WARNING: $scamResult");
      }

      // 1. Upload Video if selected (Optional)
      String? videoUrl;
      if (_selectedVideo != null) {
        setState(() => _isUploadingVideo = true);
        videoUrl = await CloudinaryService.uploadVideo(_selectedVideo!);
        setState(() => _isUploadingVideo = false);
      }

      // 2. Upload images to Cloudinary in PARALLEL (⚡ SUPER FAST)
      List<String> uploadedUrls = [];
      try {
        final List<Future<String?>> uploadFutures = _selectedImages
            .map((file) => CloudinaryService.uploadImage(file))
            .toList();
        
        final List<String?> results = await Future.wait(uploadFutures);
        uploadedUrls = results.whereType<String>().toList();
      } catch (e) {
        debugPrint("Parallel Upload Error: $e");
      }

      if (uploadedUrls.isEmpty) {
        throw 'कम्तिमा एउटा फोटो अपलोड हुन सकेन (Failed to upload photos)';
      }

      // 2.5. AI Landmark Generation (⚡ New Premium Feature)
      // This automatically finds real nearby places using AI based on the user's location
      final List<Map<String, dynamic>> nearbyLandmarks =
          await _aiService.getNearbyLandmarks(
            _areaController.text,
            _landmarkController.text,
          );

      // 3. Insert Property into Supabase
      final propertyResponse = await client
          .from('properties')
          .insert({
            'owner_id': user.id,
            'title': _titleController.text,
            'category': _selectedCategory,
            'area_name': _areaController.text,
            'landmark': _landmarkController.text,
            'price': double.tryParse(_priceController.text) ?? 0.0,
            'bedrooms': int.tryParse(_bedroomsController.text) ?? 0,
            'bathrooms': int.tryParse(_bathroomsController.text) ?? 0,
            'floor': _floorController.text,
            'sq_ft': _sqftController.text,
            'is_negotiable': _isNegotiable,
            'amenities': _selectedAmenities,
            'house_rules': _selectedRules,
            'images': uploadedUrls, // Save all URLs as array
            'description': _descriptionController.text,
            'latitude': _latitude,
            'longitude': _longitude,
            'video_url': videoUrl,
            'status': 'available',
            'is_verified': true,
            'nearby_landmarks':
                nearbyLandmarks, // Save the AI generated landmarks!
            'is_premium':
                (double.tryParse(_priceController.text) ?? 0.0) >= 15000.0,
          })
          .select()
          .single();

      final String propertyId = propertyResponse['id'];

      // 4. Also save to property_images table (BATCH INSERT for ⚡ SPEED)
      if (uploadedUrls.isNotEmpty) {
        final List<Map<String, dynamic>> imageData = uploadedUrls
            .map((url) => {
                  'property_id': propertyId,
                  'image_url': url,
                })
            .toList();
        await client.from('property_images').insert(imageData);
      }

      // 5. Update user profile to mark as owner if not already
      await client
          .from('profiles')
          .update({'is_owner': true})
          .eq('id', user.id);

        // FIRE CONFETTI!
        _confettiController.play();
        await Future.delayed(const Duration(milliseconds: 600));

        // Show full-page success screen
        if (mounted) {
          final user = Supabase.instance.client.auth.currentUser;
          final ownerName = user?.userMetadata?['full_name'] ?? user?.email ?? 'Property Owner';
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => _PropertySuccessScreen(
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Publishing failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
          _isUploadingVideo = false;
        });
      }
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _isLocating = true);

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission denied. Please enable it in Settings.',
              ),
            ),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      // Get actual coordinates
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
      }
    }
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

  void _nextStep() {
    bool isValid = false;
    String errorMessage = "";

    // Hide keyboard automatically when moving to next step
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
        errorMessage =
            "कृपया नक्शामा लोकेशन सेट गर्नुहोस् (Please set location on Map)";
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
      // Step 3 (Amenities), Step 4 (Rules) are optional
      isValid = true;
    }

    if (isValid) {
      if (_currentStep < 5) {
        // Now 6 steps
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
          style: GoogleFonts.mukta(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
            height: 1.1,
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
                size: 18, // Medium size
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
          // BOLD, SIMPLE PROGRESS BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 14, // Thicker for clarity
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 6,
                  backgroundColor: Colors.grey[100],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.brandColor,
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
                    _buildStep1(), // Basic Info
                    _buildStep2(), // Location & Landmarks
                    _buildStep3(), // Pricing
                    _buildStep4(), // Amenities Grid
                    _buildStep5(), // House Rules
                    _buildStep6(), // Media & Finish
                  ],
                ),
                // CONFETTI OVERLAY
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      AppTheme.brandColor,
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.pink
                    ],
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

  // --- STEP 1: CATEGORY ---
  Widget _buildStep1() {
    return _stepLayout(
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
            _categoryCard('कोठा\nRoom', CupertinoIcons.bed_double_fill, 'Room'),
            _categoryCard('फ्ल्याट\nFlat', CupertinoIcons.house_fill, 'Flat'),
            _categoryCard('सटर / पसल\nShop', CupertinoIcons.bag_fill, 'Shop'),
            _categoryCard('अन्य\nOther', CupertinoIcons.ellipsis, 'Other'),
          ],
        ),
        const SizedBox(height: 24),
        _buildLabel('विज्ञापनको नाम (Title)', true),
        _buildTextField(
          'e.g. 2 BHK Modern Apartment',
          controller: _titleController,
          focusNode: _titleFocusNode,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return _stepLayout(
      title: 'प्रोपर्टी कहाँ छ?',
      subtitle: 'Accurate location builds trust',
      content: [
        // MAP INTERACTION (MOVED TO TOP)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _latitude != null
                  ? [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.02)]
                  : [AppTheme.brandColor.withOpacity(0.08), Colors.white],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _latitude != null
                  ? Colors.green.withOpacity(0.3)
                  : AppTheme.brandColor.withOpacity(0.15),
              width: 1.5,
            ),
          ),
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
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _latitude != null ? Colors.green : AppTheme.brandColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_latitude != null ? Colors.green : AppTheme.brandColor)
                              .withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Icon(
                      _latitude != null ? Icons.location_on : Icons.my_location,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  if (_isLocating)
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        color: AppTheme.brandColor.withOpacity(0.5),
                        strokeWidth: 2,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_latitude != null) ...[
                Text(
                  'लोकेशन सेट भयो! ✓',
                  style: GoogleFonts.mukta(
                    fontWeight: FontWeight.w700,
                    color: Colors.green[800],
                    fontSize: 20,
                  ),
                ),
                Text(
                  'GPS verified location detected by AI',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[600]?.withValues(alpha: 0.8),
                  ),
                ),
              ] else ...[
                Text(
                  'लोकेशन राख्नुहोस्',
                  style: GoogleFonts.mukta(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                    fontSize: 20,
                  ),
                ),
                Text(
                  'Use GPS for maximum listing trust',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
              ],
              const SizedBox(height: 20),
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
                  backgroundColor:
                      _latitude != null ? Colors.green : AppTheme.brandColor,
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

        const SizedBox(height: 32),

        // TEXT FIELDS FOR LOCATION
        _buildLabel('नगरपालिका / टोल (Area Name)', true),
        _buildTextField('उदा: ललितपुर, सानेपा-२', controller: _areaController),
        const SizedBox(height: 24),
        _buildLabel('नजिकैको चिनिने ठाउँ (Landmark)', true),
        _buildTextField(
          'उदा: सिभिल हस्पिटलको पछाडि',
          controller: _landmarkController,
        ),
        const SizedBox(height: 24),

        // SMART LOCATION VERIFIER (PREMIUM GAUGE)
        if (_areaController.text.isNotEmpty || _landmarkController.text.isNotEmpty)
          _premiumFeatureCard(
            icon: Icons.gps_fixed_rounded,
            title: 'Distance Check',
            subtitle: 'Must be within 250m for verification',
            isLoading: _isAnalyzingLocation,
            accentColor: _latitude == null
                ? Colors.grey
                : (_isDistanceVerified ? Colors.green : Colors.orange),
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

  Widget _quickPriceChip(String label, String value) {
    bool isSelected = _priceController.text == value;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _priceController.text = value);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandColor : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.brandColor : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '₹ ',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : const Color(0xFF111827),
                ),
              ),
              TextSpan(
                text: label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- STEP 3: PRICING & FEATURES ---
  Widget _buildStep3() {
    return _stepLayout(
      title: 'भाडा र विवरण',
      subtitle: 'Almost halfway! High precision earns trust.',
      content: [
        _buildLabel('महिमाको जम्मा भाडा (Monthly Rent)', true),
        _buildTextField(
          'उदा: ५०००',
          prefix: '₹ ',
          controller: _priceController,
          keyboardType: TextInputType.number,
          isPrice: true,
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _quickPriceChip('५,०००', '5000'),
              const SizedBox(width: 8),
              _quickPriceChip('८,०००', '8000'),
              const SizedBox(width: 8),
              _quickPriceChip('१२,०००', '12000'),
              const SizedBox(width: 8),
              _quickPriceChip('१५,०००', '15000'),
              const SizedBox(width: 8),
              _quickPriceChip('२५,०००', '25000'),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // 2x2 Feature Grid
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Beds', false),
                  _buildTextField('उदा: २', controller: _bedroomsController, keyboardType: TextInputType.number),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Baths', false),
                  _buildTextField('उदा: १', controller: _bathroomsController, keyboardType: TextInputType.number),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Floor', false),
                  _buildTextField('उदा: १', controller: _floorController),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Sq. Ft', false),
                  _buildTextField('उदा: ४००', controller: _sqftController, keyboardType: TextInputType.number),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        // Negotiable Premium Card
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _isNegotiable = !_isNegotiable);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: _isNegotiable
                  ? AppTheme.brandColor.withValues(alpha: 0.05)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isNegotiable ? AppTheme.brandColor : const Color(0xFFE5E7EB),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isNegotiable ? AppTheme.brandColor : Colors.white,
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
                        'भाडा मिलाउन सकिन्छ',
                        style: GoogleFonts.mukta(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'Price is Negotiable',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
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
        ),
        
        const SizedBox(height: 32),

        // SMART PRICE ESTIMATOR (PREMIUM)
        _premiumFeatureCard(
          icon: Icons.insights_rounded,
          title: 'Price Guide',
          subtitle: 'AI neighborhood analysis',
          isLoading: _isEstimatingPrice,
          accentColor: Colors.purple,
          child: Column(
            children: [
              if (_aiPriceSuggestion != null)
                Text(
                  _aiPriceSuggestion!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4B5563),
                    height: 1.5,
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isEstimatingPrice
                      ? null
                      : () async {
                          if (_areaController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please set area in Step 2 first')),
                            );
                            return;
                          }
                          setState(() => _isEstimatingPrice = true);
                          final result = await _aiService.estimatePrice(
                            _areaController.text,
                            _selectedCategory == 'Room' ? 1 : 3,
                            _selectedCategory ?? 'Room',
                          );
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

  // --- STEP 4: AMENITIES GRID ---
  Widget _buildStep4() {
    return _stepLayout(
      title: 'सुविधाहरू छान्नुहोस्',
      subtitle: 'Higher quality amenities attract better tenants.',
      content: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.3,
          children: [
            _selectionCard(Icons.water_drop_rounded, '२४ सै घण्टा पानी', 'water_24_7', Colors.blue),
            _selectionCard(Icons.waves_rounded, 'बोरिङको पानी', 'water_boring', Colors.cyan),
            _selectionCard(Icons.ac_unit_rounded, 'एसी (AC)', 'ac', Colors.lightBlue),
            _selectionCard(Icons.wifi_rounded, 'इन्टरनेट', 'internet', Colors.blueGrey),
            _selectionCard(Icons.wb_sunny_rounded, 'घाम लाग्ने कोठा', 'sunny_room', Colors.orange),
            _selectionCard(Icons.balcony_rounded, 'बालकोनी (Balcony)', 'balcony', Colors.green),
            _selectionCard(Icons.kitchen_rounded, 'छुट्टै भान्सा', 'kitchen', Colors.deepOrange),
            _selectionCard(Icons.chair_rounded, 'फर्निचर सहित (Furnished)', 'furnished', Colors.brown),
            _selectionCard(Icons.solar_power_rounded, 'सोलार / तातो पानी', 'hot_water', Colors.amber),
            _selectionCard(Icons.motorcycle_rounded, 'बाइक पार्किङ', 'parking_bike', Colors.teal),
            _selectionCard(Icons.directions_car_rounded, 'कार पार्किङ', 'parking_car', Colors.indigo),
            _selectionCard(Icons.security_rounded, 'सेक्युरिटी / CCTV', 'security', Colors.redAccent),
            _selectionCard(Icons.elevator_rounded, 'लिफ्ट (Elevator)', 'elevator', Colors.deepPurple),
            _selectionCard(Icons.electric_bolt_rounded, 'पावर ब्याकअप', 'power_backup', const Color(0xFFFBC02D)),
            _selectionCard(Icons.delete_outline_rounded, 'फोहोर उठाउने', 'waste_mgmt', Colors.brown),
            _selectionCard(Icons.nature_people_rounded, 'शान्त वातावरण', 'peaceful', Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _selectionCard(IconData icon, String label, String value, Color color) {
    bool isAmenity = _currentStep == 3;
    bool isSelected = isAmenity ? _selectedAmenities.contains(value) : _selectedRules.contains(value);
    
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        if (isAmenity) _toggleAmenity(value); else _toggleRule(value);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isSelected ? color : Colors.black).withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : Colors.grey[400],
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.mukta(
                      fontSize: 13,
                      color: isSelected ? color : const Color(0xFF4B5563),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.check_circle, color: color, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  // --- STEP 5: HOUSE RULES ---
  Widget _buildStep5() {
    return _stepLayout(
      title: 'नियमहरू राख्नुहोस्',
      subtitle: 'Sets expectations for potential tenants.',
      content: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.3,
          children: [
            _selectionCard(Icons.family_restroom_rounded, 'परिवार मात्र', 'family_only', Colors.blue),
            _selectionCard(Icons.man_rounded, 'केटा मात्र', 'boys_allowed', Colors.indigo),
            _selectionCard(Icons.woman_rounded, 'केटी मात्र', 'girls_allowed', Colors.pink),
            _selectionCard(Icons.pets_rounded, 'जनावर राख्न पाईने', 'pets_allowed', Colors.orange),
            _selectionCard(Icons.smoke_free_rounded, 'चुरोट पिउन पाईने', 'smoking_allowed', Colors.red),
            _selectionCard(Icons.local_bar_rounded, 'मदिरा पिउन पाईने', 'alcohol_allowed', Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _ruleItem(IconData icon, String label, String value) {
    bool isSelected = _selectedRules.contains(value);
    return InkWell(
      onTap: () {
        _toggleRule(value);
        if (!isSelected) {
          Feedback.forTap(context);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.brandColor : Colors.grey[300]!,
            width: isSelected ? 3 : 2, // Thicker border when selected
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.brandColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.mukta(
                fontSize: 14,
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- STEP 6: MEDIA & PUBLISH ---
  Widget _buildStep6() {
    return _stepLayout(
      title: 'फोटो/भिडियो र विवरण',
      subtitle: 'Final step! Make it look irresistible.',
      content: [
        // AI DESCRIPTION GENERATOR (PREMIUM REFACTOR)
        _premiumFeatureCard(
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
        // PHOTO UPLOAD
        GestureDetector(
          onTap: _pickImages,
          child: _buildMediaUploadBox(
            icon: Icons.add_a_photo_outlined,
            title: 'फोटोहरू थप्नुहोस् (Add Photos)',
            desc: 'कम्तिमा ३ वटा फोटो राख्नु राम्रो हुन्छ।',
            isBlue: false,
          ),
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
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.all(2),
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
          ),
        ],

        const SizedBox(height: 20),
        // VIDEO UPLOAD (REEL)
        GestureDetector(
          onTap: _pickVideo,
          child: _buildMediaUploadBox(
            icon: Icons.videocam_outlined,
            title: _selectedVideo != null
                ? 'भिडियो छानियो ✓'
                : 'भिडियो राख्नुहोस् (Upload Reel)',
            desc: _selectedVideo != null
                ? 'भिडियो परिवर्तन गर्न ट्याप गर्नुहोस्'
                : 'भिडियोले ग्राहकलाई छिटो आकर्षित गर्छ।',
            isBlue: true,
            hasFile: _selectedVideo != null,
          ),
        ),
        if (_selectedVideo != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.video_file, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Video: ${_selectedVideo!.path.split('/').last}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.blue[900],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  onPressed: () => setState(() => _selectedVideo = null),
                ),
              ],
            ),
          ),
        ],
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
                  'तपाईंको विज्ञापन प्रमाणित भएपछि प्रकाशित हुनेछ।',
                  style: GoogleFonts.mukta(
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

  // --- PREMIUM REUSABLE COMPONENTS ---

  Widget _premiumFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
    Color accentColor = AppTheme.brandColor,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brandColor),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildStepProgressBar() {
    return Container(
      height: 3,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: List.generate(6, (index) {
          bool isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index == 5 ? 0 : 3),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.brandColor
                    : AppTheme.brandColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLabel(String label, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.mukta(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF374151),
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String hint, {
    TextEditingController? controller,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    String? prefix,
    int? maxLines = 1,
    bool isPrice = false,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.inter(
        fontSize: 15,
        color: const Color(0xFF111827),
        fontWeight: isPrice ? FontWeight.w900 : FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        prefixText: prefix,
        prefixStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.brandColor,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.brandColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _stepLayout({
    required String title,
    required String subtitle,
    required List<Widget> content,
    ScrollController? controller,
  }) {
    return SingleChildScrollView(
      controller: controller,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.mukta(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.mukta(
              color: AppTheme.brandColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),
          ...content,
        ],
      ),
    );
  }

  Widget _categoryCard(String label, IconData icon, String value) {
    bool isSelected = _selectedCategory == value;
    String subLabel = '';
    if (value == 'Room') subLabel = 'Single personal space';
    if (value == 'Flat') subLabel = 'Full private home';
    if (value == 'Shop') subLabel = 'Commercial use';
    if (value == 'Other') subLabel = 'Land or Hostels';

    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _selectedCategory = value);
        _titleFocusNode.requestFocus();
      },
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppTheme.brandColor : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.brandColor.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ]
              : [],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Background Illustration Shape (Faded Icon)
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                icon,
                size: 80,
                color: isSelected 
                    ? AppTheme.brandColor.withValues(alpha: 0.08) 
                    : Colors.grey.withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.brandColor 
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: (isSelected ? AppTheme.brandColor : Colors.black)
                              .withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    label.split('\n')[0], // Nepali
                    style: GoogleFonts.mukta(
                      fontSize: 16,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppTheme.brandColor : const Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    label.split('\n')[1], // English
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isSelected ? AppTheme.brandColor.withValues(alpha: 0.7) : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subLabel,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: isSelected ? AppTheme.brandColor.withValues(alpha: 0.6) : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.brandColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _amenityItem(IconData icon, String label, String value) {
    bool isSelected = _selectedAmenities.contains(value);
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _toggleAmenity(value);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.brandColor : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.brandColor.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.brandColor.withValues(alpha: 0.1) 
                          : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? AppTheme.brandColor : Colors.grey[400],
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.mukta(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppTheme.brandColor : const Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.check_circle, color: AppTheme.brandColor, size: 16),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: hasFile ? activeColor.withValues(alpha: 0.05) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasFile ? activeColor : const Color(0xFFE5E7EB),
          width: 2,
        ),
        boxShadow: hasFile ? [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ] : [],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasFile ? activeColor : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (hasFile ? activeColor : Colors.black).withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(
              hasFile ? Icons.check_rounded : icon,
              color: hasFile ? Colors.white : Colors.grey[400],
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.mukta(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.mukta(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    side: BorderSide(color: Colors.grey.shade300, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'पछाडि',
                    style: GoogleFonts.mukta(
                      color: const Color(0xFF4B5563),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _currentStep == 5
                    ? (_isPublishing ? null : _publishProperty)
                    : _nextStep,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  backgroundColor: _currentStep == 5
                      ? Colors.green
                      : AppTheme.brandColor,
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isPublishing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        _currentStep == 5
                            ? 'प्रकाशित गर्नुहोस् (Publish)'
                            : 'अर्को भाग (Next)',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.mukta(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
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

// ─────────────────────────────────────────────────────
// PREMIUM SUCCESS SCREEN
// ─────────────────────────────────────────────────────
class _PropertySuccessScreen extends StatefulWidget {
  final String ownerName;
  final String title;
  final String area;
  final String landmark;
  final String category;
  final String price;
  final DateTime submittedAt;

  const _PropertySuccessScreen({
    required this.ownerName,
    required this.title,
    required this.area,
    required this.landmark,
    required this.category,
    required this.price,
    required this.submittedAt,
  });

  @override
  State<_PropertySuccessScreen> createState() => _PropertySuccessScreenState();
}

class _PropertySuccessScreenState extends State<_PropertySuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),

                // BIG GREEN ANIMATED TICK
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 70,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // TITLE
                Text(
                  'प्रकाशित भयो! 🎉',
                  style: GoogleFonts.mukta(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Your property is now live on Khozna',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 36),

                // DETAILS CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Listing Summary',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.grey[500],
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _detailRow(Icons.home_outlined, 'Title', widget.title.isEmpty ? 'My Property' : widget.title),
                      _detailRow(Icons.location_on_outlined, 'Location', widget.area),
                      if (widget.landmark.isNotEmpty)
                        _detailRow(Icons.place_outlined, 'Landmark', widget.landmark),
                      _detailRow(
                        Icons.currency_rupee,
                        'Monthly Rent',
                        widget.price.isEmpty ? 'Not specified' : '₹ ${widget.price}/mo',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // STATUS BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Listing is Live & Verified',
                        style: GoogleFonts.inter(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // GO TO HOME BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: AppTheme.brandColor.withOpacity(0.4),
                    ),
                    child: Text(
                      'गृहपृष्ठमा जानुहोस् (Go Home)',
                      style: GoogleFonts.mukta(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // VIEW LISTING BUTTON
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'View My Listings',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF4B5563),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.brandColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.mukta(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.mukta(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
