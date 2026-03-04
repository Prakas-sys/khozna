import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/favourite_button.dart';
import 'property_details_screen.dart';
import 'chat_screen.dart';
import 'home_screen.dart';

class FilterResultsScreen extends StatelessWidget {
  final String location;
  final String priceRange;

  const FilterResultsScreen({
    super.key,
    this.location = 'Verified Listings',
    this.priceRange = 'Top Rated Properties',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(location, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            Text(priceRange, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.tune, color: AppTheme.brandColor, size: 22), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Supabase.instance.client.from('properties').select('*, property_images(image_url)').order('created_at', ascending: false),
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

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: 10, // ALWAYS show 10 items
            itemBuilder: (context, index) {
              if (index < properties.length) {
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
                  ),
                );
              } else {
                // Show skeletons if less than 10 real listings
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildSkeletonCard(context),
                );
              }
            },
          );
        },
      ),
    );
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF2ECC71), borderRadius: BorderRadius.circular(20)),
                      child: Text('For Rent', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
                        Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold))),
                        Text(price, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.brandColor)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, color: AppTheme.brandColor, size: 14),
                        const SizedBox(width: 4),
                        Text(location, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600])),
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
                            label: Text('Visit Now', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13.5)),
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
                                  builder: (_) => const ChatScreen(name: 'Jenny Wilson', avatar: 'https://i.pravatar.cc/150?img=47', online: true),
                                ),
                              );
                            },
                            icon: SvgPicture.asset('assets/icons/message.svg', width: 17, height: 17, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                            label: Text('Message', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13.5)),
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
