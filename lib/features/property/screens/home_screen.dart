import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
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
import '../widgets/home_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final List<Future<List<Property>>> _sectionFutures = List.generate(5, (index) => Future.value(<Property>[]));
  Position? _currentPosition;
  String _currentLocationName = "Kathmandu, Nepal";

  @override
  void initState() {
    super.initState();
    _initializeFutures();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final diskCache = await OfflineStorage.loadHomeCache();
    if (diskCache.isNotEmpty) {
      homeSectionCache.value = diskCache;
      if (mounted) setState(() {});
    }
    await _getCurrentLocation();
    if (mounted) setState(() => _initializeFutures());
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
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
      try {
        List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          geo.Placemark place = placemarks.first;
          macro = place.locality ?? place.subAdministrativeArea ?? '';
          micro = (place.street ?? place.name ?? place.subLocality ?? '').replaceAll('Road', '').replaceAll('Street', '').trim();
        }
      } catch (_) {}

      if (micro.isEmpty || micro == macro) {
        final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1');
        final response = await http.get(url, headers: {'User-Agent': 'KhoznaApp/1.0'});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final displayName = data['display_name']?.toString() ?? '';
          if (displayName.isNotEmpty) {
            List<String> parts = displayName.split(',').map((e) => e.trim()).toList();
            if (parts.isNotEmpty) {
              micro = parts[0];
              if (parts.length > 1 && macro.isEmpty) macro = parts[1];
            }
          }
        }
      }

      // Filter out Plus Codes (e.g., "M7GG+Q6") which often appear in place.name or place.street
      bool isPlusCode(String s) => s.contains('+') && s.length <= 12;
      
      if (isPlusCode(micro)) micro = '';
      if (isPlusCode(macro)) macro = '';

      String area = (micro.isNotEmpty && macro.isNotEmpty && micro.toLowerCase() != macro.toLowerCase()) ? '$macro, $micro' : (macro.isNotEmpty ? macro : micro);
      if (area.trim().isEmpty) area = 'Kathmandu, Nepal';
      if (mounted) setState(() => _currentLocationName = area);
    } catch (e) {
      debugPrint("Error fetching area name: $e");
    }
  }

  void _initializeFutures() {
    for (int i = 0; i < 5; i++) {
      _sectionFutures[i] = PropertyRepository.getSectionProperties(
        index: i,
        lat: _currentPosition?.latitude,
        lng: _currentPosition?.longitude,
      );
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
            onNotificationTap: () {
              notificationBadgeCount.value = 0;
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await OfflineStorage.clearHomeCache();
          homeSectionCache.value = {};
          await _getCurrentLocation();
          setState(() => _initializeFutures());
          await Future.wait(_sectionFutures);
        },
        color: AppTheme.brandColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const HomeHeroSection(),
                            const SizedBox(height: 24),
              HomeSearchBar(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                onVoiceResult: (text) {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen(initialQuery: text)));
                },
              ),
                            const SizedBox(height: 32),
              _buildSection(0, 'Near You', 'Properties in your current area'),
              const SizedBox(height: 18),
              _buildSection(2, 'Student Specials', 'Budget rooms near colleges'),
              const SizedBox(height: 18),
              _buildSection(3, 'Family Flats', 'Spacious homes for everyone'),
              const SizedBox(height: 18),
              _buildSection(4, 'Premium Collections', 'Luxurious & Executive stays'),
              const SizedBox(height: 24),
            ],
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
      onViewAll: (t, s) => Navigator.push(context, MaterialPageRoute(builder: (_) => FilterResultsScreen(location: t, priceRange: s))),
    );
  }

  Future<void> _handleLocationTap() async {
    HapticFeedback.lightImpact();
    if (_currentPosition != null) {
      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;
      final label = Uri.encodeComponent(_currentLocationName);
      final gMapsUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
      if (await canLaunchUrl(gMapsUri)) {
        await launchUrl(gMapsUri);
      } else {
        await launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'), mode: LaunchMode.externalApplication);
      }
    }
  }
}
