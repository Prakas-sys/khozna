import 'dart:io';
// firebase_auth removed
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();

  // Form State
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Location State
  bool _isLocating = false;
  double? _latitude;
  double? _longitude;

  // Selected Data State
  String? _selectedCategory = 'Room';
  bool _isNegotiable = true;
  final List<String> _selectedAmenities = [];
  final List<File> _selectedImages = [];
  bool _isPublishing = false;
  
  // AI Service (Using Khozna AI)
  final KhoznaAiService _aiService = KhoznaAiService();
  bool _isEstimatingPrice = false;
  String? _aiPriceSuggestion;
  
  // New Location Analysis State
  bool _isAnalyzingLocation = false;
  String? _aiLocationAnalysis;
  
  // AI Description State
  bool _isGeneratingDescription = false;

  @override
  void dispose() {
    _titleController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((x) => File(x.path)));
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

    if (_titleController.text.isEmpty || _priceController.text.isEmpty || _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields and add at least one photo')),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      // 0. AI Scam Detector Check
      final String scamResult = await _aiService.detectScam(
        _titleController.text, 
        _priceController.text, 
        _areaController.text
      );
      
      if (scamResult.toLowerCase().contains("scam") || scamResult.toLowerCase().contains("warning")) {
         // In a real app, you might block or flag this, for now we just show a warning
         debugPrint("AI SCAM WARNING: $scamResult");
      }

      // 1. Insert Property into Supabase
      final propertyResponse = await client.from('properties').insert({
        'owner_id': user.id,
        'title': _titleController.text,
        'category': _selectedCategory,
        'area_name': _areaController.text,
        'landmark': _landmarkController.text,
        'price': _priceController.text,
        'is_negotiable': _isNegotiable,
        'amenities': _selectedAmenities,
        'description': _descriptionController.text,
        'latitude': _latitude,
        'longitude': _longitude,
        'status': 'available',
      }).select().single();

      final String propertyId = propertyResponse['id'];

      // 2. Upload images to Cloudinary and save to property_images table
      for (var file in _selectedImages) {
        await CloudinaryService.uploadPropertyImage(file, propertyId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property published successfully! 🚀'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Publishing failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
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
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied. Please enable it in Settings.')),
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
          _isLocating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
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

  void _nextStep() {
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'प्रोपर्टी राख्नुहोस्',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                'स्टेप ${_currentStep + 1} / 5',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.brandColor, fontSize: 16),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // DUOLINGO STYLE THICK PROGRESS BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / 5,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandColor),
              ),
            ),
          ),
          
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(), // Basic Info
                _buildStep2(), // Location & Landmarks
                _buildStep3(), // Pricing
                _buildStep4(), // Amenities Grid
                _buildStep5(), // Media & Finish
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
      title: 'तपाईं के भाडामा दिँदै हुनुहुन्छ?',
      subtitle: 'सुरु गरौं! (Let\'s start)',
      content: [
        _categoryCard('कोठा / Room', Icons.bed, 'Room'),
        _categoryCard('फ्ल्याट / Flat', Icons.apartment, 'Flat'),
        _categoryCard('अपार्टमेन्ट / Apartment', Icons.domain, 'Apartment'),
        _categoryCard('अन्य / Other', Icons.more_horiz, 'Other'),
        const SizedBox(height: 32),
        _buildLabel('विज्ञापनको नाम (Title)', true),
        _buildTextField('उदा: सानेपामा राम्रो २ कोठा खाली छ', controller: _titleController),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('प्रोपर्टी विवरण (Description)', false),
            TextButton.icon(
              onPressed: _isGeneratingDescription ? null : () async {
                if (_titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a title first')),
                  );
                  return;
                }
                setState(() => _isGeneratingDescription = true);
                try {
                  final description = await _aiService.generateDescription(
                    title: _titleController.text,
                    category: _selectedCategory ?? 'Room',
                    area: _areaController.text.isEmpty ? "Kathmandu" : _areaController.text,
                    landmark: _landmarkController.text.isEmpty ? "Nearby" : _landmarkController.text,
                    amenities: _selectedAmenities,
                  );
                  setState(() => _descriptionController.text = description);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('AI Generation failed: $e')),
                  );
                } finally {
                  setState(() => _isGeneratingDescription = false);
                }
              },
              icon: _isGeneratingDescription 
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brandColor))
                : const Icon(Icons.flash_on, size: 16, color: AppTheme.brandColor),
              label: Text(
                _isGeneratingDescription ? 'लेख्दैछ...' : 'स्वत: भर्नुहोस्',
                style: GoogleFonts.inter(color: AppTheme.brandColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        _buildTextField(
          'प्रोपर्टीको बारेमा थप जानकारी...',
          controller: _descriptionController,
          maxLines: 4,
        ),
      ],
    );
  }

  // --- STEP 2: LOCATION (Nepal Context) ---
  Widget _buildStep2() {
    return _stepLayout(
      title: 'प्रोपर्टी कहाँ छ?',
      subtitle: 'Accurate location builds trust',
      content: [
        _buildLabel('नगरपालिका / टोल (Area Name)', true),
        _buildTextField('उदा: ललितपुर, सानेपा-२', controller: _areaController),
        const SizedBox(height: 24),
        _buildLabel('नजिकैको चिनिने ठाउँ (Landmark)', true),
        _buildTextField('उदा: सिभिल हस्पिटलको पछाडि', controller: _landmarkController),
        const SizedBox(height: 20),

        // SMART LOCATION VERIFIER BUTTON
        if (_areaController.text.isNotEmpty || _landmarkController.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppTheme.brandColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ठाउँ रुजु गर्नुहोस् (Smart Check)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87)),
                          Text('Ensure your location is accurate', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_aiLocationAnalysis != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _aiLocationAnalysis!,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.blue[900], height: 1.4),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isAnalyzingLocation ? null : () async {
                      if (_areaController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an area name first')));
                        return;
                      }
                      setState(() => _isAnalyzingLocation = true);
                      final result = await _aiService.verifyLocation(
                        _areaController.text, 
                        _landmarkController.text
                      );
                      setState(() {
                        _aiLocationAnalysis = result;
                        _isAnalyzingLocation = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandColor.withOpacity(0.1),
                      foregroundColor: AppTheme.brandColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isAnalyzingLocation 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.brandColor, strokeWidth: 2))
                      : const Text('ठाउँ रुजु गर्नुहोस् (Check)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 32),
        
        // MAP INTERACTION
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _latitude != null
                ? Colors.green.withOpacity(0.05)
                : AppTheme.brandColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _latitude != null
                  ? Colors.green.withOpacity(0.3)
                  : AppTheme.brandColor.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              Icon(
                _latitude != null ? Icons.location_on : Icons.my_location,
                color: _latitude != null ? Colors.green : AppTheme.brandColor,
                size: 32,
              ),
              const SizedBox(height: 12),
              if (_latitude != null) ...
              [
                Text(
                  'लोकेशन सेट भयो! ✓',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lat: ${_latitude!.toStringAsFixed(5)}, Lng: ${_longitude!.toStringAsFixed(5)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '(GPS verified location)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.green[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ] else ...
              [
                const Text(
                  'मैले अहिले भएकै ठाउँ रोज्नुहोस्',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.brandColor),
                ),
                Text(
                  '(Use my current location on Map)',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLocating ? null : _detectLocation,
                icon: _isLocating
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(_latitude != null ? Icons.refresh : Icons.gps_fixed, size: 18),
                label: Text(
                  _isLocating
                      ? 'GPS खोज्दै छ...'
                      : _latitude != null
                          ? 'लोकेशन अपडेट गर्नुहोस्'
                          : 'लोकेशन सेट गर्नुहोस्',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _latitude != null ? Colors.green : AppTheme.brandColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickPriceChip(String label, String value) {
    return ActionChip(
      label: Text('रु. $label', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87)),
      backgroundColor: Colors.grey[100],
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: () {
        setState(() => _priceController.text = value);
      },
    );
  }

  // --- STEP 3: PRICING ---
  Widget _buildStep3() {
    return _stepLayout(
      title: 'भाडा कति हो?',
      subtitle: 'लगभग आधा काम सकियो! (Halfway there!)',
      content: [
        _buildLabel('महिनाको जम्मा भाडा', true),
        _buildTextField('उदा: ५०००', prefix: 'रु. ', controller: _priceController, keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _quickPriceChip('५,०००', '5000'),
            _quickPriceChip('८,०००', '8000'),
            _quickPriceChip('१२,०००', '12000'),
            _quickPriceChip('१५,०००', '15000'),
            _quickPriceChip('२५,०००', '25000'),
          ]
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isNegotiable ? AppTheme.brandColor.withOpacity(0.05) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _isNegotiable ? AppTheme.brandColor : Colors.grey[200]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.handshake_outlined, color: AppTheme.brandColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('भाडा मिलाउन सकिन्छ', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    Text('Price is Negotiable', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Switch(
                value: _isNegotiable,
                onChanged: (v) => setState(() => _isNegotiable = v),
                activeThumbColor: AppTheme.brandColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // SMART PRICE ESTIMATOR BUTTON
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.insights, color: AppTheme.brandColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('उचित भाडा हेर्नुहोस् (Price Guide)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87)),
                        Text('See typical rent in this area', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_aiPriceSuggestion != null) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _aiPriceSuggestion!,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.purple[900], fontStyle: FontStyle.italic),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isEstimatingPrice ? null : () async {
                    if (_areaController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an area first (Step 2)')));
                      return;
                    }
                    setState(() => _isEstimatingPrice = true);
                    final result = await _aiService.estimatePrice(
                      _areaController.text, 
                      _selectedCategory == 'Room' ? 1 : 3, // Simplification
                      _selectedCategory ?? 'Room'
                    );
                    setState(() {
                      _aiPriceSuggestion = result;
                      _isEstimatingPrice = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandColor.withOpacity(0.1),
                    foregroundColor: AppTheme.brandColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isEstimatingPrice 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.brandColor, strokeWidth: 2))
                    : const Text('कति भाडा राख्ने? (Get Suggestion)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- STEP 4: AMENITIES GRID (Tap to Select) ---
  Widget _buildStep4() {
    return _stepLayout(
      title: 'सुविधाहरू छान्नुहोस्',
      subtitle: 'के के सुविधा छन्? (What are the facilities?)',
      content: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _amenityItem(Icons.water_drop, 'मेलम्ची / धारो', 'Water'),
            _amenityItem(Icons.waves, 'बोरिङको पानी', 'Boring Water'),
            _amenityItem(Icons.wb_sunny, 'घाम लाग्ने कोठा', 'Sunny Room'),
            _amenityItem(Icons.solar_power, 'सोलार / तातो पानी', 'Hot Water'),
            _amenityItem(Icons.motorcycle, 'बाइक पार्किङ', 'Bike Parking'),
            _amenityItem(Icons.directions_car, 'कार पार्किङ', 'Car Parking'),
            _amenityItem(Icons.delete_outline, 'फोहोर उठाउने', 'Waste Management'),
            _amenityItem(Icons.nature_people, 'शान्त वातावरण', 'Peaceful'),
            _amenityItem(Icons.wifi, 'इन्टरनेट', 'Internet'),
            _amenityItem(Icons.kitchen, 'छुट्टै भान्सा', 'Kitchen'),
          ],
        ),
      ],
    );
  }

  // --- STEP 5: MEDIA & PUBLISH ---
  Widget _buildStep5() {
    return _stepLayout(
      title: 'फोटो र भिडियो राख्नुहोस्',
      subtitle: 'Show the real look of your property',
      content: [
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
                      onTap: () => setState(() => _selectedImages.removeAt(index)),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
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
        _buildMediaUploadBox(
          icon: Icons.videocam_outlined,
          title: 'भिडियो राख्नुहोस् (Upload Reel)',
          desc: 'भिडियोले ग्राहकलाई छिटो आकर्षित गर्छ।',
          isBlue: true,
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.verified_outlined, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(child: Text('तपाईंको विज्ञापन प्रमाणित भएपछि प्रकाशित हुनेछ।', style: GoogleFonts.inter(color: Colors.green[800], fontSize: 13, height: 1.4))),
            ],
          ),
        )
      ],
    );
  }

  // --- REUSABLE COMPONENTS ---

  Widget _stepLayout({required String title, required String subtitle, required List<Widget> content}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.3)),
          const SizedBox(height: 8),
          Text(subtitle, style: GoogleFonts.inter(color: AppTheme.brandColor, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          ...content,
        ],
      ),
    );
  }

  Widget _categoryCard(String label, IconData icon, String value) {
    bool isSelected = _selectedCategory == value;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.brandColor : Colors.grey[300]!, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.brandColor : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : Colors.grey[600], size: 28),
            ),
            const SizedBox(width: 20),
            Text(label, style: GoogleFonts.inter(fontSize: 18, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: Colors.black87)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: AppTheme.brandColor, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _amenityItem(IconData icon, String label, String value) {
    bool isSelected = _selectedAmenities.contains(value);
    return InkWell(
      onTap: () => _toggleAmenity(value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.brandColor : Colors.grey[300]!, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[600], size: 36),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaUploadBox({required IconData icon, required String title, required String desc, required bool isBlue}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isBlue ? AppTheme.brandColor.withOpacity(0.05) : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isBlue ? AppTheme.brandColor.withOpacity(0.2) : Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: isBlue ? AppTheme.brandColor : Colors.grey[600], size: 40),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          Text(desc, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)), if (isRequired) const Text(' *', style: TextStyle(color: Colors.red))]),
    );
  }

  Widget _buildTextField(String hint, {String? prefix, TextEditingController? controller, int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (v) => setState(() {}),
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
        prefixText: prefix,
        prefixStyle: GoogleFonts.inter(color: AppTheme.brandColor, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: (controller != null && controller.text.isNotEmpty) ? Colors.white : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: BorderSide(
            color: (controller != null && controller.text.isNotEmpty) ? AppTheme.brandColor.withOpacity(0.4) : Colors.grey.shade200,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: const BorderSide(color: AppTheme.brandColor, width: 1.8),
        ),
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
                  onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut), 
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20), 
                    side: BorderSide(color: Colors.grey.shade300, width: 2), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ), 
                  child: Text('पछाडि', style: GoogleFonts.inter(color: Colors.grey[800], fontSize: 16, fontWeight: FontWeight.bold))
                )
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              flex: 2, 
              child: ElevatedButton(
                onPressed: _currentStep == 4 
                  ? (_isPublishing ? null : _publishProperty) 
                  : _nextStep, 
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20), 
                  backgroundColor: _currentStep == 4 ? Colors.green : AppTheme.brandColor, 
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ), 
                child: _isPublishing 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : Text(_currentStep == 4 ? 'प्रकाशित गर्ने (Publish)' : 'अर्को जानुहोस् (Next)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
