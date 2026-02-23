import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

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
    displayImages = widget.images ?? [
      widget.imageUrl,
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1493809842364-78817add7ffb?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
    ];
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
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    widget.description ?? 'सानेपाको शान्त वातावरणमा अवस्थित यो २ कोठाको फ्ल्याट विद्यार्थी वा सानो परिवारको लागि उपयुक्त छ। उज्यालो कोठाहरू र खुल्ला पार्किङको सुविधा उपलब्ध छ। मुख्य बाटोबाट मात्र ५ मिनेटको दुरीमा।',
                    style: GoogleFonts.outfit(fontSize: 15, color: airbnbGrey, height: 1.6),
                  ),
                  const SizedBox(height: 32),

                  // LOCATION FOCUS SECTION
                  _buildSectionTitle('लोकेशन र वरपरका सुविधाहरू (Location)'),
                  const SizedBox(height: 16),
                  _buildLocationDetails(widget.location, airbnbGrey),
                  const SizedBox(height: 16),
                  // Fake Map View
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey[200]!),
                      image: const DecorationImage(
                        image: NetworkImage('https://miro.medium.com/v2/resize:fit:1400/1*q69O5N7I6kUf6J39sP5nPQ.png'), // Placeholder map
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.location_on, color: AppTheme.brandColor, size: 30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // NEARBY PLACES
                  _buildSectionTitle('वरपरका मुख्य ठाउँहरू (Nearby Places)'),
                  const SizedBox(height: 16),
                  _buildNearbyGrid(),

                  const SizedBox(height: 32),

                  // GHARBETI (OWNER) PROFILE SECTION
                  _buildSectionTitle('घरबेटीको विवरण (Owner Profile)'),
                  const SizedBox(height: 16),
                  _buildOwnerCard(),

                  const SizedBox(height: 32),
                  
                  // HOUSE RULES
                  _buildSectionTitle('नियमहरू (House Rules)'),
                  const SizedBox(height: 16),
                  _buildRuleRow(Icons.pets_outlined, 'Pets Allowed', 'No'),
                  _buildRuleRow(Icons.smoke_free_outlined, 'Smoking', 'Outside only'),
                  _buildRuleRow(Icons.people_outline, 'Max Guests', '4 People'),
                  
                  const SizedBox(height: 120), 
                ],
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(context),
    );
  }

  // --- COMPONENT BUILDERS ---

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemCount: displayImages.length,
              itemBuilder: (context, index) {
                return Hero(
                  tag: index == 0 ? 'property-image-${widget.id}' : 'property-image-${widget.id}-$index',
                  child: Image.network(displayImages[index], fit: BoxFit.cover),
                );
              },
            ),
            // Image Indicator
            Positioned(
              bottom: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentImageIndex + 1} / ${displayImages.length}',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.black, size: 20),
              onPressed: () {},
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.black, size: 20),
              onPressed: () {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String title, String location) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: AppTheme.brandColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.verified, color: AppTheme.brandColor, size: 14),
            const SizedBox(width: 6),
            Text('VERIFIED LISTING', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.brandColor, letterSpacing: 0.5)),
          ]),
        ),
        const SizedBox(height: 16),
        Text(title, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryTextColor, height: 1.2)),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.location_on, color: Colors.grey, size: 18),
          const SizedBox(width: 4),
          Text(location, style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey[600])),
        ]),
      ],
    );
  }

  Widget _buildPropertyStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.bed_outlined, '${widget.bedrooms ?? 2}', 'Beds'),
          _buildStatItem(Icons.bathtub_outlined, '${widget.bathrooms ?? 1}', 'Baths'),
          _buildStatItem(Icons.square_foot_outlined, widget.area ?? '1200', 'Sq.ft'),
          _buildStatItem(Icons.layers_outlined, widget.floor ?? '2nd', 'Floor'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[400], size: 24),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildPriceBox(String price, Color airbnbGrey) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.brandColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.brandColor.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('महिनाको भाडा (Monthly Rent)', style: GoogleFonts.outfit(fontSize: 12, color: airbnbGrey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            RichText(text: TextSpan(children: [
              TextSpan(text: price, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.brandColor)),
              TextSpan(text: ' /mo', style: GoogleFonts.outfit(fontSize: 16, color: airbnbGrey)),
            ])),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: Text('Negotiable', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.brandColor)),
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
      childAspectRatio: 2.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildEssentialItem(Icons.water_drop_outlined, 'पानी (Water)', '24/7 Supply'),
        _buildEssentialItem(Icons.bolt_outlined, 'बिजुली (Light)', 'Sub-meter'),
        _buildEssentialItem(Icons.directions_car_outlined, 'पार्किङ (Parking)', 'Bike/Car'),
        _buildEssentialItem(Icons.wifi, 'इन्टरनेट (WiFi)', '50 Mbps'),
      ],
    );
  }

  Widget _buildEssentialItem(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.brandColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[600])),
                Text(value, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
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
        _buildNearbyItem(Icons.local_hospital_outlined, 'Hospital', '200m (Civil Hospital)'),
        _buildNearbyItem(Icons.school_outlined, 'School', '500m (St. Xavier\'s)'),
        _buildNearbyItem(Icons.shopping_cart_outlined, 'Market', '100m (Local Bazaar)'),
        _buildNearbyItem(Icons.bus_alert_outlined, 'Bus Stop', '50m (Main Road)'),
      ],
    );
  }

  Widget _buildNearbyItem(IconData icon, String title, String distance) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: Colors.blue[700]),
          ),
          const SizedBox(width: 16),
          Text(title, style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey[700])),
          const Spacer(),
          Text(distance, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryTextColor)),
        ],
      ),
    );
  }

  Widget _buildOwnerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.verified, color: Colors.blue, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ram Bahadur', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryTextColor)),
                    const SizedBox(height: 4),
                    Text('Verified Gharbeti • 2 years', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[500])),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOwnerStat('4.9', 'Rating'),
              _buildOwnerStat('98%', 'Response'),
              _buildOwnerStat('5', 'Listings'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryTextColor)),
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildRuleRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(title, style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey[700])),
          const Spacer(),
          Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryTextColor));
  }

  Widget _buildLocationDetails(String location, Color airbnbGrey) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.directions_walk, color: AppTheme.brandColor, size: 18),
          const SizedBox(width: 8),
          Text('मुख्य बाटोबाट मात्र ५ मिनेट', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
        const SizedBox(height: 8),
        Text('शान्त टोल, ढल र पिच रोडको सुविधा भएको ठाउँ।', style: GoogleFonts.outfit(fontSize: 14, color: airbnbGrey)),
      ],
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Stack(
        children: [
          // Glassmorphism Blur Effect
          Positioned.fill(
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Row(
              children: [
                // Cancel Button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.black54, size: 20),
                  ),
                  tooltip: 'Cancel',
                ),
                const SizedBox(width: 8),
                // Message Button
                IconButton(
                  onPressed: () {},
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.brandColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_outline, color: AppTheme.brandColor, size: 20),
                  ),
                  tooltip: 'Message',
                ),
                const SizedBox(width: 8),
                // Call Button
                IconButton(
                  onPressed: () {},
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.brandColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_outlined, color: AppTheme.brandColor, size: 20),
                  ),
                  tooltip: 'Call',
                ),
                const SizedBox(width: 12),
                // Primary Action: Schedule Site Visit
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [AppTheme.brandColor, Color(0xFFFF8C42)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandColor.withOpacity(0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Schedule Site Visit',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Top Border Line
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 0.5,
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}
