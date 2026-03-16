import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/cupertino.dart';
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
import '../widgets/voice_search_overlay.dart';
import 'notifications_screen.dart';
import 'login_screen.dart';
import '../widgets/property_card.dart';

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
            height: 48, // Increased from 40 to make it larger as requested
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ValueListenableBuilder<int>(
              valueListenable: notificationBadgeCount,
              builder: (context, count, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InkWell(
                      onTap: () {
                        notificationBadgeCount.value = 0;
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200, width: 1.0),
                        ),
                        child: const Icon(
                          CupertinoIcons.bell,
                          color: Colors.black87,
                          size: 28,
                        ),
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF0000), // Pure Instagram Red
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 9.5, 
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24.0,
            0,
            24.0,
            40.0,
          ), // Increased bottom padding to ensure nothing is below nav bar
          child: Column(
            children: [
              const SizedBox(height: 32), // Pushed hero section down as requested
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Find your Next Home',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.zenAntiqueSoft(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'No middleman',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.zenAntiqueSoft(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.brandColor,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 68), // Adjusted down to keep hero section balanced
              GestureDetector(
                onTap: () =>
                    _checkAuthAndNavigate(context, const SearchScreen()),
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
                      const Icon(
                        CupertinoIcons.search,
                        color: AppTheme.brandColor,
                        size: 22,
                        weight: 800,
                      ),
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
                      InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) => VoiceSearchOverlay(
                              onResult: (text) {
                                Navigator.pop(context); // Close overlay
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SearchScreen(),
                                    settings: RouteSettings(arguments: text),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppTheme.brandColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // CATEGORY CHIPS SYSTEM (BIG STARTUP UI)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    _buildCategoryChip('All Rentals', CupertinoIcons.house_fill, true),
                    _buildCategoryChip('Rooms', CupertinoIcons.bed_double, false),
                    _buildCategoryChip('Flats', Icons.apartment, false),
                    _buildCategoryChip('Houses', CupertinoIcons.house_alt, false),
                    _buildCategoryChip('Office Space', CupertinoIcons.briefcase, false),
                    _buildCategoryChip('Land', CupertinoIcons.map, false),
                  ],
                ),
              ),
              const SizedBox(height: 45), // Reduced from 85 to bring cards back up
              // 10x10 HORIZONTAL GRID SYSTEM
              ...List.generate(10, (index) {
                final titles = [
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
                ];
                
                final title = titles[index];
                final subtitle = 'Explore high-quality properties in $title';
                
                // Variation in queries for demo data diversity
                final query = Supabase.instance.client
                    .from('properties')
                    .select('*, property_images(image_url), profiles(full_name, avatar_url)');
                
                final orderedQuery = index % 2 == 0 
                    ? query.order('created_at', ascending: false)
                    : query.order('price', ascending: true);

                return Column(
                  children: [
                    _buildHorizontalSection(context, title, subtitle, orderedQuery),
                    const SizedBox(height: 40),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalSection(BuildContext context, String title, String subtitle, dynamic future) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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
                  FilterResultsScreen(
                    location: title,
                    priceRange: subtitle,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.east, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 304,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 10,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _buildSkeletonCard(context),
                  ),
                ),
              );
            }

            final List<Map<String, dynamic>> properties = List<Map<String, dynamic>>.from(snapshot.data ?? []);

            // Add hardcoded demo property to the first row for testing
            if (title == 'Verified Listings' && properties.isEmpty) {
               properties.add({
                'id': 'demo-property-id',
                'title': 'Modern Apartment in Kathmandu',
                'area_name': 'Baneshwor, Kathmandu',
                'price': '45,000',
                'bedrooms': 2,
                'bathrooms': 2,
                'sq_ft': '1,200',
                'floor': '3rd Floor',
                'description': 'Experience luxury living in the heart of Kathmandu.',
                'property_images': [{'image_url': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'}],
              });
            }

            return SizedBox(
              height: 304,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: 10, // ALWAYS show 10 items
                itemBuilder: (context, index) {
                  if (index < properties.length) {
                    final p = properties[index];
                    final images = (p['property_images'] as List? ?? []);
                    final String mainImage = images.isNotEmpty
                        ? images[0]['image_url']
                        : 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80';

                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: PropertyCard(
                        id: p['id'],
                        imageUrl: mainImage,
                        title: p['title'],
                        location: p['area_name'],
                        price: 'रू ${p['price']}',
                        bedrooms: p['bedrooms'] ?? 0,
                        bathrooms: p['bathrooms'] ?? 0,
                        area: p['sq_ft'] ?? '0',
                        floor: p['floor'] ?? 'N/A',
                        description: p['description'] ?? '',
                        ownerId: p['owner_id'] ?? '',
                        status: p['status'] ?? 'available',
                        ownerName: p['profiles']?['full_name'] ?? 'Khozna Owner',
                        ownerAvatar: p['profiles']?['avatar_url'] ?? 'https://i.pravatar.cc/150?img=47',
                        images: images
                            .map((i) => i['image_url'].toString())
                            .toList(),
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _buildSkeletonCard(context),
                    );
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }


  Widget _buildCategoryChip(String label, IconData icon, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.brandColor : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isActive ? AppTheme.brandColor : Colors.grey[200]!,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: AppTheme.brandColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive ? Colors.white : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? Colors.white : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSkeletonCard(BuildContext context, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : 260,
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
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Location line
                Container(
                  width: 100,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                // Button lines
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(30),
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
    );
  }

}
