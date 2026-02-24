import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/app_notifiers.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final String id;
  final String imageUrl;
  final List<String>? images;
  final String title;
  final String location;
  final String price;
  final String? description;
  final int? bedrooms;
  final int? bathrooms;
  final String? area;
  final String? floor;

  const PropertyDetailsScreen({
    super.key,
    required this.id,
    required this.imageUrl,
    this.images,
    required this.title,
    required this.location,
    required this.price,
    this.description,
    this.bedrooms,
    this.bathrooms,
    this.area,
    this.floor,
  });

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  late final List<String> displayImages;

  @override
  void initState() {
    super.initState();
    displayImages = widget.images ??
        [
          widget.imageUrl,
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1493809842364-78817add7ffb?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color airbnbGrey = Color(0xFF717171);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // VERIFIED BADGE & TITLE
                _buildHeader(widget.title, widget.location),
                const SizedBox(height: 24),

                // PROPERTY STATS (Beds, Baths, Area, Floor)
                _buildPropertyStats(),
                const SizedBox(height: 24),

                // PRICE BOX
                _buildPriceBox(widget.price, airbnbGrey),
                const SizedBox(height: 32),

                // THE NEPAL ESSENTIALS
                _buildSectionTitle('आधारभूत सुविधाहरू (Essentials)'),
                const SizedBox(height: 16),
                _buildEssentialGrid(),
                const SizedBox(height: 32),

                // DESCRIPTION
                _buildSectionTitle('विवरण (Description)'),
                const SizedBox(height: 12),
                Text(
                  widget.description ??
                      'सानेपाको शान्त वातावरणमा अवस्थित यो २ कोठाको फ्ल्याट विद्यार्थी वा सानो परिवारको लागि उपयुक्त छ। उज्यालो कोठाहरू र खुल्ला पार्किङको सुविधा उपलब्ध छ। मुख्य बाटोबाट मात्र ५ मिनेटको दुरीमा।',
                  style: GoogleFonts.outfit(
                      fontSize: 15, color: airbnbGrey, height: 1.6),
                ),
                const SizedBox(height: 32),

                // LOCATION FOCUS SECTION
                _buildSectionTitle('लोकेशन (Location)'),
                const SizedBox(height: 16),
                _buildLocationDetails(widget.location, airbnbGrey),
                const SizedBox(height: 16),
                // Map View with rounded corners
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Stack(
                      children: [
                        Image.network(
                          'https://miro.medium.com/v2/resize:fit:1400/1*q69O5N7I6kUf6J39sP5nPQ.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black12, blurRadius: 10)
                              ],
                            ),
                            child: const Icon(Icons.location_on,
                                color: AppTheme.brandColor, size: 28),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // NEARBY PLACES
                _buildSectionTitle('वरपरका सुविधाहरू (Nearby)'),
                const SizedBox(height: 16),
                _buildNearbyGrid(),

                const SizedBox(height: 32),

                // OWNER PROFILE SECTION
                _buildSectionTitle('घरबेटीको विवरण (Owner)'),
                const SizedBox(height: 16),
                _buildOwnerCard(),

                const SizedBox(height: 32),

                // HOUSE RULES
                _buildSectionTitle('नियमहरू (House Rules)'),
                const SizedBox(height: 16),
                _buildRuleRow(Icons.pets_outlined, 'Pets Allowed', 'No'),
                _buildRuleRow(
                    Icons.smoke_free_outlined, 'Smoking', 'Outside only'),
                _buildRuleRow(Icons.people_outline, 'Max Guests', '4 People'),

                const SizedBox(height: 140),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(context),
    );
  }

  // --- COMPONENT BUILDERS ---

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentImageIndex = index),
              itemCount: displayImages.length,
              itemBuilder: (context, index) {
                return Image.network(displayImages[index], fit: BoxFit.cover);
              },
            ),
            // Image Indicator
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_currentImageIndex + 1} / ${displayImages.length}',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        _buildCircleAction(Icons.share_outlined, () {}),
        _buildCircleAction(Icons.favorite_border, () {}),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildCircleAction(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      child: CircleAvatar(
        backgroundColor: Colors.white,
        child: IconButton(
          icon: Icon(icon, color: Colors.black, size: 18),
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String location) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.brandColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, color: AppTheme.brandColor, size: 12),
              const SizedBox(width: 4),
              Text(
                'VERIFIED LISTING',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTextColor,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, color: Colors.grey, size: 16),
            const SizedBox(width: 4),
            Text(
              location,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertyStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: Border.symmetric(
            horizontal: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.bed_outlined, '${widget.bedrooms ?? 2}', 'Beds'),
          _buildStatItem(
              Icons.bathtub_outlined, '${widget.bathrooms ?? 1}', 'Baths'),
          _buildStatItem(
              Icons.square_foot_outlined, widget.area ?? '1200', 'Sq.ft'),
          _buildStatItem(Icons.layers_outlined, widget.floor ?? '2nd', 'Floor'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.black54, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildPriceBox(String price, Color airbnbGrey) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.brandColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.brandColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'महिनाको भाडा (Monthly Rent)',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: airbnbGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: price,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandColor,
                      ),
                    ),
                    TextSpan(
                      text: ' /महिना',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: airbnbGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
              ],
            ),
            child: Text(
              'Negotiable',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.brandColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEssentialGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.8,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildEssentialItem(
            Icons.water_drop_outlined, 'पानी (Water)', '24/7 Supply'),
        _buildEssentialItem(
            Icons.bolt_outlined, 'बिजुली (Light)', 'Sub-meter'),
        _buildEssentialItem(
            Icons.directions_car_outlined, 'पार्किङ (Parking)', 'Available'),
        _buildEssentialItem(Icons.wifi, 'इन्टरनेट (WiFi)', 'Available'),
      ],
    );
  }

  Widget _buildEssentialItem(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.brandColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style:
                        GoogleFonts.outfit(fontSize: 9, color: Colors.grey[600])),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                      fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyGrid() {
    return Column(
      children: [
        _buildNearbyItem(
            Icons.local_hospital_outlined, 'Hospital', '200m (Civil)'),
        _buildNearbyItem(Icons.school_outlined, 'School', '500m (KMC)'),
        _buildNearbyItem(Icons.shopping_bag_outlined, 'Market', '300m (Bazaar)'),
      ],
    );
  }

  Widget _buildNearbyItem(IconData icon, String title, String distance) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: Colors.blue[700]),
          ),
          const SizedBox(width: 12),
          Text(title,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[700])),
          const Spacer(),
          Text(
            distance,
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ram Bahadur',
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTextColor),
                ),
                Text(
                  'Verified Owner • 2 years',
                  style:
                      GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline,
                color: AppTheme.brandColor, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Text(title,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[700])),
          const Spacer(),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 19,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryTextColor,
      ),
    );
  }

  Widget _buildLocationDetails(String location, Color airbnbGrey) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.directions_walk,
                color: AppTheme.brandColor, size: 16),
            const SizedBox(width: 6),
            Text(
              'मुख्य बाटोबाट मात्र ५ मिनेट',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'शान्त टोल, ढल र पिच रोडको सुविधा भएको ठाउँ।',
          style: GoogleFonts.outfit(fontSize: 13, color: airbnbGrey),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cancel/Back button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close, color: Colors.black87, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            // Call Now Button
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.brandColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side:
                        const BorderSide(color: AppTheme.brandColor, width: 1.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Call Now',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Reserve Button
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [AppTheme.brandColor, Color(0xFF00B4F5)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.brandColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Increment Messages badge
                    messageBadgeCount.value += 1;
                    // Show premium notification
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        duration: const Duration(seconds: 3),
                        content: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'बुकिङ अनुरोध पठाइयो! ✅',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'मेसेज सेक्सनमा हेर्नुहोस् 💬',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Reserve (बुक गर्नुहोस्)',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
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
