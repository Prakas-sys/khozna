import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/property/screens/search_screen.dart';
import 'package:khozna/widgets/property_card.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/widgets/skeleton_card.dart';
import 'package:khozna/features/property/screens/discovery_map_screen.dart';

class FilterResultsScreen extends StatefulWidget {
  final String location;
  final String priceRange;
  final String? category;
  final int? minPrice;
  final int? maxPrice;
  final String? bedrooms;
  final List<String>? amenities;
  final bool? isStudentFriendly;
  final bool? isFamilyFriendly;

  const FilterResultsScreen({
    super.key,
    this.location = 'Verified Listings',
    this.priceRange = 'Top Rated Properties',
    this.category,
    this.minPrice,
    this.maxPrice,
    this.bedrooms,
    this.amenities,
    this.isStudentFriendly,
    this.isFamilyFriendly,
  });

  @override
  State<FilterResultsScreen> createState() => _FilterResultsScreenState();
}

class _FilterResultsScreenState extends State<FilterResultsScreen> {
  late Future<List<Map<String, dynamic>>> _propertiesFuture;

  @override
  void initState() {
    super.initState();
    _propertiesFuture = _fetchProperties();
  }

  Future<List<Map<String, dynamic>>> _fetchProperties() async {
    final rawSearchText = widget.location.trim();

    // Auto-detect price inside search text (e.g. "under 15000" or "below 20k")
    int? extractedPrice;
    final priceMatch = RegExp(
      r'(?:under|below|max|budget|within|upto|up to)?\s*₹?\s*(\d+)(k)?',
      caseSensitive: false,
    ).firstMatch(rawSearchText);
    if (priceMatch != null) {
      final numStr = priceMatch.group(1);
      final isK = priceMatch.group(2) != null;
      if (numStr != null) {
        final parsed = int.tryParse(numStr);
        if (parsed != null) {
          extractedPrice = isK ? parsed * 1000 : parsed;
        }
      }
    }

    final priceStr = widget.priceRange.replaceAll(RegExp(r'[^0-9]'), '');
    final parsedMaxPrice = widget.maxPrice ?? int.tryParse(priceStr) ?? extractedPrice;

    const genericTitles = [
      'Verified Listings',
      'Recently Added',
      'Near You',
      'Popular in Kathmandu',
      'Budget Friendly',
      'High-End Apartments',
      'Hot Deals',
      'Special Deals',
      'Student Housing',
      'Student Specials',
      'Family Flats',
      'Family Friendly',
      'Premium Collections',
      'Premium Selection',
      'Top Rated Properties',
    ];
    final isLocationSearch = !genericTitles.contains(rawSearchText);

    Position? position;
    if (rawSearchText == 'Near You') {
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          position = await Geolocator.getLastKnownPosition();
          if (position == null) {
            position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.low,
              ),
            ).timeout(const Duration(seconds: 2));
          }
        }
      } catch (e) {
        debugPrint('Error getting location in filters: $e');
      }
    }

    var query = Supabase.instance.client
        .from('properties')
        .select(
          '*, property_images(image_url), profiles:owner_id(full_name, avatar_url, kyc_status)',
        )
        .eq('status', 'available');

    // Intelligent Multi-Column Google-like Search
    if (isLocationSearch && rawSearchText.isNotEmpty) {
      final stopWords = {
        'a', 'an', 'the', 'in', 'on', 'at', 'for', 'to', 'of', 'and', 'or',
        'is', 'are', 'was', 'were', 'be', 'been', 'with', 'by', 'from', 'about',
        'finding', 'find', 'looking', 'look', 'search', 'searching', 'need',
        'want', 'wants', 'like', 'would', 'some', 'any', 'my', 'me', 'i', 'we',
        'you', 'our', 'place', 'places', 'rent', 'rental', 'available', 'near', 'nearby'
      };

      final allWords = rawSearchText
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), ' ')
          .split(RegExp(r'\s+'))
          .where((w) => w.trim().isNotEmpty)
          .toList();

      final filteredKeywords = allWords.where((w) => !stopWords.contains(w) && w.length > 1).toList();
      final keywords = filteredKeywords.isNotEmpty ? filteredKeywords : allWords.where((w) => w.length > 1).toList();

      if (keywords.isNotEmpty) {
        final conditions = <String>[];
        for (final kw in keywords) {
          final pattern = '%$kw%';
          conditions.add('area_name.ilike.$pattern');
          conditions.add('title.ilike.$pattern');
          conditions.add('description.ilike.$pattern');
          conditions.add('category.ilike.$pattern');
          conditions.add('address.ilike.$pattern');
        }
        query = query.or(conditions.join(',')) as dynamic;
      } else {
        final pattern = '%${rawSearchText.replaceAll(RegExp(r'\s+'), '%')}%';
        query = query.or(
          'area_name.ilike.$pattern,title.ilike.$pattern,description.ilike.$pattern,category.ilike.$pattern,address.ilike.$pattern',
        ) as dynamic;
      }
    } else {
      if (rawSearchText == 'Near You' && position != null) {
        final lat = position.latitude;
        final lng = position.longitude;
        query = query
            .gte('latitude', lat - 0.1)
            .lte('latitude', lat + 0.1)
            .gte('longitude', lng - 0.1)
            .lte('longitude', lng + 0.1) as dynamic;
      } else if (rawSearchText == 'Special Deals' || rawSearchText == 'Hot Deals') {
        query = query.or(
          'description.ilike."%offer%",description.ilike."%discount%",title.ilike."%offer%",is_negotiable.eq.true',
        ) as dynamic;
      } else if (rawSearchText == 'Student Specials' || rawSearchText == 'Student Housing') {
        query = query.eq('is_student_friendly', true).lt('price', 9000) as dynamic;
      } else if (rawSearchText == 'Family Friendly' || rawSearchText == 'Family Flats') {
        query = query.eq('category', 'Flat') as dynamic;
      } else if (rawSearchText == 'Premium Selection' || rawSearchText == 'Premium Collections') {
        query = query.or('is_premium.eq.true,price.gt.20000') as dynamic;
      }
    }

    // Category Filter
    if (widget.category != null &&
        widget.category!.isNotEmpty &&
        widget.category != 'All' &&
        widget.category != 'Homes') {
      query = query.eq('category', widget.category!) as dynamic;
    }

    // Price Filters
    if (widget.minPrice != null && widget.minPrice! > 0) {
      query = query.gte('price', widget.minPrice!) as dynamic;
    }
    if (parsedMaxPrice != null && parsedMaxPrice > 0) {
      query = query.lte('price', parsedMaxPrice) as dynamic;
    }

    // Bedroom Filter
    if (widget.bedrooms != null && widget.bedrooms != 'Any') {
      final bhkNum = int.tryParse(widget.bedrooms!.replaceAll(RegExp(r'[^0-9]'), ''));
      if (bhkNum != null) {
        query = query.gte('bedrooms', bhkNum) as dynamic;
      }
    }

    // Preference Filters
    if (widget.isStudentFriendly == true) {
      query = query.eq('is_student_friendly', true) as dynamic;
    }

    try {
      final result = await (query as dynamic)
          .order('is_boosted', ascending: false)
          .order('created_at', ascending: false);
      final list = List<Map<String, dynamic>>.from(result);

      // Smart Fallback: If 0 results found for a location/sentence search, fetch top recommended properties!
      if (list.isEmpty && isLocationSearch) {
        debugPrint('Smart Search Fallback: 0 results for "$rawSearchText", fetching top recommended properties...');
        final fallbackResult = await Supabase.instance.client
            .from('properties')
            .select('*, property_images(image_url), profiles:owner_id(full_name, avatar_url, kyc_status)')
            .eq('status', 'available')
            .order('is_boosted', ascending: false)
            .order('created_at', ascending: false)
            .limit(10);
        return List<Map<String, dynamic>>.from(fallbackResult);
      }

      return list;
    } catch (e) {
      debugPrint('Error fetching properties: $e');
      try {
        final fallback = await Supabase.instance.client
            .from('properties')
            .select('*, property_images(image_url), profiles:owner_id(full_name, avatar_url, kyc_status)')
            .eq('status', 'available')
            .limit(10);
        return List<Map<String, dynamic>>.from(fallback);
      } catch (_) {
        return [];
      }
    }
  }

  void _navigate(BuildContext context, Widget destination) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Ultra Pro Header ──────────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                        onPressed: () => Navigator.pop(context),
                        splashRadius: 22,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              widget.location,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            // Active Filter Badges
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (widget.maxPrice != null || widget.minPrice != null)
                                    _buildFilterBadge(
                                      icon: 'assets/icons/vector of ruppes.svg',
                                      label: widget.minPrice != null && widget.maxPrice != null
                                          ? '${widget.minPrice} - ${widget.maxPrice}'
                                          : 'Up to ₹${widget.maxPrice ?? widget.minPrice}',
                                      isAccent: true,
                                    ),
                                  if (widget.category != null &&
                                      widget.category!.isNotEmpty &&
                                      widget.category != 'All') ...[
                                    const SizedBox(width: 6),
                                    _buildFilterBadge(label: widget.category!),
                                  ],
                                  if (widget.bedrooms != null && widget.bedrooms != 'Any') ...[
                                    const SizedBox(width: 6),
                                    _buildFilterBadge(label: '${widget.bedrooms} BHK'),
                                  ],
                                  if (widget.isStudentFriendly == true) ...[
                                    const SizedBox(width: 6),
                                    _buildFilterBadge(label: 'Student Friendly'),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                // ── Search Bar ──────────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Hero(
                    tag: 'search_bar',
                    child: Material(
                      color: Colors.transparent,
                      child: GestureDetector(
                        onTap: () => _navigate(context, const SearchScreen()),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade200, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 14),
                              Icon(CupertinoIcons.search, color: AppTheme.brandColor, size: 19),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Search area, city or title...',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.grey[500],
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.tune_rounded, size: 13, color: Colors.white),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Filter',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Results Content List ────────────────────────────────────
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _propertiesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          itemCount: 5,
                          itemBuilder: (context, index) => const Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: SkeletonCard(isFullWidth: true),
                          ),
                        );
                      }

                      final properties = snapshot.data ?? [];

                      if (properties.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 36),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppTheme.brandColor.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.search_off_rounded,
                                    size: 52,
                                    color: AppTheme.brandColor,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'No properties found',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your price range, property type, or search area to find available matches.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    color: Colors.grey[600],
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.brandColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    'Modify Filters',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                        itemCount: properties.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${properties.length} ${properties.length == 1 ? 'property' : 'properties'} available',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.verified_rounded, size: 14, color: AppTheme.brandColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Khozna Verified',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.brandColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }

                          final pMap = properties[index - 1];
                          final property = Property.fromMap(pMap);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: PropertyCard(
                              property: property,
                              width: double.infinity,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            // ── AIRBNB FLOATING BLACK MAP PILL (Bottom-Center) ──────────────
            Positioned(
              bottom: 24,
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
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.82), // 80% Black Fill
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Map',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.map_outlined,
                          color: Colors.white,
                          size: 20,
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
    );
  }

  Widget _buildFilterBadge({
    String? icon,
    required String label,
    bool isAccent = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAccent ? AppTheme.brandColor.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAccent ? AppTheme.brandColor.withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            SvgPicture.asset(
              icon,
              width: 10,
              height: 10,
              colorFilter: ColorFilter.mode(
                isAccent ? AppTheme.brandColor : Colors.black87,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isAccent ? AppTheme.brandColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
