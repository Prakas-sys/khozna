import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../utils/app_notifiers.dart';
import '../utils/supabase_service.dart';
import 'property_details_screen.dart';
import 'search_screen.dart';
import 'filter_results_screen.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        titleSpacing: 20,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/original logo.png',
            height: 40,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: notificationBadgeCount,
            builder: (context, badgeCount, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87, size: 26),
                        onPressed: () {
                          notificationBadgeCount.value = 0;
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                          );
                        },
                      ),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF3B30).withValues(alpha: 0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
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
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 100.0),
          child: Column(
            children: [
              const SizedBox(height: 24), // Reduced from 48
              Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Find your Next Home',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No Middleman',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandColor,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60), // Reduced from 110
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                ),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.only(left: 16, right: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                   boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppTheme.brandColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search properties',
                          style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: AppTheme.brandColor, shape: BoxShape.circle),
                        child: const Icon(Icons.mic, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40), // Closer spacing between search and listings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Verified Listings',
                    style: GoogleFonts.outfit(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FilterResultsScreen(
                            location: 'Verified Listings',
                            priceRange: 'Top Rated Properties',
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.east, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: Supabase.instance.client.from('properties').select('*, property_images(image_url)').order('created_at', ascending: false),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: 304,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: _buildSkeletonCard(context),
                        ),
                      ),
                    );
                  }

                  final properties = snapshot.data ?? [];
                  
                  if (properties.isEmpty) {
                    return Center(
                      child: Text(
                        'No live listings yet.',
                        style: GoogleFonts.outfit(color: Colors.grey),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 304,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: properties.length,
                      itemBuilder: (context, index) {
                        final p = properties[index];
                        final images = (p['property_images'] as List);
                        final String mainImage = images.isNotEmpty 
                            ? images[0]['image_url'] 
                            : 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80';

                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: _buildModernCard(
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
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF2F2F2)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder with heart overlay
            Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Container(
                    color: const Color(0xFFEEEEEE),
                  ),
                ),
                // Heart button on skeleton card
                const Positioned(
                  top: 10,
                  right: 10,
                  child: FavouriteButton(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 180, height: 10, decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(5))),
                  const SizedBox(height: 6),
                  Container(width: 100, height: 10, decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(5))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: Container(height: 32, decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(8)))),
                      const SizedBox(width: 8),
                      Expanded(child: Container(height: 32, decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(8)))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCard(
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
          ),
        ),
      ),
      child: Container(
        width: 260,
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Image (unchanged height) ---
              Stack(
                children: [
                  SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: Image.network(imageUrl, fit: BoxFit.cover),
                  ),
                  // "For Rent" badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'For Rent',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Favourite button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: FavouriteButton(propertyId: id),
                  ),
                ],
              ),
              // --- Content below image ---
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 1, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: price,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.brandColor,
                                ),
                              ),
                              TextSpan(
                                text: '/mo',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Location + Amenity icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.place_outlined, color: AppTheme.brandColor, size: 13),
                            const SizedBox(width: 2),
                            Text(
                              location,
                              style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Column(
                              children: [
                                Icon(Icons.bed_outlined, color: AppTheme.brandColor, size: 14),
                                Text('Bed', style: GoogleFonts.outfit(fontSize: 8, color: Colors.grey[700], fontWeight: FontWeight.w300)),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                Icon(Icons.directions_car_outlined, color: AppTheme.brandColor, size: 14),
                                Text('Parking', style: GoogleFonts.outfit(fontSize: 8, color: Colors.grey[700], fontWeight: FontWeight.w300)),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                Icon(Icons.wifi, color: AppTheme.brandColor, size: 14),
                                Text('Wifi', style: GoogleFonts.outfit(fontSize: 8, color: Colors.grey[700], fontWeight: FontWeight.w300)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Action Buttons
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
                            label: Text('Visit Now', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13.5)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brandColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChatScreen(
                                    name: 'Jenny Wilson',
                                    avatar: 'https://i.pravatar.cc/150?img=47',
                                    online: true,
                                  ),
                                ),
                              );
                            },
                            icon: SvgPicture.asset(
                              'assets/icons/message.svg',
                              width: 17,
                              height: 17,
                              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            ),
                            label: Text('Message', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13.5)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brandColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

class FavouriteButton extends StatefulWidget {
  final String propertyId;
  const FavouriteButton({super.key, required this.propertyId});

  @override
  State<FavouriteButton> createState() => _FavouriteButtonState();
}

class _FavouriteButtonState extends State<FavouriteButton> {
  bool isLiked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        setState(() {
          isLiked = !isLiked;
        });
        // Magic: Save to Supabase
        await SupabaseService.toggleSaveProperty(widget.propertyId);
      },
      child: Icon(
        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: 26,
        color: isLiked ? const Color(0xFFFF385C) : Colors.white,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
