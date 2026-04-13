import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// firebase_auth removed
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../utils/app_notifiers.dart';
import '../utils/supabase_service.dart';
import '../widgets/favourite_button.dart';
import 'chat_screen.dart';
import '../utils/formatters.dart';

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
  final String ownerId;
  final String status;
  final List<String> amenities;
  final List<String> houseRules;

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
    this.ownerId = '',
    this.status = 'available',
    this.amenities = const [],
    this.houseRules = const [],
  });

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool _isReserved = false;
  bool _isBooking = false;
  Map<String, dynamic>? _ownerData;

  String get _currentUserId => Supabase.instance.client.auth.currentUser?.id ?? '';
  bool get _isMyProperty => (widget.ownerId == _currentUserId) && !widget.id.contains('demo');
  static const Color _airbnbGrey = Color(0xFF717171);

  late final List<String> displayImages;

  @override
  void initState() {
    super.initState();
    _isReserved = widget.status == 'booked';
    _fetchOwnerData();
    displayImages = (widget.images != null && widget.images!.isNotEmpty)
        ? widget.images!
        : (widget.id.contains('demo')
            ? [
                widget.imageUrl,
                'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                'https://images.unsplash.com/photo-1493809842364-78817add7ffb?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
              ]
            : [widget.imageUrl]);
    _incrementViews();
  }

  Future<void> _incrementViews() async {
    if (widget.id.contains('demo')) return;
    try {
      await Supabase.instance.client.rpc(
        'increment_property_views',
        params: {'property_id': widget.id},
      );
    } catch (e) {
      debugPrint('Error incrementing views: $e');
    }
  }

  Future<void> _fetchOwnerData() async {
    if (widget.ownerId.isEmpty) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', widget.ownerId)
          .maybeSingle();
      if (mounted) {
        setState(() => _ownerData = data);
      }
    } catch (e) {
      debugPrint('Error fetching owner data: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined, color: Colors.black, size: 22), onPressed: () {}),
          FavouriteButton(
            propertyId: widget.id,
            size: 24,
            color: Colors.black,
            showShadow: false,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // IMAGE CAROUSEL (CONTAINED) - MOVED TO TOP
                _buildContainedCarousel(),
                const SizedBox(height: 24),

                // VERIFIED BADGE & TITLE - NOW BELOW IMAGE
                _buildHeader(widget.title, widget.location),
                const SizedBox(height: 32),

                // PROPERTY STATS (Beds, Baths, Area, Floor)
                // BEAUTIFIED AMENITY GRID (Kathmandu Specific)
                _buildAmenityGrid(),
                const SizedBox(height: 32),

                // PRICE BOX
                _buildPriceBox(widget.price),
                const SizedBox(height: 32),

                // DESCRIPTION
                _buildSectionTitle('Description'),
                const SizedBox(height: 12),
                Text(
                  widget.description ??
                      'सानेपाको शान्त वातावरणमा अवस्थित यो २ कोठाको फ्ल्याट विद्यार्थी वा सानो परिवारको लागि उपयुक्त छ। उज्यालो कोठाहरू र खुल्ला पार्किङको सुविधा उपलब्ध छ। मुख्य बाटोबाट मात्र ५ मिनेटको दुरीमा।',
                  style: GoogleFonts.inter(
                      fontSize: 15, color: _airbnbGrey, height: 1.6),
                ),
                const SizedBox(height: 32),

                // LOCATION FOCUS SECTION
                _buildSectionTitle('Location'),
                const SizedBox(height: 16),
                _buildLocationDetails(widget.location),
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
                if (widget.houseRules.isNotEmpty) ...[
                  _buildSectionTitle('नियमहरू (House Rules)'),
                  const SizedBox(height: 16),
                  ...widget.houseRules.map((rule) {
                    final detail = _ruleDetails(rule);
                    return _buildRuleRow(detail['icon'] as IconData, detail['label'] as String);
                  }),
                  const SizedBox(height: 32),
                ],

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

  Widget _buildContainedCarousel() {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentImageIndex = index),
              itemCount: displayImages.length,
              itemBuilder: (context, index) {
                final image = Image.network(displayImages[index], fit: BoxFit.cover);
                if (index == 0) {
                  return Hero(tag: widget.id, child: image);
                }
                return image;
              },
            ),
            // Bottom gradient for better contrast
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Dot Indicators
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  displayImages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: _currentImageIndex == index ? 18 : 6,
                    decoration: BoxDecoration(
                      color: _currentImageIndex == index 
                          ? Colors.white 
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            // Image Counter Badge
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentImageIndex + 1}/${displayImages.length}',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
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
                style: GoogleFonts.inter(
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
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTextColor,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.place_outlined, color: Colors.grey, size: 16),
            const SizedBox(width: 4),
            Text(
              location,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmenityGrid() {
    final Map<String, Map<String, dynamic>> amenityData = {
      'water_melamchi': {
        'icon': Icons.water_drop_outlined,
        'label': 'खानेपानी',
        'sub': 'Melamchi/Boring',
      },
      'parking_bike': {
        'icon': Icons.pedal_bike_outlined,
        'label': 'पार्किङ',
        'sub': 'Bike Parking',
      },
      'parking_car': {
        'icon': Icons.directions_car_outlined,
        'label': 'पार्किङ',
        'sub': 'Car Parking',
      },
      'sunny_room': {
        'icon': Icons.wb_sunny_outlined,
        'label': 'उज्यालो कोठा',
        'sub': 'Sunny Room',
      },
      'hot_water': {
        'icon': Icons.hot_tub_outlined,
        'label': 'तातो पानी',
        'sub': 'Solar/Electric',
      },
      'waste_mgmt': {
        'icon': Icons.delete_outline,
        'label': 'फोहोर व्यवस्थापन',
        'sub': 'Waste Mgmt',
      },
      'peaceful': {
        'icon': Icons.nature_people_outlined,
        'label': 'शान्त वातावरण',
        'sub': 'Peaceful',
      },
      'water_boring': {
        'icon': Icons.waves_outlined,
        'label': 'बोरिङ',
        'sub': 'Boring Water',
      },
      'internet': {
        'icon': Icons.wifi_outlined,
        'label': 'इन्टरनेट',
        'sub': 'Internet/Wifi',
      },
      'kitchen': {
        'icon': Icons.kitchen_outlined,
        'label': 'भान्सा',
        'sub': 'Separate Kitchen',
      },
    };

    List<Widget> items = [];
    
    // Add standard ones
    if (widget.bedrooms != null && widget.bedrooms! > 0) {
      items.add(_buildStatItem(Icons.bed_outlined, '${widget.bedrooms}', 'Bedrooms'));
    }
    if (widget.bathrooms != null && widget.bathrooms! > 0) {
      items.add(_buildStatItem(Icons.bathtub_outlined, '${widget.bathrooms}', 'Bathrooms'));
    }
    if (widget.floor != null && widget.floor != 'N/A' && widget.floor!.isNotEmpty) {
      items.add(_buildStatItem(Icons.layers_outlined, widget.floor!, 'Floor'));
    }
    if (widget.area != null && widget.area!.isNotEmpty) {
      items.add(_buildStatItem(Icons.square_foot_outlined, widget.area!, 'Sq. Ft'));
    }

    // Add Kathmandu specific ones
    for (var amenity in widget.amenities) {
      if (amenityData.containsKey(amenity)) {
        final data = amenityData[amenity]!;
        items.add(_buildStatItem(data['icon'], data['label'], data['sub']));
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        border: Border.symmetric(
            horizontal: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 24,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: items,
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.brandColor.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.brandColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, height: 1.1),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500], height: 1.1),
        ),
      ],
    );
  }

  Widget _buildPriceBox(String price) {
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
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _airbnbGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'रू ${PriceFormatter.format(price)}',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandColor,
                      ),
                    ),
                    TextSpan(
                      text: ' /महिना',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _airbnbGrey,
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
              style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700])),
          const Spacer(),
          Text(
            distance,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerCard() {
    final name = _ownerData?['full_name'] ?? 'Loading...';
    final avatar = _ownerData?['avatar_url'] ?? 'https://i.pravatar.cc/150?img=1';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(avatar),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTextColor),
                ),
                Text(
                  _isReserved 
                    ? 'Already Booked' 
                    : 'Verified Owner',
                  style: GoogleFonts.inter(
                    fontSize: 12, 
                    color: _isReserved ? Colors.orange.shade800 : Colors.grey[500],
                    fontWeight: _isReserved ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isMyProperty ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    ownerId: widget.ownerId,
                    name: name,
                    avatar: avatar,
                    online: true,
                  ),
                ),
              );
            },
            icon: Icon(Icons.chat_bubble_outline,
                color: _isMyProperty ? Colors.grey : AppTheme.brandColor, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Text(title,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Map<String, dynamic> _ruleDetails(String key) {
    switch (key) {
      case 'family_only':
        return {'icon': Icons.family_restroom, 'label': 'परिवार मात्र (Family Only)'};
      case 'boys_allowed':
        return {'icon': Icons.man, 'label': 'केटा मात्र (Boys Allowed)'};
      case 'girls_allowed':
        return {'icon': Icons.woman, 'label': 'केटी मात्र (Girls Allowed)'};
      case 'pets_allowed':
        return {'icon': Icons.pets, 'label': 'जनावर राख्न पाईने (Pets Allowed)'};
      case 'smoking_allowed':
        return {'icon': Icons.smoke_free, 'label': 'चुरोट पिउन पाईने (Smoking Allowed)'};
      case 'alcohol_allowed':
        return {'icon': Icons.local_bar, 'label': 'मदिरा पिउन पाईने (Alcohol Allowed)'};
      default:
        return {'icon': Icons.info_outline, 'label': key};
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 19,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryTextColor,
      ),
    );
  }

  Widget _buildLocationDetails(String location) {
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
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'शान्त टोल, ढल र पिच रोडको सुविधा भएको ठाउँ।',
          style: GoogleFonts.inter(fontSize: 13, color: _airbnbGrey),
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
            // Call Now Button
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  border: Border.all(color: AppTheme.brandColor.withValues(alpha: 0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppTheme.brandColor,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone_rounded, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Call',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Dynamic Action Button (Reserve -> Cancel)
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (_isReserved || _isBooking) 
                  ? (_isMyProperty && _isReserved ? () async {
                      // OWNER CANCEL FEATURE
                      setState(() => _isBooking = true);
                      try {
                        await SupabaseService.cancelBooking(widget.id);
                        if (mounted) {
                          setState(() {
                            _isReserved = false;
                            _isBooking = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Status set to Available'))
                          );
                        }
                      } catch (e) {
                         if (mounted) setState(() => _isBooking = false);
                      }
                    } : null)
                  : () async {
                    setState(() => _isBooking = true);
                    try {
                      // Call Supabase Magic
                      await SupabaseService.bookProperty(widget.id, widget.title, widget.ownerId);
                      
                      // Increment Notifications badge
                      notificationBadgeCount.value += 1;
                      
                      if (mounted) {
                        setState(() {
                          _isReserved = true;
                          _isBooking = false;
                        });

                        // Show premium notification
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            content: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E).withOpacity(0.95),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Reserved Successfully!',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'The owner has been notified.',
                                          style: GoogleFonts.inter(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() => _isBooking = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text('Booking failed: $e'))
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isMyProperty 
                        ? Colors.blue[600]
                        : _isReserved 
                            ? Colors.grey[700] 
                            : AppTheme.brandColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: AppTheme.brandColor.withOpacity(0.3),
                  ),
                child: Text(
                  (_isMyProperty && !widget.id.contains('demo'))
                      ? 'Your Listing'
                      : _isReserved 
                          ? 'Booked ✓' 
                          : 'BOOK NOW (बुक गर्नुहोस्)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
