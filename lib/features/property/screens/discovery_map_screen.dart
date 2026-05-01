import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/core/utils/map_style.dart';
import 'package:khozna/features/property/screens/property_details_screen.dart';
import 'package:geolocator/geolocator.dart';

class DiscoveryMapScreen extends StatefulWidget {
  final LatLng? initialCenter;
  const DiscoveryMapScreen({super.key, this.initialCenter});

  @override
  State<DiscoveryMapScreen> createState() => _DiscoveryMapScreenState();
}

class _DiscoveryMapScreenState extends State<DiscoveryMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<Property> _properties = [];
  bool _isLoading = true;
  LatLng _initialPosition = const LatLng(27.7172, 85.3240); // Kathmandu default

  @override
  void initState() {
    super.initState();
    if (widget.initialCenter != null) {
      _initialPosition = widget.initialCenter!;
      _isLoading = false; // We have a center, can show map
    }
    _loadUserLocationAndProperties();
  }

  Future<void> _loadUserLocationAndProperties() async {
    try {
      // Get user location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _initialPosition = LatLng(position.latitude, position.longitude);
        });
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
                  markerId: MarkerId(p.id),
                  position: LatLng(p.latitude!, p.longitude!),
                  infoWindow: InfoWindow(
                    title: p.title,
                    snippet: '₹${p.price}/mo',
                    onTap: () => _navigateToDetails(p),
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                ))
            .toSet();
        _isLoading = false;
      });
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
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.black, size: 18),
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
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 13,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController!.setMapStyle(KhoznaMapStyle.silver);
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.brandColor),
            ),
          
          // Bottom Property Carousel (Optional but Premium)
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
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(p.latitude ?? 0, p.longitude ?? 0),
                          15,
                        ),
                      );
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
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
          );
        },
        child: const Icon(Icons.my_location, color: AppTheme.brandColor),
      ),
    );
  }
}
