import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
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
  String _currentLocationName = 'Kirtipur, Nepal';

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
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // ⚡ Use lowest accuracy for instant fix (network/cell tower - fast!)
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.lowest,
          ),
        ).timeout(const Duration(seconds: 4));
        if (mounted) {
          setState(() => _currentPosition = position);
          _fetchAreaName(position);
        }
      }
    } catch (e) {
      debugPrint('Location fetch skipped: $e');
      // Stays on "Kirtipur, Nepal" default — that's fine
    }
  }

  Future<void> _fetchAreaName(Position position) async {
    try {
      // Log position for troubleshooting
      debugPrint('KHOZNA GEO: Lat=${position.latitude}, Lng=${position.longitude}');

      // Widen the check for Kirtipur area boundary (includes center, TU area, etc.)
      final bool isLocallyKirtipur = position.latitude >= 27.63 &&
          position.latitude <= 27.712 &&
          position.longitude >= 85.22 &&
          position.longitude <= 85.31;

      if (isLocallyKirtipur) {
        if (mounted) {
          setState(() => _currentLocationName = 'Kirtipur, Nepal');
        }
        return;
      }

      // ⚡ Use native geocoding only — fast, no network, no AI call
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 4));

      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        
        // Print clean representation for debugging
        debugPrint('KHOZNA PLACEMARK: subLocality=${p.subLocality}, locality=${p.locality}, thoroughfare=${p.thoroughfare}');

        // Check if Kirtipur is mentioned anywhere in the placemark address elements
        final String fullAddressString = '${p.name} ${p.subLocality} ${p.locality} ${p.subAdministrativeArea} ${p.administrativeArea}'.toLowerCase();
        if (fullAddressString.contains('kirtipur')) {
          if (mounted) {
            setState(() => _currentLocationName = 'Kirtipur, Nepal');
          }
          return;
        }

        String clean(String? s) => (s ?? '')
            .replaceAll('Municipality', '')
            .replaceAll('Nagarpalika', '')
            .replaceAll('Mahanagarpalika', '')
            .trim();

        final micro = clean(p.subLocality ?? p.thoroughfare ?? p.name ?? '');
        final macro = clean(p.locality ?? p.subAdministrativeArea ?? '');

        String area;
        if (micro.isNotEmpty && macro.isNotEmpty &&
            micro.toLowerCase() != macro.toLowerCase()) {
          area = '$micro, $macro';
        } else if (macro.isNotEmpty) {
          area = macro;
        } else if (micro.isNotEmpty) {
          area = micro;
        } else {
          area = 'Kirtipur, Nepal';
        }

        if (mounted) {
          setState(() => _currentLocationName = area);
        }
      }
    } catch (e) {
      debugPrint('Geocoding error (keeping default): $e');
      if (mounted) {
        setState(() => _currentLocationName = 'Kirtipur, Nepal');
      }
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                  onVoiceResult: (text) {
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
