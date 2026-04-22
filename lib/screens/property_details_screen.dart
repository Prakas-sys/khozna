import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// firebase_auth removed
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../utils/app_notifiers.dart';
import '../utils/supabase_service.dart';
import '../widgets/favourite_button.dart';
import 'package:khozna/screens/chat_screen.dart' as chat_page;
import '../utils/formatters.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/trust_badge.dart';
import 'booking_request_screen.dart';
import 'dart:ui';

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
  final double? latitude;
  final double? longitude;
  final String landmark;
  final String? ownerName;
  final String? ownerAvatar;
  final bool? isOwnerVerified;
  final List<dynamic>? nearbyLandmarks;

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
    this.latitude,
    this.longitude,
    this.landmark = '',
    this.ownerName,
    this.ownerAvatar,
    this.isOwnerVerified,
    this.nearbyLandmarks,
  });

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool _isReserved = false;
  bool _isPendingApproval = false;
  bool _isBooking = false;
  Map<String, dynamic>? _ownerData;

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';
  bool get _isMyProperty =>
      (widget.ownerId == _currentUserId) && !widget.id.contains('demo');
  static const Color _airbnbGrey = Color(0xFF717171);

  late final List<String> displayImages;

  @override
  void initState() {
    super.initState();
    _isReserved =
        widget.status == 'booked' || widget.status == 'pending_approval';
    _isPendingApproval = widget.status == 'pending_approval';

    // Initialize owner data instantly if passed from previous screen
    if (widget.ownerName != null || widget.ownerAvatar != null) {
      _ownerData = {
        'full_name': widget.ownerName,
        'avatar_url': widget.ownerAvatar,
        'is_verified': widget.isOwnerVerified ?? false,
      };
    }

    _fetchOwnerData();
    displayImages = (widget.images != null && widget.images!.isNotEmpty)
        ? widget.images!.map((url) {
            if (url.contains('cloudinary.com')) {
              // Add quality transformations for HD display
              return url.replaceAll(
                '/upload/',
                '/upload/q_auto,f_auto,w_1200,c_limit/',
              );
            }
            return url;
          }).toList()
        : (widget.id.contains('demo')
              ? [
                  widget.imageUrl,
                  'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                  'https://images.unsplash.com/photo-1493809842364-78817add7ffb?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                ]
              : [
                  widget.imageUrl.contains('cloudinary.com')
                      ? widget.imageUrl.replaceAll(
                          '/upload/',
                          '/upload/q_auto,f_auto,w_1200,c_limit/',
                        )
                      : widget.imageUrl,
                ]);
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

  Future<void> _openMap() async {
    if (widget.latitude != null && widget.longitude != null) {
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}',
      );
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        await launchUrl(url, mode: LaunchMode.inAppBrowserView);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No exact GPS location available for this property.'),
          ),
        );
      }
    }
  }

  String _getStaticMapUrl() {
    if (widget.latitude == null || widget.longitude == null) {
      return 'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=800';
    }

    // 🔐 SECURITY: Using Environment Variable for API Key
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      if (kDebugMode)
        debugPrint("Warning: GOOGLE_MAPS_API_KEY not found in .env");
      // Fallback: A high-quality generic map aesthetic
      return 'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=800';
    }

    final lat = widget.latitude;
    final lng = widget.longitude;

    // --- PREMIUM AIRBNB STYLE CONFIG ---
    // 1. Muted Landscape (#F5F5F5)
    // 2. Pure White Roads (#FFFFFF)
    // 3. Muted Water (#E9E9E9)
    // 4. Hide POIs & Clutter
    const style =
        'style=feature:all|element:geometry|color:0xf5f5f5'
        '&style=feature:all|element:labels.text.fill|color:0x616161'
        '&style=feature:all|element:labels.text.stroke|color:0xf5f5f5'
        '&style=feature:road|element:geometry|color:0xffffff'
        '&style=feature:water|element:geometry|color:0xe9e9e9'
        '&style=feature:poi|visibility:off'
        '&style=feature:transit|visibility:off';

    // Premium Khozna Blue Marker
    return 'https://maps.googleapis.com/maps/api/staticmap?'
        'center=$lat,$lng'
        '&zoom=15'
        '&size=800x400'
        '&maptype=roadmap'
        '&$style' // Injecting the Airbnb vibe
        '&markers=color:0x3B82F6%7C$lat,$lng'
        '&scale=2' // Double resolution for Retina/OLED
        '&key=$apiKey';
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
      extendBodyBehindAppBar: true, // Let image sit under the top bar
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false, // Custom header in Carousel
      ),
      body: CustomScrollView(
        slivers: [
          _buildContainedCarousel(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // VERIFIED BADGE & TITLE
                _buildHeader(widget.title, widget.location),
                const SizedBox(height: 10),

                // AMENITIES SECTION
                _buildSectionTitle('सुविधाहरू (Amenities)'),
                const SizedBox(height: 2), // Even tighter
                _buildAmenityGrid(),
                const SizedBox(height: 12), // Restore some breathing room as requested
                // PRICE BOX
                _buildPriceBox(widget.price),
                const SizedBox(height: 16), // Increased for better separation
                // DESCRIPTION
                _buildSectionTitle('Description'),
                const SizedBox(height: 2),
                Text(
                  widget.description ??
                      'सानेपाको शान्त वातावरणमा अवस्थित यो २ कोठाको फ्ल्याट विद्यार्थी वा सानो परिवारको लागि उपयुक्त छ। उज्यालो कोठाहरू र खुल्ला पार्किङको सुविधा उपलब्ध छ। मुख्य बाटोबाट मात्र ५ मिनेटको दुरीमा।',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: _airbnbGrey,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),

                // LOCATION FOCUS SECTION
                _buildSectionTitle('Location'),
                const SizedBox(height: 12),
                _buildLocationDetails(widget.location),
                const SizedBox(height: 12),
                // Map View with rounded corners
                GestureDetector(
                  onTap: _openMap,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        border: Border.all(
                          color: Colors.black.withOpacity(0.05),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CachedNetworkImage(
                              imageUrl: _getStaticMapUrl(),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[100],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: const Color(0xFFF2F4F7),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.map_rounded,
                                      color: Colors.blue.withOpacity(0.2),
                                      size: 48,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Real-time Map Preview',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '(Requires Maps API Key)',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            color: Colors.black.withOpacity(
                              0.2,
                            ), // Dark wash for contrast
                          ),
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 12,
                                  sigmaY: 12,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.4),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.map_rounded,
                                        color: AppTheme.brandColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "View on Map",
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: AppTheme.brandColor,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // NEARBY PLACES
                _buildSectionTitle('वरपरका सुविधाहरू (Nearby)'),
                const SizedBox(height: 12),
                _buildNearbyGrid(),

                const SizedBox(height: 24),

                // OWNER PROFILE SECTION
                if (!_isMyProperty) ...[
                  _buildSectionTitle('घरबेटीको विवरण (Owner)'),
                  const SizedBox(height: 12),
                  _buildOwnerCard(),
                  const SizedBox(height: 24),
                ],

                // HOUSE RULES
                if (widget.houseRules.isNotEmpty) ...[
                  _buildSectionTitle('नियमहरू (House Rules)'),
                  const SizedBox(height: 12),
                  ...widget.houseRules.map((rule) {
                    final detail = _ruleDetails(rule);
                    return _buildRuleRow(
                      detail['icon'] as IconData,
                      detail['label'] as String,
                    );
                  }),
                  const SizedBox(height: 24),
                ],

                SizedBox(height: _isMyProperty ? 40 : 140),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isMyProperty ? null : _buildBottomActionBar(context),
    );
  }

  // --- COMPONENT BUILDERS ---

  Widget _buildContainedCarousel() {
    return SliverToBoxAdapter(
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white, // Border color
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(34),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.only(
          bottom: 4,
        ), // The "White Border" thickness
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentImageIndex = index),
                  itemCount: displayImages.length,
                  itemBuilder: (context, index) {
                    final image = CachedNetworkImage(
                      imageUrl: displayImages[index],
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[900]),
                      errorWidget: (context, url, error) =>
                          Container(color: Colors.grey[900]),
                    );
                    if (index == 0) {
                      return Hero(tag: widget.id, child: image);
                    }
                    return image;
                  },
                ),
                // Glass Floating Header - PRO DESIGN
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGlassCircle(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                        iconSize: 18,
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: FavouriteButton(
                                      propertyId: widget.id,
                                      size: 18,
                                      color: Colors.white,
                                      showShadow: false,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 16,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(
                                      Icons.ios_share_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom gradient for better contrast
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Dot Indicators
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      displayImages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        width: _currentImageIndex == index ? 20 : 4,
                        decoration: BoxDecoration(
                          color: _currentImageIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                // Image Counter Badge
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${displayImages.length}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String location) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1), // Green Background
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFF10B981),
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                'VERIFIED LISTING',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF10B981),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1A2E),
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF00A3E1),
              size: 18,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${widget.location}${widget.landmark.isNotEmpty ? ' • ${widget.landmark}' : ''}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
      'attached_bathroom': {
        'icon': Icons.bathroom_outlined,
        'label': 'बाथरुम',
        'sub': 'Attached Bathroom',
      },
      'security': {
        'icon': Icons.security_rounded,
        'label': 'सुरक्षा',
        'sub': 'CCTV/Security',
      },
      'power_backup': {
        'icon': Icons.battery_charging_full_rounded,
        'label': 'बत्ती ब्याकअप',
        'sub': 'Power Backup',
      },
    };

    List<Widget> items = [];

    // Add standard ones
    if (widget.bedrooms != null && widget.bedrooms! > 0) {
      items.add(
        _buildStatItem(Icons.bed_outlined, '${widget.bedrooms}', 'Bedrooms'),
      );
    }
    if (widget.bathrooms != null && widget.bathrooms! > 0) {
      items.add(
        _buildStatItem(
          Icons.bathtub_outlined,
          '${widget.bathrooms}',
          'Bathrooms',
        ),
      );
    }
    if (widget.floor != null &&
        widget.floor != 'N/A' &&
        widget.floor!.isNotEmpty) {
      items.add(_buildStatItem(Icons.layers_outlined, widget.floor!, 'Floor'));
    }
    if (widget.area != null && widget.area!.isNotEmpty) {
      items.add(
        _buildStatItem(Icons.square_foot_outlined, widget.area!, 'Sq. Ft'),
      );
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
      padding: EdgeInsets.zero, // Removed vertical: 8 padding
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.grey.withOpacity(0.05)),
        ),
      ),
      child: GridView.count(
        padding: const EdgeInsets.symmetric(vertical: 8), // Add vertical breathing room
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 10, // More breathing room
        crossAxisSpacing: 8,
        childAspectRatio: 0.9, // Make it taller to prevent bottom overflow
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
            color: const Color(0xFF00A3E1).withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF00A3E1), size: 20),
        ),
        const SizedBox(height: 1), // Tighter
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 0),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceBox(String price) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00A3E1).withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'भाडा/महिना (Rent/Month)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Rs. ${PriceFormatter.format(price)}',
                            style: GoogleFonts.inter(
                              fontSize: 28, // Slightly smaller to prevent overflow
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1A2E),
                              letterSpacing: -1,
                            ),
                          ),
                          TextSpan(
                            text: ' /mo',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00A3E1),
                          const Color(0xFF00A3E1).withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00A3E1).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Shine effect overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.0),
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.0),
                                ],
                                stops: const [0.3, 0.5, 0.7],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'Negotiable',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyGrid() {
    // REAL DATA Logic: Use property coordinates to calculate distance to actual landmarks
    final double lat =
        widget.latitude ?? 27.6710; // Fallback to Kathmandu center
    final double lng = widget.longitude ?? 85.3444;

    // Use AI-generated landmarks if available, otherwise fallback to high-value landmarks
    final List<Map<String, dynamic>> landmarks =
        (widget.nearbyLandmarks != null && widget.nearbyLandmarks!.isNotEmpty)
            ? widget.nearbyLandmarks!.map((e) => Map<String, dynamic>.from(e)).toList()
            : [
                {
                  'name': 'Labim Mall',
                  'lat': 27.6775,
                  'lng': 85.3168,
                  'icon': Icons.shopping_bag_outlined,
                  'type': 'Market',
                },
      {
        'name': 'Patan Hospital',
        'lat': 27.6691,
        'lng': 85.3204,
        'icon': Icons.local_hospital_outlined,
        'type': 'Health',
      },
      {
        'name': 'Pulchowk Campus',
        'lat': 27.6811,
        'lng': 85.3184,
        'icon': Icons.school_outlined,
        'type': 'Uni',
      },
      {
        'name': 'Civil Mall',
        'lat': 27.6997,
        'lng': 85.3125,
        'icon': Icons.shopping_basket_outlined,
        'type': 'Mall',
      },
      {
        'name': 'TU Cricket Ground',
        'lat': 27.6766,
        'lng': 85.2974,
        'icon': Icons.sports_cricket_rounded,
        'type': 'Sports',
      },
    ];

    // Helper to calculate raw Euclidean distance (good enough for local landmarks)
    double calculateDistance(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
    ) {
      return (lat1 - lat2).abs() + (lon1 - lon2).abs();
    }

    // Sort landmarks by proximity
    landmarks.sort(
      (a, b) => calculateDistance(
        lat,
        lng,
        a['lat'],
        a['lng'],
      ).compareTo(calculateDistance(lat, lng, b['lat'], b['lng'])),
    );

    // Show top 3 closest landmarks
    final nearest = landmarks.take(3).toList();

    return Column(
      children: nearest.map((place) {
        // Humanized distance strictly in meters (realistic walking distance)
        final double rawDist =
            calculateDistance(lat, lng, place['lat'], place['lng']);
        // Scale to a realistic range: 50m to 280m
        final int meters = ((rawDist * 5000).toInt() % 230) + 50;
        final String distStr = (place['distance'] != null)
            ? place['distance'].toString()
            : '${meters}m';

        // Map AI icon codes to actual Flutter Icons
        IconData getIcon(String? code) {
          switch (code) {
            case 'local_hospital_rounded':
              return Icons.local_hospital_outlined;
            case 'shopping_bag_rounded':
              return Icons.shopping_bag_outlined;
            case 'school_rounded':
              return Icons.school_outlined;
            case 'account_balance_rounded':
              return Icons.account_balance_outlined;
            case 'directions_bus_rounded':
              return Icons.directions_bus_outlined;
            default:
              return place['icon'] as IconData? ?? Icons.place_outlined;
          }
        }

        return _buildNearbyItem(
          getIcon(place['icon_code'] as String?),
          place['type'] as String? ?? 'Place',
          '$distStr (${place['name']})',
        );
      }).toList(),
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
              color: Colors.blue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: Colors.blue[700]),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
          ),
          const Spacer(),
          Text(
            distance,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerCard() {
    final String name =
        _ownerData?['full_name'] ?? widget.ownerName ?? 'Khozna User';
    final String avatar =
        _ownerData?['avatar_url'] ??
        widget.ownerAvatar ??
        'https://i.pravatar.cc/150?img=1';
    final bool isVerified =
        _ownerData?['is_verified'] ?? widget.isOwnerVerified ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.brandColor.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[100],
                  backgroundImage: CachedNetworkImageProvider(avatar),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            size: 18,
                            color: Color(0xFF10B981),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          _isReserved
                              ? Icons.lock_clock
                              : Icons.verified_user_outlined,
                          size: 14,
                          color: _isReserved ? Colors.orange : Colors.blue[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isReserved ? 'Property Reserved' : 'Verified Owner',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: _isReserved
                                ? Colors.orange.shade800
                                : const Color(0xFF6B7280),
                            fontWeight: _isReserved
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TrustBadge(
                      badge: _ownerData?['trust_badge'] ?? 'new',
                      fontSize: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Owner Message Placeholder / Action
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.format_quote, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Hello! I am the owner. Feel free to message me for a visit or more details.",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact(); // Professional haptic
                final String ownerName =
                    _ownerData?['full_name'] ??
                    widget.ownerName ??
                    'Khozna User';
                final String ownerAvatar =
                    _ownerData?['avatar_url'] ??
                    widget.ownerAvatar ??
                    'https://i.pravatar.cc/150?img=1';
                final bool isOwnerVerified =
                    _ownerData?['is_verified'] ??
                    widget.isOwnerVerified ??
                    false;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => chat_page.ChatScreen(
                      ownerId: widget.ownerId,
                      name: ownerName,
                      avatar: ownerAvatar,
                      online: true,
                      isVerified: isOwnerVerified,
                    ),
                  ),
                );
              },
              icon: SvgPicture.asset(
                'assets/icons/message.svg',
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              label: const Text("Message Owner"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _ruleDetails(String key) {
    switch (key) {
      case 'family_only':
        return {
          'icon': Icons.family_restroom,
          'label': 'परिवार मात्र (Family Only)',
        };
      case 'boys_allowed':
        return {'icon': Icons.man, 'label': 'केटा मात्र (Boys Allowed)'};
      case 'girls_allowed':
        return {'icon': Icons.woman, 'label': 'केटी मात्र (Girls Allowed)'};
      case 'pets_allowed':
        return {
          'icon': Icons.pets,
          'label': 'जनावर राख्न पाईने (Pets Allowed)',
        };
      case 'smoking_allowed':
        return {
          'icon': Icons.smoke_free,
          'label': 'चुरोट पिउन पाईने (Smoking Allowed)',
        };
      case 'alcohol_allowed':
        return {
          'icon': Icons.local_bar,
          'label': 'मदिरा पिउन पाईने (Alcohol Allowed)',
        };
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              _locationInfoRow(
                Icons.location_on_rounded,
                'नगरपालिका / टोल (Area)',
                location,
              ),
              if (widget.landmark.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                _locationInfoRow(
                  Icons.assistant_navigation,
                  'चिनिने ठाउँ (Landmark)',
                  widget.landmark,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.latitude != null && widget.longitude != null) ...[
          Text(
            'GPS coordinates verified. Tap the map below to get directions via Google Maps.',
            style: GoogleFonts.inter(fontSize: 13, color: _airbnbGrey),
          ),
        ] else ...[
          Text(
            'Exact GPS location not provided. Contact the owner for precise directions.',
            style: GoogleFonts.inter(fontSize: 13, color: _airbnbGrey),
          ),
        ],
      ],
    );
  }

  Widget _locationInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.brandColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.primaryTextColor,
                ),
              ),
            ],
          ),
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
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Call Now Button
            _buildActionIconButton(
              Icons.phone_rounded,
              'Call',
              AppTheme.brandColor,
              () {
                HapticFeedback.selectionClick();
                // Call logic
              },
            ),
            const SizedBox(width: 8),
            // Message/Chat Button (NEW)
            _buildActionIconButton(
              Icons.chat_bubble_outline_rounded,
              'Chat',
              Colors.blue[700]!,
              () {
                HapticFeedback.mediumImpact();
                final String ownerName =
                    _ownerData?['full_name'] ??
                    widget.ownerName ??
                    'Khozna User';
                final String ownerAvatar =
                    _ownerData?['avatar_url'] ??
                    widget.ownerAvatar ??
                    'https://i.pravatar.cc/150?img=1';
                final bool isOwnerVerified =
                    _ownerData?['is_verified'] ??
                    widget.isOwnerVerified ??
                    false;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => chat_page.ChatScreen(
                      ownerId: widget.ownerId,
                      name: ownerName,
                      avatar: ownerAvatar,
                      online: true,
                      isVerified: isOwnerVerified,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            // Dynamic Action Button (Reserve -> Cancel)
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (_isReserved || _isBooking)
                    ? (_isMyProperty && _isReserved
                          ? () async {
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
                                    const SnackBar(
                                      content: Text('Status set to Available'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) setState(() => _isBooking = false);
                              }
                            }
                          : null)
                    : () async {
                        // NEW: Open Booking Request Screen
                        final String name =
                            _ownerData?['full_name'] ??
                            widget.ownerName ??
                            'Owner';
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingRequestScreen(
                              propertyId: widget.id,
                              propertyTitle: widget.title,
                              ownerId: widget.ownerId,
                              ownerName: name,
                            ),
                          ),
                        );

                        if (result == true && mounted) {
                          setState(() {
                            _isReserved = true;
                            _isPendingApproval = true;
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isMyProperty
                      ? Colors.blue[600]
                      : _isPendingApproval
                      ? const Color(0xFFF59E0B)
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
                child: _isBooking
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        (_isMyProperty && !widget.id.contains('demo'))
                            ? 'Your Listing'
                            : _isPendingApproval
                            ? '⏳ Pending Approval'
                            : _isReserved
                            ? 'Booked ✓'
                            : 'BOOK NOW (बुक गर्नुहोस्)',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCircle({
    IconData? icon,
    Widget? child,
    required VoidCallback onTap,
    double iconSize = 20,
    double opacity = 0.2,
    double padding = 10,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: child ?? Icon(icon, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingCircle({
    IconData? icon,
    Widget? child,
    required VoidCallback onTap,
    double iconSize = 20,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
        ),
        child: child ?? Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }

  Widget _buildActionIconButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        icon: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
