import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/services/khozna_ai_service.dart';
import 'package:khozna/features/property/screens/filter_results_screen.dart';
import 'package:khozna/features/chat/screens/ai_chat_screen.dart';
import 'package:khozna/core/utils/formatters.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/widgets/property_card.dart';
import 'package:khozna/features/property/screens/discovery_map_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Auto-fill from voice search or constructor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        setState(() {
          _searchController.text = widget.initialQuery!;
        });
        // Auto-trigger search
        Future.delayed(const Duration(milliseconds: 100), () {
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
        return;
      }
    });

    _loadNearbyData();

    _scrollController.addListener(() {
      final shouldShow = _scrollController.offset > 100;
      if (shouldShow != _showMapPill) {
        setState(() => _showMapPill = shouldShow);
      }
    });
  }

  Future<void> _loadNearbyData() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }

    final properties = await SupabaseService.getAllProperties();
    if (mounted) {
      setState(() {
        _nearbyProperties = properties.take(5).toList();
        _isLoadingNearby = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
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
                                const Icon(
                                  CupertinoIcons.search,
                                  color: Colors.black,
                                  size: 24,
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
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),



                      // 4. QUICK DISCOVERY
                      Text(
                        'Quick Discovery',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSuggestedItem(
                        'Find Nearby',
                        'Show properties around your current location',
                        Icons.near_me_rounded,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _showNearbySection = true);
                        },
                      ),
                      
                      const SizedBox(height: 8),
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
                      ...['Baluwatar', 'Sanepa', 'Lalitpur', 'Kirtipur', 'Baneshwor'].map((area) =>
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
                                        'Up to ₹ ${_priceValue.toInt()}',
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
                                            flags: InteractiveFlag.none,
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
                                                  p.longitude == null)
                                                return Marker(
                                                  point: const LatLng(0, 0),
                                                  child: const SizedBox(),
                                                );
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
                                                    child: Text(
                                                      '₹ ${(p.priceNight > 0 ? p.priceNight : (double.tryParse(p.price) ?? 0)) > 999 ? '${((p.priceNight > 0 ? p.priceNight : (double.tryParse(p.price) ?? 0)) / 1000).toStringAsFixed(0)}K' : (p.priceNight > 0 ? p.priceNight.toInt().toString() : (double.tryParse(p.price)?.toInt().toString() ?? p.price))}',
                                                      style:
                                                          GoogleFonts.plusJakartaSans(
                                                            color: Colors.black,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            fontSize: 11,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                        ),
                                    ],
                                  ),
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const DiscoveryMapScreen(),
                                        ),
                                      ),
                                      child: Container(
                                        color: Colors.transparent,
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
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 24,
                                      ),
                                      child: PropertyCard(property: p),
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
          if (_showNearbySection && _showMapPill)
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
                        builder: (_) => const DiscoveryMapScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.brandColor, AppTheme.brandColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brandColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 24,
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
                priceRange: 'रू ${_priceValue.toInt()}',
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
}
