import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../utils/app_notifiers.dart';
import '../utils/supabase_service.dart';
import 'property_details_screen.dart';
import 'search_screen.dart';
import 'filter_results_screen.dart';
import 'chat_screen.dart';
import 'kyc_screen.dart';
import '../widgets/favourite_button.dart';
import 'notifications_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _checkAuthAndNavigate(BuildContext context, Widget destination) {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
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
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87, size: 26),
                      onPressed: () {
                        notificationBadgeCount.value = 0;
                        _checkAuthAndNavigate(context, const NotificationsScreen());
                      },
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        top: 10,
                        right: 12,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
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
          padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 35.0), // tweaked to 35 for clear "little" gap above nav bar
          child: Column(
            children: [
              const SizedBox(height: 32), // moved up slightly from 48
              Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Find your Next Home',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.2,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No Middleman',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.brandColor,
                        height: 1.1,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80), // moved up from 110 for better balance
              GestureDetector(
                onTap: () => _checkAuthAndNavigate(context, const SearchScreen()),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: Colors.grey[400], 
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppTheme.brandColor, 
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 38), // Shifted down a little from 30
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Verified Listings',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      _checkAuthAndNavigate(
                        context,
                        const FilterResultsScreen(
                          location: 'Verified Listings',
                          priceRange: 'Top Rated Properties',
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
              const SizedBox(height: 18), // 1 number below listings
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

                  // Hardcoded Demo Property
                  final Map<String, dynamic> demoProperty = {
                    'id': 'demo-property-id',
                    'title': 'Modern Apartment in Kathmandu',
                    'area_name': 'Baneshwor, Kathmandu',
                    'price': '45,000',
                    'bedrooms': 2,
                    'bathrooms': 2,
                    'sq_ft': '1,200',
                    'floor': '3rd Floor',
                    'description': 'Experience luxury living in the heart of Kathmandu. This modern apartment offers breathtaking city views, high-end finishes, and complete security.',
                    'property_images': [
                      {'image_url': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'}
                    ],
                  };

                  final List<Map<String, dynamic>> properties = [
                    demoProperty,
                    ...(snapshot.data ?? []),
                  ];
                  
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
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF2F2F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Placeholder
          Container(
            height: 190,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Price line
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 120, height: 14, decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4))),
                    Container(width: 60, height: 14, decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4))),
                  ],
                ),
                const SizedBox(height: 8),
                // Location line
                Container(width: 100, height: 10, decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 12),
                // Button lines
                Row(
                  children: [
                    Expanded(child: Container(height: 38, decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(30)))),
                    const SizedBox(width: 8),
                    Expanded(child: Container(height: 38, decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(30)))),
                  ],
                ),
              ],
            ),
          ),
        ],
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
      onTap: () => _checkAuthAndNavigate(
        context,
        PropertyDetailsScreen(
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
                            onPressed: () => _checkAuthAndNavigate(
                              context,
                              PropertyDetailsScreen(
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
                            onPressed: () => _checkAuthAndNavigate(
                              context,
                              const ChatScreen(
                                name: 'Jenny Wilson',
                                avatar: 'https://i.pravatar.cc/150?img=47',
                                online: true,
                              ),
                            ),
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

