import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart' as geo;
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/core/utils/offline_storage.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/features/property/repositories/property_repository.dart';
import 'package:khozna/features/profile/screens/notifications_screen.dart';
import 'package:khozna/features/property/screens/search_screen.dart';
import 'package:khozna/features/property/screens/filter_results_screen.dart';
import 'package:khozna/features/property/screens/discovery_map_screen.dart';
import 'package:khozna/core/guards/auth_guard.dart';
import '../widgets/home_widgets.dart';

import 'package:khozna/core/services/khozna_ai_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final List<Future<List<Property>>> _sectionFutures = List.generate(
    5,
    (index) => Future.value(<Property>[]),
  );
  Position? _currentPosition;
  String _currentLocationName = "Kathmandu, Nepal";
  final KhoznaAiService _aiService = KhoznaAiService();

  @override
  void initState() {
    super.initState();
    _initializeFutures();
    _fetchInitialData();
    refreshTrigger.addListener(_onGlobalRefresh);
  }

  @override
  void dispose() {
    refreshTrigger.removeListener(_onGlobalRefresh);
    super.dispose();
  }

  void _onGlobalRefresh() {
    if (mounted) {
      refreshData();
    }
  }

  Future<void> _fetchInitialData() async {
    final diskCache = await OfflineStorage.loadHomeCache();
    if (diskCache.isNotEmpty) {
      homeSectionCache.value = diskCache;
      if (mounted) setState(() {});
    }
    await _getCurrentLocation();
    if (mounted) _initializeFutures();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        if (mounted) {
          setState(() => _currentPosition = position);
          _fetchAreaName(position);
        }
      }
    } catch (e) {
      debugPrint("Error fetching location: $e");
    }
  }

  Future<void> _fetchAreaName(Position position) async {
    try {
      String micro = '';
      String macro = '';
      String rawDisplayName = '';

      geo.Placemark? nativePlace;
      try {
        List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          nativePlace = placemarks.first;
          macro =
              nativePlace.locality ?? nativePlace.subAdministrativeArea ?? '';
          micro =
              (nativePlace.subLocality ??
                      nativePlace.thoroughfare ??
                      nativePlace.name ??
                      '')
                  .replaceAll('Road', '')
                  .replaceAll('Street', '')
                  .trim();
        }
      } catch (_) {}

      // Get raw data from Nominatim for additional context
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'KhoznaApp/1.0'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        rawDisplayName = data['display_name'] ?? '';
        final address = data['address'];
        if (address != null && (micro.isEmpty || macro.isEmpty)) {
          final osmMicro =
              address['suburb'] ??
              address['neighbourhood'] ??
              address['hamlet'] ??
              address['quarter'] ??
              address['village'] ??
              address['residential'] ??
              address['road'] ??
              '';
          final osmMacro =
              address['city'] ??
              address['town'] ??
              address['municipality'] ??
              address['city_district'] ??
              address['county'] ??
              '';
          if (micro.isEmpty) micro = osmMicro;
          if (macro.isEmpty) macro = osmMacro;
        }
      }

      // If we have a very specific native subLocality, we use it as a "Strong Lead" for the AI
      String area = '';
      try {
        debugPrint(
          "Location Debug - Lat: ${position.latitude}, Lng: ${position.longitude}",
        );
        final aiPolished = await _aiService.refineLocationWithAI(
          lat: position.latitude,
          lng: position.longitude,
          rawAddress:
              "Native Specific: $micro, Native City: $macro, Full OSM: $rawDisplayName",
        );
        debugPrint("AI Location Response: $aiPolished");

        if (aiPolished.isNotEmpty && aiPolished.contains(',')) {
          area = aiPolished;
        }
      } catch (e) {
        debugPrint("AI Location refinement failed: $e");
      }

      // Fallback/Cleanup
      if (area.isEmpty) {
        String clean(String s) => s
            .replaceAll('Municipality', '')
            .replaceAll('Nagarpalika', '')
            .replaceAll('Mahanagarpalika', '')
            .trim();
        micro = clean(micro);
        macro = clean(macro);
        bool isPlusCode(String s) => s.contains('+') && s.length <= 12;
        if (isPlusCode(micro)) micro = '';
        if (isPlusCode(macro)) macro = '';

        if (micro.isNotEmpty &&
            macro.isNotEmpty &&
            micro.toLowerCase() != macro.toLowerCase()) {
          area = '$micro, $macro';
        } else if (macro.isNotEmpty) {
          area = macro;
        } else if (micro.isNotEmpty) {
          area = micro;
        } else {
          area = 'Kathmandu, Nepal';
        }
      }

      // Final redundancy check: If "Kirtipur, Kirtipur", just show "Kirtipur"
      if (area.contains(',')) {
        List<String> parts = area.split(',').map((e) => e.trim()).toList();
        if (parts.length >= 2 &&
            parts[0].toLowerCase() == parts[1].toLowerCase()) {
          area = parts[0];
        }
      }

      // HARD SAFETY OVERRIDE: Kill the "Sanga" hallucination for Kirtipur users
      // If the coordinates are clearly in Kirtipur but the API/AI says "Sanga", force it to Khasibazar.
      final lat = position.latitude;
      final lng = position.longitude;
      bool isInKirtipur =
          lat > 27.65 && lat < 27.70 && lng > 85.25 && lng < 85.30;
      if (isInKirtipur &&
          (area.toLowerCase().contains('sanga') || area.contains('सा:गा'))) {
        area = "Khasibazar, Kirtipur";
      }

      if (mounted) setState(() => _currentLocationName = area);
    } catch (e) {
      debugPrint("Error fetching area name: $e");
    }
  }

  Future<void> _initializeFutures() async {
    final Set<String> seenIds = {};

    for (int i = 0; i < 5; i++) {
      // We create a new future that waits for the previous ones to finish their 'seenIds' update
      final sectionData = await PropertyRepository.getSectionProperties(
        index: i,
        lat: _currentPosition?.latitude,
        lng: _currentPosition?.longitude,
        excludeIds: seenIds.toList(),
      );

      // Add these to our "Memory"
      for (var p in sectionData) {
        seenIds.add(p.id);
      }

      // Update the UI with this section's unique data
      if (mounted) {
        setState(() {
          _sectionFutures[i] = Future.value(sectionData);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          child: HomeHeader(
            locationName: _currentLocationName,
            onLocationTap: _handleLocationTap,
            onLogoTap: refreshData,
            onNotificationTap: () {
              notificationBadgeCount.value = 0;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: refreshData,
        color: AppTheme.brandColor,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                const HomeHeroSection(),
                const SizedBox(height: 24),
                HomeSearchBar(
                  onTap: () {
                    if (!AuthGuard.checkAuth(
                      context,
                      title: 'Search Properties',
                      message: 'Log in to search and discover matching properties.',
                    )) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                  onVoiceResult: (text) {
                    if (!AuthGuard.checkAuth(
                      context,
                      title: 'Search Properties',
                      message: 'Log in to search and discover matching properties.',
                    )) return;
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SearchScreen(initialQuery: text),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                _buildSection(0, 'Near You', 'Properties in your current area'),
                const SizedBox(height: 18),
                _buildSection(
                  1,
                  'Special Deals',
                  'Exclusive offers & negotiable prices',
                ),
                const SizedBox(height: 18),
                _buildSection(
                  2,
                  'Student Specials',
                  'Budget rooms near colleges',
                ),
                const SizedBox(height: 18),
                _buildSection(
                  3,
                  'Family Friendly',
                  'Spacious homes for everyone',
                ),
                const SizedBox(height: 18),
                _buildSection(
                  4,
                  'Premium Selection',
                  'Luxurious & Executive stays',
                ),
                const SizedBox(
                  height: 120,
                ), // Added significant extra space so the bottom section isn't cut off by the menu
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(int index, String title, String subtitle) {
    return HomeHorizontalSection(
      index: index,
      title: title,
      subtitle: subtitle,
      future: _sectionFutures[index],
      onViewAll: (t, s) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FilterResultsScreen(location: t, priceRange: s),
        ),
      ),
    );
  }

  Future<void> _handleLocationTap() async {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DiscoveryMapScreen()),
    );
  }

  Future<void> refreshData() async {
    HapticFeedback.mediumImpact();
    await OfflineStorage.clearHomeCache();
    homeSectionCache.value = {};
    await _getCurrentLocation();
    _initializeFutures();
    await Future.wait(_sectionFutures);
  }
}
