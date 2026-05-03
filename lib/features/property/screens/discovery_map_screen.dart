import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/features/property/screens/property_details_screen.dart';
import 'package:geolocator/geolocator.dart';

import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

class DiscoveryMapScreen extends StatefulWidget {
  final LatLng? initialCenter;
  const DiscoveryMapScreen({super.key, this.initialCenter});

  @override
  State<DiscoveryMapScreen> createState() => _DiscoveryMapScreenState();
}

class _DiscoveryMapScreenState extends State<DiscoveryMapScreen> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  List<Property> _properties = [];
  bool _isLoading = true;
  LatLng _initialPosition = const LatLng(27.7172, 85.3240); // Kathmandu default
  LatLng? _userLocation;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialCenter != null) {
      _initialPosition = widget.initialCenter!;
      _isLoading = false; 
    }
    _loadUserLocationAndProperties();
  }

  Future<void> _loadUserLocationAndProperties() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _initialPosition = _userLocation!;
        });
        _mapController.move(_initialPosition, 13.0);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }

    await _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    final properties = await SupabaseService.getAllProperties();
    if (mounted) {
      setState(() {
        _properties = properties;
        _markers = _properties
            .where((p) => p.latitude != null && p.longitude != null)
            .map((p) => Marker(
                  point: LatLng(p.latitude!, p.longitude!),
                  width: 60,
                  height: 60,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _navigateToDetails(p),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                        border: Border.all(color: AppTheme.brandColor, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.home_rounded,
                          color: AppTheme.brandColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ))
            .toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _getRoute(LatLng destination) async {
    final start = _userLocation ?? const LatLng(27.7172, 85.3240);
    
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}?geometries=geojson';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          setState(() {
            _routePoints = coordinates.map((c) => LatLng(
              (c[1] as num).toDouble(), 
              (c[0] as num).toDouble()
            )).toList();
          });
          
          if (_routePoints.length > 1) {
            try {
              final bounds = LatLngBounds.fromPoints(_routePoints);
              double latDiff = (bounds.northEast.latitude - bounds.southWest.latitude).abs();
              double lonDiff = (bounds.northEast.longitude - bounds.southWest.longitude).abs();
              double maxDiff = latDiff > lonDiff ? latDiff : lonDiff;
              
              double zoom = 14.0;
              if (maxDiff > 0.01) zoom = 13.0;
              if (maxDiff > 0.05) zoom = 11.5;
              if (maxDiff > 0.1) zoom = 10.0;
              if (maxDiff > 0.5) zoom = 8.0;

              _mapController.move(bounds.center, zoom);
            } catch (e) {
              debugPrint('Error moving camera: $e');
              _mapController.move(_routePoints.first, 14.0);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting route: $e');
    }
  }

  void _navigateToDetails(Property property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyDetailsScreen(property: property),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'खोज्ना नक्सा · Discovery Map',
            style: GoogleFonts.mukta(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 13.0,
              minZoom: 3.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=xmsI10GyMKz5IT0XAIhv',
                userAgentPackageName: 'com.khozna.khozna',
                retinaMode: true,
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: AppTheme.brandColor.withOpacity(0.8),
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 45,
                  size: const Size(40, 40),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(50),
                  maxZoom: 15,
                  markers: [
                    ..._markers,
                    if (_userLocation != null)
                      Marker(
                        point: _userLocation!,
                        width: 25,
                        height: 25,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 12, spreadRadius: 4),
                            ],
                          ),
                        ),
                      ),
                  ],
                  builder: (context, markers) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppTheme.brandColor,
                        boxShadow: [
                          BoxShadow(color: AppTheme.brandColor.withOpacity(0.3), blurRadius: 10, spreadRadius: 2),
                        ],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          markers.length.toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.brandColor),
            ),
          
          // Bottom Property Carousel
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _properties.take(5).length,
                itemBuilder: (context, index) {
                  final p = _properties[index];
                  return GestureDetector(
                    onTap: () {
                      final destination = LatLng(p.latitude ?? 0, p.longitude ?? 0);
                      _mapController.move(destination, 15.0);
                      _getRoute(destination);
                    },
                    child: Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              p.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  p.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  p.location,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${p.price}/mo',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.brandColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () async {
          Position position = await Geolocator.getCurrentPosition();
          setState(() {
            _userLocation = LatLng(position.latitude, position.longitude);
          });
          _mapController.move(_userLocation!, 15.0);
        },
        child: const Icon(Icons.my_location, color: AppTheme.brandColor),
      ),
    );
  }
}
