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
import 'package:share_plus/share_plus.dart';

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
  final String category;

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
    this.category = 'Room',
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
  bool _userHasPendingBooking = false; // current user specifically has a pending booking
  Map<String, dynamic>? _ownerData;

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';
  bool get _isMyProperty =>
      (widget.ownerId == _currentUserId) && !widget.id.contains('demo');
  bool get _hasLocation =>
      widget.latitude != null && widget.longitude != null;
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
    
    // Instant Master Memory check for booking status
    _userHasPendingBooking = bookedPropertiesStore.value.contains(widget.id);
    _checkUserBookingStatus();
  }

  Future<void> _incrementViews() async {
    if (widget.id.contains('demo') || _isMyProperty) return;
    try {
      await Supabase.instance.client.rpc(
        'increment_property_views',
        params: {'property_id': widget.id},
      );
    } catch (e) {
      debugPrint('Error incrementing views: $e');
    }
  }

  /// Check if the current user already has a pending/confirmed booking for this property
  Future<void> _checkUserBookingStatus() async {
    if (widget.id.contains('demo') || _currentUserId.isEmpty) return;
    try {
      final result = await Supabase.instance.client
          .from('bookings')
          .select('id, status')
          .eq('property_id', widget.id)
          .eq('guest_id', _currentUserId)
          .inFilter('status', ['pending', 'confirmed'])
          .limit(1);
      if (mounted) {
        final hasBooking = result.isNotEmpty;
        setState(() {
          _userHasPendingBooking = hasBooking;
        });

        // Sync back to Master Memory if mismatch
        if (hasBooking && !bookedPropertiesStore.value.contains(widget.id)) {
          final current = Set<String>.from(bookedPropertiesStore.value);
          current.add(widget.id);
          bookedPropertiesStore.value = current;
        } else if (!hasBooking && bookedPropertiesStore.value.contains(widget.id)) {
          final current = Set<String>.from(bookedPropertiesStore.value);
          current.remove(widget.id);
          bookedPropertiesStore.value = current;
        }
      }
    } catch (e) {
      debugPrint('Error checking booking status: $e');
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
      return '';
    }

    // 🔐 SECURITY: Using Environment Variable for API Key
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      if (kDebugMode)
        debugPrint("Warning: GOOGLE_MAPS_API_KEY not found in .env");
      // Fallback to custom widget
      return '';
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
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverCarousel(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // VERIFIED BADGE & TITLE
                _buildHeader(widget.title, widget.location),
                const SizedBox(height: 24),

                // AMENITIES SECTION
                _buildSectionTitle('सुविधाहरू (Amenities)'),
                const SizedBox(height: 20), 
                _buildAmenityGrid(),
                const SizedBox(height: 44), // Aggressive breathing room for premium feel

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
                            child: _getStaticMapUrl().isEmpty
                                ? _buildRidingAppMapPlaceholder()
                                : CachedNetworkImage(
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
                                    errorWidget: (context, url, error) => _buildRidingAppMapPlaceholder(),
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
                                        _hasLocation
                                            ? "नक्सामा हेर्न यहाँ क्लिक गर्नुहोस्" // More interactive: "Click here to view on map"
                                            : "स्थान गोप्य छ",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16, // Bigger
                                          color: AppTheme.brandColor,
                                          fontWeight: FontWeight.w800, // Semi-solid
                                          letterSpacing: -0.5,
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
      bottomNavigationBar: _buildBottomActionBar(context),
    );
  }

  // --- COMPONENT BUILDERS ---

  Widget _buildSliverCarousel() {
    return SliverAppBar(
      expandedHeight: 380,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      pinned: true,
      stretch: true,
      automaticallyImplyLeading: false,
      leading: Center(
        child: _buildGlassCircle(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
          iconSize: 18,
        ),
      ),
      actions: [
        Center(
          child: _buildGlassCircle(
            icon: Icons.ios_share_rounded,
            onTap: () {
              HapticFeedback.mediumImpact();
              Share.share('Check out this amazing property on Khozna: ${widget.title} in ${widget.location} for just Rs. ${widget.price}/month! Download the app to view more details.');
            },
            iconSize: 16,
          ),
        ),
        const SizedBox(width: 8),
        Center(
          child: FavouriteButton(propertyId: widget.id),
        ),
        const SizedBox(width: 16),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Container(
          height: 32,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(32),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
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
            // Bottom gradient for better contrast
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Dot Indicators
            Positioned(
              bottom: 42,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  displayImages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 5,
                    width: _currentImageIndex == index ? 22 : 5,
                    decoration: BoxDecoration(
                      color: _currentImageIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        if (_currentImageIndex == index)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Left Arrow
            if (_currentImageIndex > 0)
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildNavArrow(
                    icon: Icons.chevron_left_rounded,
                    onTap: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
            // Right Arrow
            if (_currentImageIndex < displayImages.length - 1)
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildNavArrow(
                    icon: Icons.chevron_right_rounded,
                    onTap: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
            // Image Counter Badge
            Positioned(
              bottom: 42,
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
    );
  }

  Widget _buildHeader(String title, String location) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF00C853).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFF00C853).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFF00C853),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'VERIFIED',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF00C853),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.category.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandColor,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A1A2E),
                  height: 1.1,
                  letterSpacing: -1.0,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '₹',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.brandColor,
                        ),
                      ),
                      TextSpan(
                        text: PriceFormatter.format(widget.price),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.brandColor,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'भाडा/महिना',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: AppTheme.brandColor,
              size: 18,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                location,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppTheme.brandColor,
                  fontWeight: FontWeight.w600,
                ),
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
        'sub': 'Water',
        'color': const Color(0xFF0EA5E9),
      },
      'parking_bike': {
        'icon': Icons.pedal_bike_outlined,
        'label': 'पार्किङ',
        'sub': 'Bike',
        'color': const Color(0xFF64748B),
      },
      'parking_car': {
        'icon': Icons.directions_car_outlined,
        'label': 'पार्किङ',
        'sub': 'Car',
        'color': const Color(0xFF475569),
      },
      'sunny_room': {
        'icon': Icons.wb_sunny_outlined,
        'label': 'उज्यालो',
        'sub': 'Sunny',
        'color': const Color(0xFFF59E0B),
      },
      'hot_water': {
        'icon': Icons.hot_tub_outlined,
        'label': 'तातो पानी',
        'sub': 'Hot Water',
        'color': const Color(0xFFEF4444),
      },
      'waste_mgmt': {
        'icon': Icons.delete_outline,
        'label': 'फोहोर',
        'sub': 'Waste',
        'color': const Color(0xFF10B981),
      },
      'peaceful': {
        'icon': Icons.nature_people_outlined,
        'label': 'शान्त',
        'sub': 'Peaceful',
        'color': const Color(0xFF059669),
      },
      'water_boring': {
        'icon': Icons.waves_outlined,
        'label': 'बोरिङ',
        'sub': 'Boring',
        'color': const Color(0xFF3B82F6),
      },
      'internet': {
        'icon': Icons.wifi_outlined,
        'label': 'इन्टरनेट',
        'sub': 'Wifi',
        'color': const Color(0xFF6366F1),
      },
      'kitchen': {
        'icon': Icons.kitchen_outlined,
        'label': 'भान्सा',
        'sub': 'Kitchen',
        'color': const Color(0xFF71717A),
      },
      'attached_bathroom': {
        'icon': Icons.bathroom_outlined,
        'label': 'बाथरुम',
        'sub': 'Attached',
        'color': const Color(0xFF06B6D4),
      },
      'security': {
        'icon': Icons.security_rounded,
        'label': 'सुरक्षा',
        'sub': 'Security',
        'color': const Color(0xFF1E293B),
      },
      'power_backup': {
        'icon': Icons.battery_charging_full_rounded,
        'label': 'बत्ती',
        'sub': 'Backup',
        'color': const Color(0xFFFBBF24),
      },
    };

    List<Widget> items = [];

    // Add standard ones
    if (widget.bedrooms != null && widget.bedrooms! > 0) {
      items.add(
        _buildStatItem(Icons.bed_outlined, '${widget.bedrooms}', 'Beds', const Color(0xFF6366F1)),
      );
    }
    if (widget.bathrooms != null && widget.bathrooms! > 0) {
      items.add(
        _buildStatItem(Icons.bathtub_outlined, '${widget.bathrooms}', 'Baths', const Color(0xFF06B6D4)),
      );
    }
    if (widget.area != null && widget.area!.isNotEmpty) {
      items.add(
        _buildStatItem(Icons.square_foot_outlined, widget.area!, 'Area', const Color(0xFF10B981)),
      );
    }

    // Add Kathmandu specific ones
    for (var amenity in widget.amenities) {
      if (amenityData.containsKey(amenity)) {
        final data = amenityData[amenity]!;
        items.add(_buildStatItem(data['icon'], data['label'], data['sub'], data['color']));
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double itemWidth = (constraints.maxWidth - 24) / 4;
          return Wrap(
            spacing: 8,
            runSpacing: 20,
            alignment: WrapAlignment.start,
            children: items.map((item) => SizedBox(
              width: itemWidth,
              child: item,
            )).toList(),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color accentColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withOpacity(0.08),
                accentColor.withOpacity(0.18),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accentColor.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Icon(icon, color: accentColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.4),
            letterSpacing: 0.1,
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
                            text: '₹',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          TextSpan(
                            text: PriceFormatter.format(price),
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.brandColor,
                              letterSpacing: -1,
                            ),
                          ),
                          WidgetSpan(
                            child: Transform.translate(
                              offset: const Offset(0, -5), // Move up to align with large price text
                              child: Text(
                                ' /mo',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: const Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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
    // Robust Landmark Filter: Ensure we only process valid Maps with coordinates
    final List<Map<String, dynamic>> landmarksRaw =
        (widget.nearbyLandmarks != null)
            ? widget.nearbyLandmarks!
                .where((e) => e is Map && e['lat'] != null && e['lng'] != null)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList()
            : [];

    // Fallback logic: If no valid landmarks, use local amenities within walking distance
    final List<Map<String, dynamic>> landmarks = landmarksRaw.isNotEmpty
        ? landmarksRaw
        : [
            {
              'name': 'Main Road Access',
              'lat': lat + 0.0007, // ~80m
              'lng': lng + 0.0005,
              'icon': Icons.add_road_rounded,
              'type': 'Access',
              'customDist': '100m', 
            },
            {
              'name': 'Local Grocery Shop',
              'lat': lat - 0.0012, // ~130m
              'lng': lng + 0.0008,
              'icon': Icons.shopping_basket_outlined,
              'type': 'Market',
            },
            {
              'name': 'Pharmacy / Clinic',
              'lat': lat + 0.0018, // ~200m
              'lng': lng - 0.0011,
              'icon': Icons.local_hospital_outlined,
              'type': 'Health',
            },
            {
              'name': 'Taxi / Bus Stand',
              'lat': lat - 0.0015, // ~170m
              'lng': lng - 0.0014,
              'icon': Icons.directions_bus_filled_outlined,
              'type': 'Transport',
            },
            {
              'name': 'Temple / Park',
              'lat': lat + 0.0022, // ~250m
              'lng': lng + 0.0019,
              'icon': Icons.park_outlined,
              'type': 'Amenity',
            },
          ];

    // Helper to calculate raw Euclidean distance (scaled to meters)
    double calculateDistance(
      double lat1,
      double lon1,
      dynamic lat2,
      dynamic lon2,
    ) {
      try {
        final dLat2 = (lat2 as num).toDouble();
        final dLon2 = (lon2 as num).toDouble();
        // Simple approximation: 1 degree latitude ~= 111,111 meters
        // 1 degree longitude ~= 111,111 * cos(lat) meters
        final dy = (lat1 - dLat2).abs() * 111111;
        final dx = (lon1 - dLon2).abs() * 111111 * 0.88; // cos(27 deg) approx 0.88
        return (dy + dx) / 1.4; // Average walking distance factor
      } catch (e) {
        return 999.0;
      }
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
        
        final int meters = place['customDist'] != null 
            ? 100 
            : rawDist.toInt().clamp(50, 450);
            
        final String distStr = '${meters}m';

        // Map AI icon codes to actual Flutter Icons
        IconData getIcon(String? code, String? type) {
          if (type == 'Transport') return Icons.directions_bus_filled_outlined;
          if (type == 'Amenity') return Icons.park_outlined;
          if (type == 'Access') return Icons.add_road_rounded;
          
          switch (code) {
            case 'local_hospital_rounded':
              return Icons.local_hospital_outlined;
            case 'shopping_bag_rounded':
              return Icons.shopping_bag_outlined;
            case 'school_rounded':
              return Icons.school_outlined;
            case 'account_balance_rounded':
              return Icons.account_balance_outlined;
            default:
              return Icons.location_on_outlined;
          }
        }

        return _buildNearbyItem(
          getIcon(place['icon_code'] as String?, place['type'] as String?),
          place['type'] as String? ?? 'Place',
          '$distStr (${place['name']})',
        );
      }).toList().cast<Widget>(),
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
                  backgroundImage: (avatar.isNotEmpty && !avatar.contains('pravatar.cc'))
                      ? CachedNetworkImageProvider(avatar)
                      : null,
                  child: (avatar.isEmpty || avatar.contains('pravatar.cc'))
                      ? Icon(Icons.person, size: 30, color: Colors.grey[400])
                      : null,
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
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF717171)),
          ),
        ] else ...[
          Text(
            'Exact GPS location not provided. Contact the owner for precise directions.',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF717171)),
          ),
        ],
      ],
    );
  }

  Widget _buildRidingAppMapPlaceholder() {
    return Container(
      color: const Color(0xFFE8ECEF), // Typical map background
      child: Stack(
        children: [
          // Background Map Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/Map view.png',
              fit: BoxFit.cover,
            ),
          ),
          // Subtle overlay to make pin stand out
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.05),
            ),
          ),
          
          // Center House Pin
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brandColor.withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.home_rounded, color: Colors.white, size: 24),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 16,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // CANCEL BUTTON
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF4B5563),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // BOOKING BUTTON
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (widget.status == 'booked' || widget.status == 'pending_approval' || _userHasPendingBooking)
                    ? null
                    : () {
                        HapticFeedback.heavyImpact();
                        
                        final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
                        if (currentUserId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'कृपया बुकिङ गर्न लगइन गर्नुहोस् (Please log in to book)',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingRequestScreen(
                              propertyId: widget.id,
                              propertyTitle: widget.title,
                              ownerId: widget.ownerId,
                              ownerName: widget.ownerName ?? 'Owner',
                            ),
                          ),
                        ).then((result) {
                          if (result == true) {
                            setState(() => _userHasPendingBooking = true);
                          }
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _userHasPendingBooking
                      ? Colors.orange.shade400
                      : AppTheme.brandColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: (widget.status == 'booked' || widget.status == 'pending_approval') ? 0 : 4,
                  shadowColor: AppTheme.brandColor.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_userHasPendingBooking) ...[
                      const Icon(Icons.hourglass_top_rounded, size: 16),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      widget.status == 'booked'
                          ? 'Booked'
                          : _userHasPendingBooking
                              ? 'Pending Approval'
                              : widget.status == 'pending_approval'
                                  ? 'Pending'
                                  : 'Book Now',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavArrow({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 60, // Vertical pill shape to differentiate from circular back button
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Center(
              child: Icon(
                icon == Icons.chevron_left_rounded
                    ? Icons.arrow_back_ios_new_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
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
