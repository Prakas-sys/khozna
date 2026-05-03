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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              onSubmitted: (val) {
                                if (val.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FilterResultsScreen(
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

                // 3. POPULAR LOCATIONS (INITIAL STATE)
                if (!_showNearbySection) ...[
                  Text(
                    'Popular Locations',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSuggestedItem(
                    'Nearby Properties',
                    'Find what’s around you right now',
                    Icons.near_me_rounded,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _showNearbySection = true);
                    },
                  ),
                  _buildSuggestedItem(
                    'Baluwatar',
                    'Premium residential area',
                    Icons.location_city_rounded,
                    onTap: () => _searchController.text = 'Baluwatar',
                  ),
                  _buildSuggestedItem(
                    'Sanepa',
                    'Popular for flats and houses',
                    Icons.home_work_rounded,
                    onTap: () => _searchController.text = 'Sanepa',
                  ),
                  _buildSuggestedItem(
                    'Lalitpur',
                    'Historical and cultural hub',
                    Icons.museum_rounded,
                    onTap: () => _searchController.text = 'Lalitpur',
                  ),
                  _buildSuggestedItem(
                    'Pokhara',
                    'Lakefront and scenic views',
                    Icons.landscape_rounded,
                    onTap: () => _searchController.text = 'Pokhara',
                  ),

                  const SizedBox(height: 40),
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
                                priceRange: 'Up to ₹ ${_priceValue.toInt()}',
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppTheme.brandColor.withOpacity(0.4),
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
                ],

                // 5. NEARBY SECTION (REVEALED ON TAP)
                if (_showNearbySection) ...[
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Prominent Nearby Header & Map Button
                      InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DiscoveryMapScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
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
                              // ENLARGED PILL MAP BUTTON
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandColor,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.brandColor.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Map',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(
                                      Icons.map_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                                  initialZoom: 14.0,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.none,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=xmsI10GyMKz5IT0XAIhv',
                                    userAgentPackageName: 'com.khozna.khozna',
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
                                                    color: AppTheme.brandColor
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
                                            width: 100,
                                            height: 45,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.15),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                                border: Border.all(
                                                  color: Colors.grey.shade100,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '₹${(double.tryParse(p.price) ?? 0) > 999 ? '${((double.tryParse(p.price) ?? 0) / 1000).toStringAsFixed(0)}K' : (double.tryParse(p.price)?.toInt().toString() ?? p.price)}',
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontSize: 13,
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
                                  child: Container(color: Colors.transparent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Horizontal Property Scroll
                      SizedBox(
                        height: 300,
                        child: _isLoadingNearby
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.brandColor,
                                ),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _nearbyProperties.length,
                                clipBehavior: Clip.none,
                                itemBuilder: (context, index) {
                                  final p = _nearbyProperties[index];
                                  return Container(
                                    width: 280,
                                    margin: const EdgeInsets.only(right: 16),
                                    alignment: Alignment.topCenter,
                                    child: PropertyCard(property: p),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'PRICE RANGE (भाडाको सीमा)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.black38,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.grey.shade100,
                        width: 1.2,
                      ),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '₹',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '2K',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '₹',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '100K+',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppTheme.brandColor,
                            inactiveTrackColor: AppTheme.brandColor.withOpacity(
                              0.1,
                            ),
                            thumbColor: Colors.white,
                            overlayColor: AppTheme.brandColor.withOpacity(0.1),
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 10,
                              elevation: 4,
                            ),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _priceValue,
                            min: 2000,
                            max: 100000,
                            onChanged: (val) =>
                                setState(() => _priceValue = val),
                          ),
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '₹',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.brandColor,
                                ),
                              ),
                              TextSpan(
                                text:
                                    '${PriceFormatter.format(_priceValue.toInt().toString())} / month',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.brandColor,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'RECENTLY SEARCHED (भर्खरै खोजिएका)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.black38,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _recentSearches
                        .map(
                          (search) => InkWell(
                            onTap: () {
                              setState(() => _searchController.text = search);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilterResultsScreen(
                                    location: search,
                                    priceRange:
                                        'Up to ₹ ${_priceValue.toInt()}',
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: _buildRecentTag(search),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 40),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Popular Areas ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: '(लोकप्रिय ठाउँहरू)',
                          style: GoogleFonts.mukta(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAreaItem('Baluwatar, Kathmandu', '450+ Listings'),
                  _buildAreaItem('Sanepa, Lalitpur', '320+ Listings'),
                  _buildAreaItem('Baneshwor, Kathmandu', '580+ Listings'),
                  _buildAreaItem('Jhamsikhel, Lalitpur', '210+ Listings'),
                  _buildAreaItem('Kirtipur, Kathmandu', '120+ Listings'),
                  const SizedBox(height: 80), // Prevent collision with FAB
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FilterResultsScreen(
                    location: _searchController.text.isEmpty
                        ? 'Verified Listings'
                        : _searchController.text,
                    priceRange: 'Up to ₹ ${_priceValue.toInt()}',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Apply Filters & Search',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AiChatScreen()),
          );
        },
        backgroundColor: AppTheme.brandColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        icon: const Icon(Icons.support_agent, color: Colors.white),
        label: Text(
          'AI सहायक',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
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
                priceRange: 'Up to ₹ ${_priceValue.toInt()}',
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
