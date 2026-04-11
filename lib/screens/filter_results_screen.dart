import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/favourite_button.dart';
import '../widgets/voice_search_overlay.dart';
import 'property_details_screen.dart';
import 'chat_screen.dart';
import 'search_screen.dart';

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
  final TextEditingController _searchController = TextEditingController();

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
    const genericTitles = ['Verified Listings', 'Recently Added', 'Near You',
      'Popular in Kathmandu', 'Budget Friendly', 'High-End Apartments',
      'Hot Deals', 'Student Housing', 'Family Flats', 'Premium Collections',
      'Top Rated Properties'];
    final isLocationSearch = !genericTitles.contains(widget.location);

    var query = Supabase.instance.client
        .from('properties')
        .select('*, property_images(image_url)');

    // Filter by location if it's a real location
    if (isLocationSearch) {
      query = query.ilike('area_name', '%${widget.location}%') as dynamic;
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
    Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(widget.location, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  Text(widget.priceRange, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
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
                      padding: const EdgeInsets.fromLTRB(8, 0, 4, 0), // Smaller left padding for back button
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade200, width: 1.2),
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
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      itemCount: 10,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildSkeletonCard(context),
                      ),
                    );
                  }

                  final properties = snapshot.data ?? [];

                  if (properties.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.home_work_outlined, size: 80, color: Colors.grey[200]),
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
                          Text(
                            'Be the first to post a property!',
                            style: GoogleFonts.inter(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: properties.length,
                    itemBuilder: (context, index) {
                      final p = properties[index];
                      final images = (p['property_images'] as List);
                      final String mainImage = images.isNotEmpty 
                          ? images[0]['image_url'] 
                          : 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildWideCard(
                          context,
                          p['id'],
                          mainImage,
                          p['title'],
                          p['area_name'],
                          'रू ${p['price']}',
                          p['bedrooms'] ?? 0,
                          p['bathrooms'] ?? 0,
                          p['sq_ft'] ?? '0',
                          p['floor'] ?? 'N/A',
                          p['description'] ?? '',
                          images.map((i) => i['image_url'].toString()).toList(),
                          p['owner_id'] ?? '',
                          List<String>.from(p['amenities'] ?? []),
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
  }

  Widget _buildSkeletonCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF2F2F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 190,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 140, height: 16, decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4))),
                    Container(width: 80, height: 16, decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4))),
                  ],
                ),
                const SizedBox(height: 12),
                Container(width: 100, height: 10, decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideCard(
    BuildContext context, 
    String id, 
    String imageUrl, 
    String title, 
    String location, 
    String price, 
    int bedrooms, 
    int bathrooms, 
    String area, 
    String floor, 
    String description,
    List<String> images,
    String ownerId,
    List<String> amenities,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PropertyDetailsScreen(
            id: id,
            imageUrl: imageUrl,
            images: images,
            title: title,
            location: location,
            price: price,
            bedrooms: bedrooms,
            bathrooms: bathrooms,
            area: area,
            floor: floor,
            description: description,
            ownerId: ownerId,
            amenities: amenities,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF2F2F2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Image.network(imageUrl, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
                      decoration: BoxDecoration(color: const Color(0xFF2ECC71), borderRadius: BorderRadius.circular(20)),
                      child: Text('For Rent', style: GoogleFonts.inter(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Positioned(
                    top: 12, right: 12,
                    child: FavouriteButton(propertyId: id),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600))),
                        Text(price, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.brandColor)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, color: AppTheme.brandColor, size: 14),
                        const SizedBox(width: 4),
                        Text(location, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PropertyDetailsScreen(
                                  id: id,
                                  imageUrl: imageUrl,
                                  images: images,
                                  title: title,
                                  location: location,
                                  price: price,
                                  bedrooms: bedrooms,
                                  bathrooms: bathrooms,
                                  area: area,
                                  floor: floor,
                                  description: description,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.directions_walk, size: 17),
                            label: Text('Visit Now', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brandColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    ownerId: ownerId,
                                    name: 'Property Owner',
                                    avatar: 'https://i.pravatar.cc/150?img=1',
                                    online: true,
                                  ),
                                ),
                              );
                            },
                            icon: SvgPicture.asset('assets/icons/message.svg', width: 17, height: 17, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                            label: Text('Message', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brandColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
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
}
