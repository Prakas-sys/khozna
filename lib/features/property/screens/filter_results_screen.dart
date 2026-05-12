import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
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

  const FilterResultsScreen({
    super.key,
    this.location = 'Verified Listings',
    this.priceRange = 'Top Rated Properties',
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
        );

    // Filter by location if it's a real location
    if (isLocationSearch) {
      final searchVal = widget.location.trim();
      query =
          query.or(
                'area_name.ilike.%$searchVal%,title.ilike.%$searchVal%,category.ilike.%$searchVal%',
              )
              as dynamic;
    }

    // Filter by price if a valid number was found
    if (priceInt != null && priceInt > 0) {
      query = query.lte('price', priceInt) as dynamic;
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
      backgroundColor: Colors.white,
      appBar: null,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Location Header (Moved from AppBar to body)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.black,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.location,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        widget.priceRange,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Unified Premium Search Bar (Matches Home Screen)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Hero(
                tag: 'search_bar',
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: () => _navigate(context, const SearchScreen()),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.fromLTRB(
                        8,
                        0,
                        4,
                        0,
                      ), // Smaller left padding for back button
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 15,
                            spreadRadius: 0,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Icon(
                            CupertinoIcons.search,
                            color: AppTheme.brandColor,
                            size: 26,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Search properties',
                              style: GoogleFonts.inter(
                                color: Colors.grey[400],
                                fontSize: 16,
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

            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _propertiesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      itemCount: 8,
                      itemBuilder: (context, index) => const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: SkeletonCard(isFullWidth: true),
                      ),
                    );
                  }

                  final properties = snapshot.data ?? [];
                  final priceStr = widget.priceRange.replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  );
                  final priceInt = int.tryParse(priceStr);

                  if (properties.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home_work_outlined,
                            size: 80,
                            color: Colors.grey[200],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No listings found yet',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              priceInt != null && priceInt > 0
                                  ? 'Try increasing your budget or changing the location to see more results.'
                                  : 'Be the first to post a property in this area!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: Colors.grey[500]),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    itemCount: properties.length,
                    itemBuilder: (context, index) {
                      final pMap = properties[index];
                      final property = Property.fromMap(pMap);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
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
      ),
    );
  }
}
