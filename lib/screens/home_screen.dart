import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
import 'owner_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  // Caching futures to prevent flickering on rebuild
  final List<Future<List<Map<String, dynamic>>>> _sectionFutures = [];
  int _bossTaps = 0;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  final String _adminEmail = 'khoznaapp@gmail.com';
  final String _adminPin = '8888';

  void _handleBossTap() {
    // Add a subtle secret vibration for the boss
    HapticFeedback.lightImpact();
    
    setState(() {
      _bossTaps++;
      if (_bossTaps >= 5) {
        _bossTaps = 0; // Reset
        final user = Supabase.instance.client.auth.currentUser;
        
        // 🛡️ SECURITY SHIELD: Only "khoznaapp@gmail.com" can trigger the PIN prompt
        if (user != null && user.email == _adminEmail) {
          _showBossLogin();
        } else {
          debugPrint('Unauthorized Boss Mode attempt by: ${user?.email}');
        }
      }
    });
  }

  void _showBossLogin() {
    final TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            const SizedBox(height: 16),
            Text('Admin Access', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 22)),
            const SizedBox(height: 8),
            Text('Enter 4-digit security PIN', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: TextField(
            controller: pinController,
            obscureText: true,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 4,
            style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 16),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••',
              hintStyle: TextStyle(color: Colors.grey[300]),
              border: InputBorder.none,
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (pinController.text == '8888') { // Using 8888 as a default admin pin
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerDashboard()));
                } else {
                  HapticFeedback.heavyImpact();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access Denied')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Unlock Dashboard', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    await _getCurrentLocation();
    _initializeFutures();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low)
        );
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _isLoadingLocation = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingLocation = false);
      }
    } catch (e) {
      debugPrint("Error fetching location: $e");
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> refreshData() async {
    // Re-fetch location before refreshing data
    await _getCurrentLocation();
    setState(() {
      _sectionFutures.clear();
      _initializeFutures();
    });
    // Wait for all futures to complete for the RefreshIndicator
    await Future.wait(_sectionFutures);
  }

  void _initializeFutures() {
    final client = Supabase.instance.client;
    
    for (int i = 0; i < 10; i++) {
      var query = client
          .from('properties')
          .select('*, property_images(image_url)');
      
      // Categorization logic based on titles[index] in build method
      switch (i) {
        case 0: // Verified Listings
          query = query.eq('is_verified', true).order('created_at', ascending: false);
          break;
        case 1: // Recently Added
          query = query.order('created_at', ascending: false);
          break;
        case 2: // Near You (Location based)
          if (_currentPosition != null) {
            // Basic box filter (approx 10km radius calculation: ~0.1 degrees)
            query = query
              .gte('latitude', _currentPosition!.latitude - 0.1)
              .lte('latitude', _currentPosition!.latitude + 0.1)
              .gte('longitude', _currentPosition!.longitude - 0.1)
              .lte('longitude', _currentPosition!.longitude + 0.1);
          }
          query = query.order('created_at', ascending: false);
          break;
        case 3: // Popular in Kathmandu
          query = query.ilike('area_name', '%Kathmandu%').order('created_at', ascending: false);
          break;
        case 4: // Budget Friendly
          query = query.lt('price', 10000).order('price', ascending: true);
          break;
        case 5: // High-End Apartments
          query = query.eq('category', 'Apartment').gt('price', 20000).order('price', ascending: false);
          break;
        case 6: // Hot Deals (Recent + Cheap)
          query = query.lt('price', 15000).order('created_at', ascending: false);
          break;
        case 7: // Student Housing (Small rooms or cheap)
          query = query.eq('category', 'Room').lt('price', 7000).order('price', ascending: true);
          break;
        case 8: // Family Flats
          query = query.eq('category', 'Flat').order('created_at', ascending: false);
          break;
        case 9: // Premium Collections
          query = query.or('is_premium.eq.true,price.gt.15000').order('price', descending: true);
          break;
        default:
          query = query.order('created_at', ascending: false);
      }
      
      // Limit to 6 items per section for performance
      final limitedQuery = query.limit(6);
          
      _sectionFutures.add(limitedQuery.then((data) => List<Map<String, dynamic>>.from(data)));
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
        title: GestureDetector(
          onTap: _handleBossTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/original logo.png',
              height: 48,
              fit: BoxFit.contain,
            ),
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
              child: ValueListenableBuilder<int>(
                valueListenable: notificationBadgeCount,
                builder: (context, badgeCount, _) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
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
                      if (badgeCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF0000), // Vibrant Red
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.0),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 22,
                              minHeight: 22,
                            ),
                            child: Center(
                              child: Text(
                                badgeCount > 9 ? '9+' : '$badgeCount',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshData,
          color: AppTheme.brandColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
              Hero(
                tag: 'search_bar',
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _navigate(context, const SearchScreen());
                    },
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
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
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                'title': 'Demo',
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
                        price: '${p['price']}',
                        bedrooms: p['bedrooms'] ?? 0,
                        bathrooms: p['bathrooms'] ?? 0,
                        area: p['sq_ft'] ?? '0',
                        floor: p['floor'] ?? 'N/A',
                        description: p['description'] ?? '',
                        images: images.map((i) => i['image_url'].toString()).toList(),
                        status: p['status'] ?? 'available',
                        ownerId: p['owner_id'] ?? '',
                        amenities: List<String>.from(p['amenities'] ?? []),
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
