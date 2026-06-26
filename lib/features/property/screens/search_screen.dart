import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/services/khozna_ai_service.dart';
import 'package:khozna/features/property/screens/filter_results_screen.dart';
import 'package:khozna/features/chat/screens/ai_chat_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/widgets/property_card.dart';
import 'package:khozna/features/property/screens/discovery_map_screen.dart';
import 'package:khozna/core/guards/auth_guard.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  double _priceValue = 15000;
  final List<String> _recentSearches = [
    'Baluwatar',
    '2BHK Sanepa',
    'Flat under 20k',
    'Baneshwor Room',
  ];
  late TextEditingController _searchController;

  // AI Search State
  final KhoznaAiService _aiService = KhoznaAiService();
  bool _isAiSearching = false;
  String? _aiSearchResult;
  List<Map<String, dynamic>>? _aiFoundProperties;

  // Search Flow State
  bool _showNearbySection = false;
  String _activeCategory = 'Homes';

  // Nearby State
  List<Property> _nearbyProperties = [];
  bool _isLoadingNearby = true;
  LatLng? _userLocation;
  final MapController _miniMapController = MapController();
  final ScrollController _scrollController = ScrollController();
  bool _showMapPill = false;
  late AnimationController _aiPulseController;
  late Animation<double> _aiScaleAnimation;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Auto-fill from voice search or constructor
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FilterResultsScreen(
                location: widget.initialQuery!,
                priceRange: 'Up to ₹ ${_priceValue.toInt()}',
              ),
            ),
          );
        }
      });
    }

    _loadNearbyData();

    _scrollController.addListener(() {
      final shouldShow = _scrollController.offset > 100;
      if (shouldShow != _showMapPill) {
        setState(() => _showMapPill = shouldShow);
      }
    });

    _aiPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _aiScaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _aiPulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _loadNearbyData() async {
    LatLng? currentLoc;
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      currentLoc = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _userLocation = currentLoc;
        });
        _miniMapController.move(currentLoc!, 13.0);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }

    final properties = await SupabaseService.getAllProperties();
    
    // 📍 FILTER & SORT BY DISTANCE
    if (currentLoc != null) {
      const Distance distance = Distance();
      properties.sort((a, b) {
        if (a.latitude == null || a.longitude == null) return 1;
        if (b.latitude == null || b.longitude == null) return -1;
        
        final dA = distance.as(LengthUnit.Meter, currentLoc!, LatLng(a.latitude!, a.longitude!));
        final dB = distance.as(LengthUnit.Meter, currentLoc!, LatLng(b.latitude!, b.longitude!));
        return dA.compareTo(dB);
      });
    }

    if (mounted) {
      setState(() {
        // Take the closest 10 properties
        _nearbyProperties = properties.take(10).toList();
        _isLoadingNearby = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _aiPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_showNearbySection) ...[
                      // 1. BRANDED HEADER
                      Text(
                        'Find your next home',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Search across thousands of properties',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 2. SEARCH BAR
                      Hero(
                        tag: 'search_bar_container',
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/Search vector.svg',
                                  width: 24,
                                  height: 24,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.black,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Location, Area or City',
                                        hintStyle: GoogleFonts.plusJakartaSans(
                                          color: Colors.grey[400],
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                      ),
                                      onSubmitted: (val) {
                                        if (val.isNotEmpty) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FilterResultsScreen(
                                                    location: val,
                                                    priceRange:
                                                        'Up to ₹ ${_priceValue.toInt()}',
                                                  ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  // --- AIRBNB STYLE FILTER ICON ---
                                  Container(
                                    height: 32,
                                    width: 1.5,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    color: Colors.grey.withOpacity(0.12),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      _showFilterOptions(context);
                                    },
                                    icon: const Icon(
                                      Icons.tune_rounded, // 2-3 Layer premium filter icon
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      _buildSuggestedItem(
                        'Find Nearby',
                        'Show properties around your current location',
                        Icons.near_me_rounded,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _showNearbySection = true);
                        },
                      ),
                      
                      const SizedBox(height: 24),

                      Text(
                        'Popular Areas',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...['Lalitpur', 'Bhaktapur', 'Basundhara'].map((area) =>
                        _buildSuggestedItem(
                          area,
                          'Browse properties in $area',
                          Icons.location_on_rounded,
                          onTap: () {
                            _searchController.text = area;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FilterResultsScreen(
                                  location: area,
                                  priceRange: 'Up to ₹ ${_priceValue.toInt()}',
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 32),
                      // Khozna Branded Search Button
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_searchController.text.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilterResultsScreen(
                                    location: _searchController.text,
                                    priceRange:
                                        '₹ ${_priceValue.toInt()}',
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Search Properties',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 140,
                      ), // Increased to prevent collision with FAB and AI Pill
                    ],

                    // 5. NEARBY SECTION (REVEALED ON TAP)
                    if (_showNearbySection) ...[
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Prominent Nearby Header & Map Button
                          // Header with back arrow + title
                          Transform.translate(
                            offset: const Offset(-8, 0),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() => _showNearbySection = false);
                                  },
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nearby Properties',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.8,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'Find homes near you',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Mini Map Preview
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.grey.shade100,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Stack(
                                children: [
                                  FlutterMap(
                                    mapController: _miniMapController,
                                    options: MapOptions(
                                      initialCenter:
                                          _userLocation ??
                                          const LatLng(27.7172, 85.3240),
                                      initialZoom: 12.5,
                                      interactionOptions:
                                          const InteractionOptions(
                                            flags: InteractiveFlag.all,
                                          ),
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=xmsI10GyMKz5IT0XAIhv',
                                        userAgentPackageName:
                                            'com.khozna.khozna',
                                      ),
                                      if (_userLocation != null)
                                        MarkerLayer(
                                          markers: [
                                            if (_userLocation != null)
                                              Marker(
                                                point: _userLocation!,
                                                width: 40,
                                                height: 40,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.brandColor,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 3,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: AppTheme
                                                            .brandColor
                                                            .withOpacity(0.4),
                                                        blurRadius: 8,
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Icons.my_location,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            // Airbnb-style Price Markers
                                            ..._nearbyProperties.map((p) {
                                              if (p.latitude == null ||
                                                  p.longitude == null) {
                                                return Marker(
                                                  point: const LatLng(0, 0),
                                                  child: const SizedBox(),
                                                );
                                              }
                                              return Marker(
                                                point: LatLng(
                                                  p.latitude!,
                                                  p.longitude!,
                                                ),
                                                width: 50,
                                                height: 30,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        blurRadius: 6,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ],
                                                    border: Border.all(
                                                      color:
                                                          Colors.grey.shade200,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: RichText(
                                                      text: TextSpan(
                                                        children: [
                                                          WidgetSpan(
                                                            alignment: PlaceholderAlignment.middle,
                                                            child: Transform.translate(
                                                                offset: const Offset(0, 0.0),
                                                              child: SvgPicture.asset(
                                                                'assets/icons/vector of ruppes.svg',
                                                                width: 9,
                                                                height: 9,
                                                                colorFilter: const ColorFilter.mode(
                                                                  Colors.black,
                                                                  BlendMode.srcIn,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const WidgetSpan(child: SizedBox(width: 2)),
                                                          TextSpan(
                                                            text: '${(p.priceNight > 0 ? p.priceNight : (double.tryParse(p.price) ?? 0)) > 999 ? '${((p.priceNight > 0 ? p.priceNight : (double.tryParse(p.price) ?? 0)) / 1000).toStringAsFixed(0)}K' : (p.priceNight > 0 ? p.priceNight.toInt().toString() : (double.tryParse(p.price)?.toInt().toString() ?? p.price))}',
                                                            style: GoogleFonts.plusJakartaSans(
                                                              color: Colors.black,
                                                              fontWeight: FontWeight.w800,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                    ],
                                  ),
                                  // View Full Map Floating Button
                                  Positioned(
                                    bottom: 12,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const DiscoveryMapScreen(),
                                        ),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.1),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.fullscreen_rounded,
                                              size: 16,
                                              color: Colors.black87,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Full Map',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black87,
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
                          ),
                          const SizedBox(height: 16),
                          // Vertical Property Scroll
                          _isLoadingNearby
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: CircularProgressIndicator(
                                      color: AppTheme.brandColor,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _nearbyProperties.length,
                                  itemBuilder: (context, index) {
                                    final p = _nearbyProperties[index];
                                    String distanceLabel = '';
                                    if (_userLocation != null && p.latitude != null && p.longitude != null) {
                                      const Distance distance = Distance();
                                      double meters = distance.as(LengthUnit.Meter, _userLocation!, LatLng(p.latitude!, p.longitude!));
                                      if (meters < 1000) {
                                        distanceLabel = '${meters.toInt()}m away';
                                      } else {
                                        distanceLabel = '${(meters / 1000).toStringAsFixed(1)}km away';
                                      }
                                    }
                                    
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 24,
                                      ),
                                      child: Stack(
                                        children: [
                                          PropertyCard(property: p),
                                          if (distanceLabel.isNotEmpty)
                                            Positioned(
                                              top: 12,
                                              right: 12,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.7),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.near_me_rounded, color: Colors.white, size: 12),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      distanceLabel,
                                                      style: GoogleFonts.inter(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                          const SizedBox(
                            height: 80,
                          ), // Prevent collision with FAB
                        ],
                      ),
                    ],

                    if (!_showNearbySection) ...[
                      const SizedBox(height: 80), // Prevent collision with FAB
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Floating Map Pill (Airbnb-style) - only in Nearby section
          if (_showNearbySection && _nearbyProperties.isNotEmpty && _showMapPill)
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DiscoveryMapScreen(
                          initialCenter: _userLocation,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Map',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.map_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Floating AI Button - only in Main Search section
          if (!_showNearbySection)
            Positioned(
              bottom: 32,
              right: 24,
              child: ScaleTransition(
                scale: _aiScaleAnimation,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AiChatScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.brandColor, AppTheme.brandColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'AI',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaItem(String title, String count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.brandColor.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: AppTheme.brandColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          count,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Colors.grey.shade400,
        ),
        onTap: () {
          setState(() => _searchController.text = title.split(',')[0]);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FilterResultsScreen(
                location: title.split(',')[0],
                priceRange: '₹ ${_priceValue.toInt()}',
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _runAiSearch() async {
    if (_searchController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please type what you are looking for first!'),
        ),
      );
      return;
    }

    setState(() {
      _isAiSearching = true;
      _aiSearchResult = null;
    });

    try {
      // 1. Fetch properties for context
      // We try to find properties that match the user's search query keywords
      final queryText = _searchController.text.trim();
      final supabase = Supabase.instance.client;

      var query = supabase
          .from('properties')
          .select('id, title, price, area_name, category')
          .eq('status', 'available');

      // Simple keyword matching for better context
      if (queryText.isNotEmpty) {
        query = query.or(
          'area_name.ilike.%$queryText%,title.ilike.%$queryText%,category.ilike.%$queryText%',
        );
      }

      final List<dynamic> propertiesData = await query.limit(20);

      final List<Map<String, dynamic>> properties = propertiesData
          .cast<Map<String, dynamic>>();

      // 2. Call AI Service
      final result = await _aiService.matchProperty(
        _searchController.text,
        properties,
      );

      setState(() {
        _aiSearchResult = result;
        _aiFoundProperties = properties;
        _isAiSearching = false;
      });
    } catch (e) {
      setState(() => _isAiSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI Search failed: $e')));
      }
    }
  }

  Widget _buildCategoryIcon(String label, IconData icon) {
    bool isActive = _activeCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _activeCategory = label),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? Colors.transparent : Colors.transparent,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.grey[400],
              size: 28,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              color: isActive ? Colors.black : Colors.grey[400],
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 20,
              color: Colors.black,
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestedItem(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.brandColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setModalState(() {
                          _priceValue = 15000;
                          _activeCategory = 'Room';
                        }),
                        child: Text(
                          'Reset',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      Text(
                        'Price Range',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Up to ',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.brandColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                          SvgPicture.asset(
                            'assets/icons/vector of ruppes.svg',
                            width: 14,
                            height: 14,
                            colorFilter: const ColorFilter.mode(
                              AppTheme.brandColor,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_priceValue.toInt()}',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.brandColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.brandColor,
                          inactiveTrackColor: AppTheme.brandColor.withOpacity(0.12),
                          thumbColor: Colors.white,
                          overlayColor: AppTheme.brandColor.withOpacity(0.1),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12, elevation: 4),
                        ),
                        child: Slider(
                          value: _priceValue,
                          min: 1000,
                          max: 100000,
                          divisions: 99,
                          onChanged: (val) {
                            setModalState(() => _priceValue = val);
                            setState(() {}); // Sync with parent state
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Location',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: ['Kathmandu', 'Lalitpur', 'Bhaktapur', 'Pokhara'].map((loc) {
                          bool isSelected = _searchController.text == loc;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() => _searchController.text = loc);
                              setState(() => _searchController.text = loc);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.black : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.grey.shade200,
                                ),
                              ),
                              child: Text(
                                loc,
                                style: GoogleFonts.plusJakartaSans(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Property Type',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: ['Room', 'Flat', 'Cottage', 'Apartment', 'Office'].map((cat) {
                          bool isSelected = _activeCategory == cat;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() => _activeCategory = cat);
                              setState(() => _activeCategory = cat);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.black : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: GoogleFonts.plusJakartaSans(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FilterResultsScreen(
                              location: _searchController.text.isNotEmpty ? _searchController.text : _activeCategory,
                              category: _activeCategory,
                              priceRange: 'Up to ₹ ${_priceValue.toInt()}',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Show Results',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
