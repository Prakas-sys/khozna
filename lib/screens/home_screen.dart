import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
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
  // Reduced to 5 high-impact sections to prevent duplication
  final List<Future<List<Map<String, dynamic>>>> _sectionFutures =
      List.generate(5, (index) => Future.value(<Map<String, dynamic>>[]));

  int _bossTaps = 0;
  Position? _currentPosition;
  final String _adminEmail = 'khoznaapp@gmail.com';

  @override
  void initState() {
    super.initState();
    _initializeFutures();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    // Acquire location asynchronously
    await _getCurrentLocation();

    // Once location is found, refresh only the sections that rely on location
    // or just refresh everything for simplicity since indices are now stable.
    if (mounted) {
      setState(() {
        _initializeFutures();
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
          ),
        );
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
        }
      } else {
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Error fetching location: $e");
      if (mounted) setState(() {});
    }
  }

  Future<void> refreshData() async {
    HapticFeedback.mediumImpact();
    await _getCurrentLocation();
    setState(() {
      _initializeFutures();
    });
    // Wait for all to finish for RefreshIndicator spinning state
    await Future.wait(_sectionFutures);
  }

  void _initializeFutures() {
    final client = Supabase.instance.client;

    for (int i = 0; i < 5; i++) {
      _sectionFutures[i] = _fetchSectionData(client, i);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSectionData(
    SupabaseClient client,
    int index,
  ) async {
    dynamic query = client
        .from('properties')
        .select('*, property_images(image_url)');

    switch (index) {
      case 0: // Near You (Location-based) - Promoted to #1
        if (_currentPosition != null) {
          query = query
              .gte('latitude', _currentPosition!.latitude - 0.1)
              .lte('latitude', _currentPosition!.latitude + 0.1)
              .gte('longitude', _currentPosition!.longitude - 0.1)
              .lte('longitude', _currentPosition!.longitude + 0.1);
        }
        query = query.order('created_at', ascending: false);
        break;
      case 1: // Recent Listings (Formerly Verified)
        query = query
            .order('created_at', ascending: false);
        break;
      case 2: // Student Housing (Room < 7k)
        query = query
            .eq('category', 'Room')
            .lt('price', 7000)
            .order('price', ascending: true);
        break;
      case 3: // Family Flats (Flat)
        query = query
            .eq('category', 'Flat')
            .order('created_at', ascending: false);
        break;
      case 4: // Premium Collections
        query = query
            .or('is_premium.eq.true,price.gt.20000')
            .order('price', ascending: false);
        break;
      default:
        query = query.order('created_at', ascending: false);
    }

    final data = await query.limit(6);
    return List<Map<String, dynamic>>.from(data);
  }

  void _handleBossTap() {
    HapticFeedback.lightImpact();
    setState(() {
      _bossTaps++;
      if (_bossTaps >= 5) {
        _bossTaps = 0;
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null && user.email == _adminEmail) {
          _showBossLogin();
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
            Text(
              'Admin Access',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter 4-digit security PIN',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        content: TextField(
          controller: pinController,
          obscureText: true,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 4,
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 16,
          ),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '••••',
            border: InputBorder.none,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (pinController.text == '8888') {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OwnerDashboard()),
                  );
                } else {
                  HapticFeedback.heavyImpact();
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Unlock Dashboard',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
                          border: Border.all(color: Colors.grey.shade200),
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
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
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
                },
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            child: Column(
              children: [
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      FittedBox(
                        child: Text(
                          'Find your Next Home',
                          style: GoogleFonts.zenAntiqueSoft(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        child: Text(
                          'No middleman',
                          style: GoogleFonts.zenAntiqueSoft(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.brandColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 54),
                Hero(
                  tag:
                      'search_bar_container', // Changed tag to be more specific
                  child: Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: () => _navigate(context, const SearchScreen()),
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.only(
                          left: 16,
                          top: 4,
                          bottom: 4,
                        ), // Removed horizontal to allow mic to sit flush right
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
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
                            Padding(
                              padding: const EdgeInsets.only(
                                right: 4,
                              ), // Minimal padding for the mic circle to sit flush on the right
                              child: InkWell(
                                onTap: () {
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
                                            builder: (_) => SearchScreen(
                                              initialQuery: text,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 38),

                // --- SECTION 1: NEAR YOU ---
                _buildHorizontalSection(
                  context,
                  'Near You',
                  'Properties in your current area',
                  _sectionFutures[0],
                ),

                const SizedBox(height: 40),

                // --- SECTION 2: DISCOVER ---
                _buildHorizontalSection(
                  context,
                  'Discover',
                  'Fresh listings personally for you',
                  _sectionFutures[1],
                ),

                const SizedBox(height: 40),

                // --- SECTION 3: STUDENT HOUSING ---
                _buildHorizontalSection(
                  context,
                  'Student Specials',
                  'Budget rooms near colleges',
                  _sectionFutures[2],
                ),

                const SizedBox(height: 40),

                // --- SECTION 4: FAMILY FLATS ---
                _buildHorizontalSection(
                  context,
                  'Family Flats',
                  'Spacious homes for everyone',
                  _sectionFutures[3],
                ),

                const SizedBox(height: 40),

                // --- SECTION 5: PREMIUM ---
                _buildHorizontalSection(
                  context,
                  'Premium Collections',
                  'Luxurious & Executive stays',
                  _sectionFutures[4],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalSection(
    BuildContext context,
    String title,
    String subtitle,
    Future<List<Map<String, dynamic>>> future,
  ) {
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
              onTap: () => _navigate(
                context,
                FilterResultsScreen(location: title, priceRange: subtitle),
              ),
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
                height: 285,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SkeletonCard(),
                  ),
                ),
              );
            }

            final properties = snapshot.data ?? [];

            if (properties.isEmpty) {
              return SizedBox(
                height: 285,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: 3,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SkeletonCard(),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 285,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: 4, // Always show 4 items to keep UI full
                itemBuilder: (context, index) {
                  if (index < properties.length) {
                    final p = properties[index];
                    final List joinImages = p['property_images'] ?? [];
                    final List arrayImages = p['images'] ?? [];
                    List<String> finalImages = [];

                    if (joinImages.isNotEmpty) {
                      finalImages = joinImages
                          .map((i) => i['image_url'].toString())
                          .toList();
                    } else if (arrayImages.isNotEmpty) {
                      finalImages = arrayImages
                          .map((i) => i.toString())
                          .toList();
                    }

                    final String mainImage = finalImages.isNotEmpty
                        ? finalImages[0]
                        : 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80';

                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: PropertyCard(
                        id: p['id'].toString(),
                        imageUrl: mainImage,
                        title: p['title'] ?? 'Apartment',
                        location: p['area_name'] ?? 'Kathmandu',
                        price: (p['price'] ?? 0).toString(),
                        bedrooms: p['bedrooms'] ?? 0,
                        bathrooms: p['bathrooms'] ?? 0,
                        area: (p['sq_ft'] ?? 0).toString(),
                        floor: p['floor'] ?? 'N/A',
                        description: p['description'] ?? '',
                        images: finalImages,
                        status: p['status'] ?? 'available',
                        ownerId: p['owner_id'] ?? '',
                        amenities: List<String>.from(p['amenities'] ?? []),
                        houseRules: List<String>.from(p['house_rules'] ?? []),
                        latitude: p['latitude'] != null
                            ? double.tryParse(p['latitude'].toString())
                            : null,
                        longitude: p['longitude'] != null
                            ? double.tryParse(p['longitude'].toString())
                            : null,
                      ),
                    );
                  } else {
                    // Fill remaining slots with skeletons
                    return const Padding(
                      padding: EdgeInsets.only(right: 16),
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
