import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/core/utils/offline_storage.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/features/property/repositories/property_repository.dart';
import 'package:khozna/features/profile/screens/notifications_screen.dart';
import 'package:khozna/features/property/screens/search_screen.dart';
import 'package:khozna/features/property/screens/filter_results_screen.dart';
import 'package:khozna/features/property/screens/discovery_map_screen.dart';
import '../widgets/home_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final List<List<Property>> _sectionProperties = List.generate(
    5,
    (index) => <Property>[],
  );
  final List<bool> _sectionLoading = List.generate(
    5,
    (index) => true,
  );
  Position? _currentPosition;
  String _currentLocationName = 'Nepal';

  @override
  void initState() {
    super.initState();
    // ⚡ Read cache synchronously from memory first so the first frame renders instantly
    if (homeSectionCache.value.isNotEmpty) {
      for (int i = 0; i < 5; i++) {
        final cachedData = homeSectionCache.value[i] ?? [];
        _sectionProperties[i] = cachedData.map((e) => Property.fromMap(e)).toList();
        _sectionLoading[i] = false;
      }
    }
    _fetchInitialData();
    refreshTrigger.addListener(_onGlobalRefresh);
  }

  Future<void> _initializeFutures() async {
    final startTime = DateTime.now();

    final List<Future<List<Property>>> futures = List.generate(
      5,
      (i) => PropertyRepository.getSectionProperties(
        index: i,
        lat: _currentPosition?.latitude,
        lng: _currentPosition?.longitude,
      ),
    );

    final results = await Future.wait(futures);

    final Set<String> seenIds = {};
    final List<List<Property>> filteredResults = [];

    for (var list in results) {
      final List<Property> filtered = [];
      for (var p in list) {
        if (!seenIds.contains(p.id)) {
          seenIds.add(p.id);
          filtered.add(p);
        }
      }
      // If deduplication cleared all items for this section, retain original list so section is not empty
      if (filtered.isEmpty && list.isNotEmpty) {
        filtered.addAll(list);
      }
      filteredResults.add(filtered);
    }

    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final bool hadNoData = _sectionProperties.every((list) => list.isEmpty);
    
    // Hold skeleton for a brief period if it finishes too fast (prevent visual flicker)
    if (hadNoData && elapsed < 650) {
      await Future.delayed(Duration(milliseconds: 650 - elapsed));
    }

    // Deep compare to only trigger UI update if anything changed
    bool dataChanged = false;
    for (int i = 0; i < 5; i++) {
      final currentList = _sectionProperties[i];
      final newList = filteredResults[i];
      if (currentList.length != newList.length) {
        dataChanged = true;
        break;
      }
      for (int j = 0; j < currentList.length; j++) {
        if (currentList[j].id != newList[j].id || 
            currentList[j].price != newList[j].price ||
            currentList[j].status != newList[j].status ||
            currentList[j].title != newList[j].title) {
          dataChanged = true;
          break;
        }
      }
      if (dataChanged) break;
    }

    if (mounted) {
      setState(() {
        for (int i = 0; i < 5; i++) {
          if (dataChanged) {
            _sectionProperties[i] = filteredResults[i];
          }
          _sectionLoading[i] = false;
        }
      });
    }
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
    // If cache not loaded in memory yet, load from disk
    if (homeSectionCache.value.isEmpty) {
      final diskCache = await OfflineStorage.loadHomeCache();
      if (diskCache.isNotEmpty) {
        homeSectionCache.value = diskCache;
        for (int i = 0; i < 5; i++) {
          final cachedData = diskCache[i] ?? [];
          if (cachedData.isNotEmpty) {
            _sectionProperties[i] = cachedData.map((e) => Property.fromMap(e)).toList();
            _sectionLoading[i] = false;
          }
        }
        if (mounted) setState(() {});
      }
    } else {
      // If already in memory, only apply cache when it has content
      for (int i = 0; i < 5; i++) {
        final cachedData = homeSectionCache.value[i] ?? [];
        if (cachedData.isNotEmpty) {
          _sectionProperties[i] = cachedData.map((e) => Property.fromMap(e)).toList();
          _sectionLoading[i] = false;
        }
      }
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

        // ⚡ First try last known position for instant display
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          _currentPosition = lastKnown;
          _fetchAreaName(lastKnown);
        }

        // Then get fresh accurate position with fallback sequence to prevent timeout hang
        Position? position;
        try {
          // 1. Try High Accuracy first (Fast 6s timeout)
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          ).timeout(const Duration(seconds: 6));
        } catch (_) {
          // 2. Fallback to Medium (Network based, fast 4s timeout)
          try {
            position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
              ),
            ).timeout(const Duration(seconds: 4));
          } catch (_) {
            // Keep default/lastKnown if both failed
          }
        }

        if (position != null) {
          _currentPosition = position;
          await _fetchAreaName(position); // overwrite with fresh result
        } else {
          // Fallback to IP location if GPS coordinates could not be retrieved
          await _fallbackToIpLocation();
        }
      } else {
        // Fallback to IP if permissions are denied
        await _fallbackToIpLocation();
      }
    } catch (e) {
      debugPrint('Location fetch skipped, attempting IP fallback: $e');
      await _fallbackToIpLocation();
    }
  }

  Future<void> _fallbackToIpLocation() async {
    // 1. Try ip-api.com (reliable, unthrottled in Nepal)
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json')).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final double? lat = double.tryParse(data['lat']?.toString() ?? '');
          final double? lng = double.tryParse(data['lon']?.toString() ?? '');
          final String city = data['city']?.toString() ?? '';
          final String region = data['regionName']?.toString() ?? '';
          
          if (lat != null && lng != null && mounted) {
            final pos = Position(
              latitude: lat,
              longitude: lng,
              timestamp: DateTime.now(),
              accuracy: 1000.0,
              altitude: 0.0,
              heading: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
              altitudeAccuracy: 0.0,
              headingAccuracy: 0.0,
            );
            
            setState(() {
              _currentPosition = pos;
              _currentLocationName = region.isNotEmpty && region.toLowerCase() != city.toLowerCase()
                  ? '$city, $region'
                  : city.isNotEmpty ? city : 'Nepal';
              currentLocationName.value = _currentLocationName;
            });
            return; // Success!
          }
        }
      }
    } catch (e) {
      debugPrint('Primary IP fallback failed: $e');
    }

    // 2. Try ipapi.co (secondary fallback)
    try {
      final response = await http.get(Uri.parse('https://ipapi.co/json')).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final double? lat = double.tryParse(data['latitude']?.toString() ?? '');
        final double? lng = double.tryParse(data['longitude']?.toString() ?? '');
        final String? city = data['city']?.toString();
        final String? region = data['region']?.toString();
        
        if (lat != null && lng != null && mounted) {
          final pos = Position(
            latitude: lat,
            longitude: lng,
            timestamp: DateTime.now(),
            accuracy: 1000.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );
          
          setState(() {
            _currentPosition = pos;
            if (city != null && city.isNotEmpty) {
              _currentLocationName = region != null && region.isNotEmpty && region.toLowerCase() != city.toLowerCase()
                  ? '$city, $region'
                  : city;
              currentLocationName.value = _currentLocationName;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Secondary IP fallback failed: $e');
    }
  }

  Future<void> _fetchAreaName(Position position) async {
    try {
      debugPrint('KHOZNA GEO: Lat=${position.latitude}, Lng=${position.longitude}');

      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 8));

      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        debugPrint('KHOZNA PLACEMARK: name=${p.name}, subLocality=${p.subLocality}, thoroughfare=${p.thoroughfare}, locality=${p.locality}, street=${p.street}, subAdmin=${p.subAdministrativeArea}');

        String clean(String? s) => (s ?? '')
            .replaceAll('Municipality', '')
            .replaceAll('Nagarpalika', '')
            .replaceAll('Mahanagarpalika', '')
            .trim();

        bool isUsable(String? s) {
          if (s == null) return false;
          final t = s.trim();
          return t.isNotEmpty &&
              t.length > 2 &&
              !t.contains('+') &&
              double.tryParse(t) == null &&
              int.tryParse(t) == null;
        }

        // Neighborhood: most specific level available
        final String neighborhood = clean(
          [p.subLocality, p.thoroughfare, p.name, p.street]
              .firstWhere(isUsable, orElse: () => null),
        );

        // City: best administrative match
        final String city = clean(
          [p.locality, p.subAdministrativeArea, p.administrativeArea]
              .firstWhere(isUsable, orElse: () => null),
        );

        String area;
        if (neighborhood.isNotEmpty && city.isNotEmpty &&
            neighborhood.toLowerCase() != city.toLowerCase()) {
          area = '$neighborhood, $city';
        } else if (city.isNotEmpty) {
          area = city;
        } else if (neighborhood.isNotEmpty) {
          area = neighborhood;
        } else {
          area = 'Nepal';
        }

        if (mounted && _currentLocationName != area) {
          setState(() => _currentLocationName = area);
          currentLocationName.value = area; // sync global notifier
        }
      }
    } catch (e) {
      debugPrint('Geocoding error (trying OSM fallback): $e');
      
      // Fallback to OpenStreetMap reverse geocoding to bypass slow/failing Google Services in Nepal
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1'
        );
        final response = await http.get(url, headers: {
          'User-Agent': 'KhoznaApp/1.0 (nepal; mobile)'
        }).timeout(const Duration(seconds: 4));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final address = data['address'];
          if (address != null) {
            String neighborhood = address['neighbourhood'] ?? 
                                 address['suburb'] ?? 
                                 address['residential'] ?? 
                                 address['village'] ?? 
                                 address['road'] ?? 
                                 '';
            String city = address['city'] ?? 
                         address['town'] ?? 
                         address['municipality'] ?? 
                         address['locality'] ?? 
                         '';
            
            String clean(String s) => s
                .replaceAll('Municipality', '')
                .replaceAll('Nagarpalika', '')
                .replaceAll('Mahanagarpalika', '')
                .trim();
                
            neighborhood = clean(neighborhood);
            city = clean(city);
            
            String area;
            if (neighborhood.isNotEmpty && city.isNotEmpty &&
                neighborhood.toLowerCase() != city.toLowerCase()) {
              area = '$neighborhood, $city';
            } else if (city.isNotEmpty) {
              area = city;
            } else if (neighborhood.isNotEmpty) {
              area = neighborhood;
            } else {
              area = 'Nepal';
            }
            
            if (mounted && _currentLocationName != area) {
              setState(() => _currentLocationName = area);
              currentLocationName.value = area;
              return;
            }
          }
        }
      } catch (osmError) {
        debugPrint('OSM fallback geocoding error: $osmError');
      }

      if (mounted) {
        setState(() => _currentLocationName = 'Nepal');
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
                  'Villa',
                  'Spacious villas for all budgets',
                ),
                const SizedBox(height: 18),
                _buildSection(
                  2,
                  'Cottage',
                  'Cozy cottages & countryside stays',
                ),
                const SizedBox(height: 18),
                _buildSection(
                  3,
                  'Apartment',
                  'Modern apartments & flats',
                ),
                const SizedBox(height: 18),
                _buildSection(
                  4,
                  'BHK',
                  '1BHK · 2BHK · 3BHK homes',
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
      properties: _sectionProperties[index],
      isLoading: _sectionLoading[index],
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
    // Do NOT wipe cache on refresh. Keep existing data on screen to prevent flashy skeletons.
    final bool hasData = _sectionProperties.any((list) => list.isNotEmpty);
    if (mounted) {
      setState(() {
        for (int i = 0; i < 5; i++) {
          if (!hasData) {
            _sectionLoading[i] = true;
            _sectionProperties[i] = [];
          }
        }
      });
    }
    await _getCurrentLocation();
    await _initializeFutures();
  }
}
