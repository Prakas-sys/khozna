import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../utils/app_notifiers.dart';
import '../widgets/property_card.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/voice_search_overlay.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import 'filter_results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Caching futures to prevent flickering on rebuild
  final List<Future<List<Map<String, dynamic>>>> _sectionFutures = [];

  @override
  void initState() {
    super.initState();
    _initializeFutures();
  }

  void _initializeFutures() {
    final client = Supabase.instance.client;
    for (int i = 0; i < 10; i++) {
      final query = client
          .from('properties')
          .select('*, property_images(image_url)');
      
      final orderedQuery = i % 2 == 0 
          ? query.order('created_at', ascending: false)
          : query.order('price', ascending: true);
          
      _sectionFutures.add(orderedQuery.then((data) => List<Map<String, dynamic>>.from(data)));
    }
  }

  void _navigate(BuildContext context, Widget destination) {
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
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
            height: 48,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () {
                notificationBadgeCount.value = 0;
                _navigate(context, const NotificationsScreen());
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
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 40.0),
          child: Column(
            children: [
              const SizedBox(height: 32),
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
              const SizedBox(height: 68),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _navigate(context, const SearchScreen());
                },
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
                          style: GoogleFonts.inter(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) => VoiceSearchOverlay(
                              onResult: (text) {
                                Navigator.pop(context);
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
              const SizedBox(height: 45),
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
                
                return Column(
                  children: [
                    _buildHorizontalSection(context, title, subtitle, _sectionFutures[index]),
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

  Widget _buildHorizontalSection(BuildContext context, String title, String subtitle, Future<List<Map<String, dynamic>>> future) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _navigate(
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
                  itemBuilder: (context, index) => const Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SkeletonCard(),
                  ),
                ),
              );
            }

            final List<Map<String, dynamic>> properties = List<Map<String, dynamic>>.from(snapshot.data ?? []);

            // Add hardcoded demo property to the first row for testing if empty
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
                'owner_id': 'demo-owner',
                'status': 'available',
                'property_images': [{'image_url': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'}],
              });
            }

            return SizedBox(
              height: 304,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: 10, 
                itemBuilder: (context, index) {
                  if (index < properties.length) {
                    final p = properties[index];
                    final images = (p['property_images'] as List);
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
                        images: images.map((i) => i['image_url'].toString()).toList(),
                        ownerId: p['owner_id'] ?? '',
                        status: p['status'] ?? 'available',
                      ),
                    );
                  } else {
                    return const Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: SkeletonCard(),
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
}
