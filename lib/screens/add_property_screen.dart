import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Selected Data State
  String? _selectedCategory = 'Room';
  bool _isNegotiable = true;
  final List<String> _selectedAmenities = [];

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'प्रोपर्टी राख्नुहोस् (Post Property)',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                'Step ${_currentStep + 1}',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.brandColor),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / 5,
            backgroundColor: Colors.grey[100],
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandColor),
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
      subtitle: 'Select the type of your property',
      content: [
        _categoryCard('कोठा (Room)', Icons.bed_outlined, 'Room'),
        _categoryCard('फ्ल्याट (Flat)', Icons.apartment_outlined, 'Flat'),
        _categoryCard('घर (House)', Icons.home_outlined, 'House'),
        _categoryCard('जग्गा (Land)', Icons.landscape_outlined, 'Land'),
        const SizedBox(height: 32),
        _buildLabel('विज्ञापनको नाम (Title)', true),
        _buildTextField('उदा: सानेपामा राम्रो २ कोठा खाली छ'),
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
        _buildTextField('उदा: ललितपुर, सानेपा-२'),
        const SizedBox(height: 24),
        _buildLabel('नजिकैको चिनिने ठाउँ (Landmark)', true),
        _buildTextField('उदा: सिभिल हस्पिटलको पछाडि'),
        const SizedBox(height: 32),
        
        // MAP INTERACTION
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.brandColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.brandColor.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              const Icon(Icons.my_location, color: AppTheme.brandColor, size: 32),
              const SizedBox(height: 12),
              Text(
                'मैले अहिले भएकै ठाउँ रोज्नुहोस्',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.brandColor),
              ),
              Text(
                '(Use my current location on Map)',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandColor, elevation: 0),
                child: const Text('लोकेशन सेट गर्नुहोस्'),
              )
            ],
          ),
        ),
      ],
    );
  }

  // --- STEP 3: PRICING ---
  Widget _buildStep3() {
    return _stepLayout(
      title: 'भाडा कति हो?',
      subtitle: 'Set a fair monthly rent',
      content: [
        _buildLabel('महिनाको जम्मा भाडा (Monthly Rent)', true),
        _buildTextField('रुपैयाँमा (In Rs.)', prefix: 'रु. '),
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
                    Text('भाडा मिलाउन सकिन्छ', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    Text('Price is Negotiable', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Switch(
                value: _isNegotiable,
                onChanged: (v) => setState(() => _isNegotiable = v),
                activeColor: AppTheme.brandColor,
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
      subtitle: 'Tap to select all available facilities',
      content: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _amenityItem(Icons.water_drop_outlined, '२४सै घण्टा पानी', 'Water'),
            _amenityItem(Icons.bolt_outlined, 'बिजुली (सब-मिटर)', 'Electricity'),
            _amenityItem(Icons.directions_car_outlined, 'पार्किङ', 'Parking'),
            _amenityItem(Icons.wifi, 'इन्टरनेट', 'Internet'),
            _amenityItem(Icons.balcony_outlined, 'बार्दली', 'Balcony'),
            _amenityItem(Icons.kitchen_outlined, 'छट्टै भान्सा', 'Kitchen'),
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
        // VIDEO UPLOAD (REEL)
        _buildMediaUploadBox(
          icon: Icons.videocam_outlined,
          title: 'भिडियो राख्नुहोस् (Upload Reel)',
          desc: 'भिडियोले ग्राहकलाई छिटो आकर्षित गर्छ।',
          isBlue: true,
        ),
        const SizedBox(height: 20),
        // PHOTO UPLOAD
        _buildMediaUploadBox(
          icon: Icons.add_a_photo_outlined,
          title: 'फोटोहरू थप्नुहोस् (Add Photos)',
          desc: 'कम्तिमा ३ वटा फोटो राख्नु राम्रो हुन्छ।',
          isBlue: false,
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.verified_outlined, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(child: Text('तपाईंको विज्ञापन प्रमाणित भएपछि प्रकाशित हुनेछ।', style: GoogleFonts.outfit(color: Colors.green[800], fontSize: 13, height: 1.4))),
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
          Text(title, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14)),
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.brandColor : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.brandColor : Colors.grey[600]),
            const SizedBox(width: 16),
            Text(label, style: GoogleFonts.outfit(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: AppTheme.brandColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _amenityItem(IconData icon, String label, String value) {
    bool isSelected = _selectedAmenities.contains(value);
    return InkWell(
      onTap: () => _toggleAmenity(value),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandColor : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.brandColor : Colors.grey[200]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppTheme.brandColor, size: 28),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 10, color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
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
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          Text(desc, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)), if (isRequired) const Text(' *', style: TextStyle(color: Colors.red))]),
    );
  }

  Widget _buildTextField(String hint, {String? prefix}) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix,
        fillColor: const Color(0xFFF9F9F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(child: OutlinedButton(onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: AppTheme.brandColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('पछाडि', style: TextStyle(color: AppTheme.brandColor)))),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(flex: 2, child: ElevatedButton(onPressed: _currentStep == 4 ? () => Navigator.pop(context) : _nextStep, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: AppTheme.brandColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(_currentStep == 4 ? 'प्रकाशित गर्नुहोस्' : 'अर्को जानुहोस्', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
          ],
        ),
      ),
    );
  }
}
