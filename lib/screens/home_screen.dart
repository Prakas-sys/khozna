import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart' as geo;
import '../theme/app_theme.dart';
import '../utils/app_notifiers.dart';
import '../widgets/property_card.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/voice_search_overlay.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import 'filter_results_screen.dart';
import 'owner_dashboard.dart';
import '../utils/offline_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  // Reduced to 5 high-impact sections to prevent duplication
  final List<Future<List<Map<String, dynamic>>>> _sectionFutures =
      List.generate(5, (index) => Future.value(<Map<String, dynamic>>[]));

  Position? _currentPosition;
  final String _adminEmail = 'khoznaapp@gmail.com';
  String _currentLocationName = "Kathmandu, Nepal";

  @override
  void initState() {
    super.initState();
    _initializeFutures();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    // Load offline cache from disk for instant display across app restarts
    final diskCache = await OfflineStorage.loadHomeCache();
    if (diskCache.isNotEmpty) {
      homeSectionCache.value = diskCache;
      if (mounted) setState(() {});
    }

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
            accuracy: LocationAccuracy.high,
          ),
        );
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
          _fetchAreaName(position);
        }
      } else {
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Error fetching location: $e");
      if (mounted) setState(() {});
    }
  }

  Future<void> _fetchAreaName(Position position) async {
    try {
      String micro = '';
      String macro = '';

      // 1. Try Native Google Geocoding first
      try {
        List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          geo.Placemark place = placemarks.first;
          String street = place.street ?? '';
          String name = place.name ?? '';
          String subLocality = place.subLocality ?? '';
          macro = place.locality ?? place.subAdministrativeArea ?? '';

          if (street.isNotEmpty && !street.contains('+') && street.length > 3) {
             micro = street;
          } else if (name.isNotEmpty && !name.contains('+')) {
             micro = name;
          } else {
             micro = subLocality;
          }
          micro = micro.replaceAll('Road', '').replaceAll('Street', '').trim();
          if (micro.endsWith(',')) micro = micro.substring(0, micro.length - 1);
        }
      } catch (_) {}

      // 2. If Google failed to get the deep micro area (e.g. only gave Kirtipur), fallback to OSM structured Display Name extraction
      if (micro.isEmpty || micro == macro) {
        final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1');
        final response = await http.get(url, headers: {'User-Agent': 'KhoznaApp/1.0'});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final displayName = data['display_name']?.toString() ?? '';
          if (displayName.isNotEmpty) {
            // display_name format: "DeepArea, City, District, Province, Country"
            List<String> parts = displayName.split(',').map((e) => e.trim()).toList();
            if (parts.isNotEmpty) {
              micro = parts[0]; // The deepest possible physical area
              if (parts.length > 1 && macro.isEmpty) {
                macro = parts[1]; // Next level up
              }
            }
          }
        }
      }

      // 3. Assemble and clean
      String area;
      if (micro.isNotEmpty && macro.isNotEmpty && micro.toLowerCase() != macro.toLowerCase()) {
        if (micro.toLowerCase().contains(macro.toLowerCase())) {
           area = micro;
        } else {
           area = '$macro, $micro';
        }
      } else if (macro.isNotEmpty) {
        area = macro;
      } else {
        area = micro;
      }

      if (area.trim().isEmpty) area = 'Kathmandu, Nepal';

      if (mounted) {
        setState(() {
          _currentLocationName = area;
        });
      }
    } catch (e) {
      debugPrint("Error fetching area name: $e");
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
    try {
      dynamic query = client
          .from('properties')
          .select('*, property_images(image_url), profiles:owner_id(full_name, avatar_url)');

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
      final finalData = List<Map<String, dynamic>>.from(data);

      // Successfully fetched fresh data, update cache
      if (finalData.isNotEmpty) {
        final currentCache = Map<int, List<Map<String, dynamic>>>.from(
          homeSectionCache.value,
        );
        currentCache[index] = finalData;
        homeSectionCache.value = currentCache;
        OfflineStorage.saveHomeCache(currentCache); // Persist to disk
      }
      return finalData;
    } catch (e) {
      debugPrint("Error fetching section $index: $e");
      // Fallback to cache if available
      final cached = homeSectionCache.value[index];
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      return [];
    }
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
        title: Row(
          children: [
            Image.asset(
              'assets/images/original logo.png',
              height: 48,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  if (_currentPosition != null) {
                    final lat = _currentPosition!.latitude;
                    final lng = _currentPosition!.longitude;
                    final label = Uri.encodeComponent(_currentLocationName);
                    final gMapsUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
                    final gMapsBrowserUri = Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                    );
                    if (await canLaunchUrl(gMapsUri)) {
                      await launchUrl(gMapsUri);
                    } else {
                      await launchUrl(gMapsBrowserUri, mode: LaunchMode.externalApplication);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Location not yet detected. Please wait...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.brandColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.location_solid,
                          color: AppTheme.brandColor,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Marquee effect: Horizontal scrolling remains active for long text
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            _currentLocationName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.black.withValues(alpha: 0.8),
                              height: 1.1,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.brandColor.withValues(alpha: 0.5),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
                              color: Color(0xFFFF0000), // Pure vibrant red
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
                const SizedBox(height: 32), // Pushed down slightly from app bar
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      FittedBox(
                        child: Text(
                          'Find your Next Home',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        child: Text(
                          'No middleman',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            color: AppTheme.brandColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 42), // Increased gap below hero for better breathing room
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
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
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
                const SizedBox(height: 48), // Pushed down sections for a more centered stack

                // --- SECTION 1: NEAR YOU ---
                _buildHorizontalSection(
                  context,
                  'Near You',
                  'Properties in your current area',
                  _sectionFutures[0],
                ),                const SizedBox(height: 18),

                // --- SECTION 3: STUDENT HOUSING ---
                _buildHorizontalSection(
                  context,
                  'Student Specials',
                  'Budget rooms near colleges',
                  _sectionFutures[2],
                ),

                const SizedBox(height: 18),

                // --- SECTION 4: FAMILY FLATS ---
                _buildHorizontalSection(
                  context,
                  'Family Flats',
                  'Spacious homes for everyone',
                  _sectionFutures[3],
                ),

                const SizedBox(height: 18),

                // --- SECTION 5: PREMIUM ---
                _buildHorizontalSection(
                  context,
                  'Premium Collections',
                  'Luxurious & Executive stays',
                  _sectionFutures[4],
                ),

                const SizedBox(height: 24), // Reduced to keep it tight near nav bar
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
            Transform.translate(
              offset: const Offset(0, -4), // Nudge arrow up slightly
              child: InkWell(
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
            ),
          ],
        ),
        const SizedBox(height: 12), // Tighten gap between title and cards
        FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 285, // Perfectly fits the tightened PropertyCard without overflow
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
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
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasError) {
                return Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, color: Colors.grey[400], size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Offline Mode',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Check internet to refresh',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }
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
              height: 285, // Perfectly fits the tightened PropertyCard without overflow
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none, // Ensure shadows aren't clipped
                physics: const BouncingScrollPhysics(),
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

                    final ownerProfile = p['profiles'] as Map<String, dynamic>?;
                    final String ownerName = ownerProfile?['full_name'] ?? 'Khozna User';
                    final String ownerAvatar = ownerProfile?['avatar_url'] ?? '';
                    final bool isOwnerVerified = ownerProfile?['is_verified'] ?? false;

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
                        ownerName: ownerName,
                        ownerAvatar: ownerAvatar,
                        isOwnerVerified: isOwnerVerified,
                        amenities: List<String>.from(p['amenities'] ?? []),
                        houseRules: List<String>.from(p['house_rules'] ?? []),
                        latitude: p['latitude'] != null
                            ? double.tryParse(p['latitude'].toString())
                            : null,
                        longitude: p['longitude'] != null
                            ? double.tryParse(p['longitude'].toString())
                            : null,
                        landmark: p['landmark'] ?? '',
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
