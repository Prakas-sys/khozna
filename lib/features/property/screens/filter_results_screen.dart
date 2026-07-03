import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/property/screens/search_screen.dart';
import 'package:khozna/widgets/property_card.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/widgets/skeleton_card.dart';

class FilterResultsScreen extends StatefulWidget {
  final String location;
  final String priceRange;
  final String? category;

  const FilterResultsScreen({
    super.key,
    this.location = 'Verified Listings',
    this.priceRange = 'Top Rated Properties',
    this.category,
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
    // Extract numeric price from string like "Up to Rs. 45000"
    final priceStr = widget.priceRange.replaceAll(RegExp(r'[^0-9]'), '');
    final priceInt = int.tryParse(priceStr);

    // Generic section titles that are NOT location filters
    const genericTitles = [
      'Verified Listings',
      'Recently Added',
      'Near You',
      'Popular in Kathmandu',
      'Budget Friendly',
      'High-End Apartments',
      'Hot Deals',
      'Student Housing',
      'Family Flats',
      'Premium Collections',
      'Top Rated Properties',
    ];
    final isLocationSearch = !genericTitles.contains(widget.location);

    var query = Supabase.instance.client
        .from('properties')
        .select(
          '*, property_images(image_url), profiles:owner_id(full_name, avatar_url, kyc_status)',
        )
        .eq('status', 'available');

    // Filter by location if it's a real location
    if (isLocationSearch) {
      final searchVal = widget.location.trim();
      query =
          query.or(
                'area_name.ilike.%$searchVal%,title.ilike.%$searchVal%,category.ilike.%$searchVal%',
              )
              as dynamic;
    }

    // Filter by category if specifically selected
    if (widget.category != null && widget.category!.isNotEmpty && widget.category != 'All') {
      query = query.eq('category', widget.category!) as dynamic;
    }

    // Filter by price if a valid number was found
    if (priceInt != null && priceInt > 0) {
      query = query.lte('price', priceInt) as dynamic;
    }
    
    // Fallback if price is listed in price_month
    if (priceInt != null && priceInt > 0) {
       // We can iterate results later or try an or filter if DB supports it
    }

    final result = await (query as dynamic)
        .order('is_boosted', ascending: false)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(result);
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Premium Header ──────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.location,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (widget.priceRange.isNotEmpty &&
                                widget.priceRange != 'Top Rated Properties') ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/vector of ruppes.svg',
                                      width: 9,
                                      height: 9,
                                      colorFilter: ColorFilter.mode(
                                        AppTheme.brandColor,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      widget.priceRange.replaceAll(RegExp(r'(रू|Rs\.|₹)'), '').trim(),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.brandColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (widget.category != null && widget.category!.isNotEmpty && widget.category != 'All') ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.category!,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Search Bar ──────────────────────────────────────────────
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
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFE8ECF0), width: 1),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Icon(CupertinoIcons.search, color: Colors.grey[400], size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Search properties...',
                              style: GoogleFonts.inter(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Results List ────────────────────────────────────────────
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _propertiesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      itemCount: 6,
                      itemBuilder: (context, index) => const Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: SkeletonCard(isFullWidth: true),
                      ),
                    );
                  }

                  final properties = snapshot.data ?? [];
                  final priceStr = widget.priceRange.replaceAll(RegExp(r'[^0-9]'), '');
                  final priceInt = int.tryParse(priceStr);

                  if (properties.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: AppTheme.brandColor.withOpacity(0.06),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.search_off_rounded,
                                size: 56,
                                color: AppTheme.brandColor.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No listings found',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              priceInt != null && priceInt > 0
                                  ? 'Try increasing your budget or changing the location.'
                                  : 'Be the first to list a property in this area!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                color: Colors.grey[500],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    itemCount: properties.length + 1,
                    itemBuilder: (context, index) {
                      // Result count row as first item
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${properties.length} result${properties.length == 1 ? '' : 's'}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.brandColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final pMap = properties[index - 1];
                      final property = Property.fromMap(pMap);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: PropertyCard(property: property, width: double.infinity),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
