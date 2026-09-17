import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/features/property/screens/property_details_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:khozna/core/utils/map_launcher.dart';

class DiscoveryMapScreen extends StatefulWidget {
  final LatLng? initialCenter;
  const DiscoveryMapScreen({super.key, this.initialCenter});

  @override
  State<DiscoveryMapScreen> createState() => _DiscoveryMapScreenState();
}

class _DiscoveryMapScreenState extends State<DiscoveryMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final PageController _pageController;
  List<Property> _properties = [];
  bool _isLoading = true;
  LatLng _initialPosition = const LatLng(27.7172, 85.3240); // Kathmandu default
  LatLng? _userLocation;
  Property? _selectedProperty;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    if (widget.initialCenter != null) {
      _initialPosition = widget.initialCenter!;
      _isLoading = false;
    }
    _loadUserLocationAndProperties();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocationAndProperties() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _initialPosition = _userLocation!;
        });
        _animatedMapMove(_initialPosition, 13.5);
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
        if (_properties.isNotEmpty) {
          _selectedProperty = _properties.first;
        }
        _isLoading = false;
      });

      if (_selectedProperty != null &&
          _selectedProperty!.latitude != null &&
          _selectedProperty!.longitude != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _animatedMapMove(
              LatLng(_selectedProperty!.latitude!, _selectedProperty!.longitude!),
              14.5,
            );
          }
        });
      }
    }
  }

  void _selectProperty(Property p) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedProperty = p;
    });

    final index = _properties.indexWhere((item) => item.id == p.id);
    if (index != -1 && _pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    if (p.latitude != null && p.longitude != null) {
      _animatedMapMove(LatLng(p.latitude!, p.longitude!), 14.5);
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
        begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(
        begin: _mapController.camera.zoom, end: destZoom);

    final animationController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    
    final animation = CurvedAnimation(
        parent: animationController, curve: Curves.fastOutSlowIn);

    animationController.addListener(() {
      if (mounted) {
        _mapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation),
        );
      }
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        animationController.dispose();
      }
    });

    animationController.forward();
  }

  List<Marker> _buildMapMarkers() {
    return _properties
        .where((p) => p.latitude != null && p.longitude != null)
        .map((p) {
          final isSelected = _selectedProperty?.id == p.id;
          final price = p.priceNight > 0
              ? p.priceNight
              : (double.tryParse(p.price) ?? 0);
          
          return Marker(
            point: LatLng(p.latitude!, p.longitude!),
            width: isSelected ? 95 : 85,
            height: isSelected ? 44 : 40,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _selectProperty(p),
              child: AnimatedScale(
                scale: isSelected ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.brandColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isSelected ? 0.22 : 0.12),
                        blurRadius: isSelected ? 12 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.grey.shade300,
                      width: isSelected ? 2.5 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/vector of ruppes.svg',
                          width: 10,
                          height: 10,
                          colorFilter: ColorFilter.mode(
                            isSelected ? Colors.white : Colors.black87,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          price > 999
                              ? '${(price / 1000).toStringAsFixed(0)}K'
                              : price.toInt().toString(),
                          style: GoogleFonts.plusJakartaSans(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w900,
                            fontSize: isSelected ? 13.5 : 12.5,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        })
        .toList();
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
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black,
                size: 18,
              ),
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
            'Discovery Map',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w800,
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
                urlTemplate:
                    'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=xmsI10GyMKz5IT0XAIhv',
                userAgentPackageName: 'com.khozna.khozna',
              ),
              MarkerLayer(
                markers: [
                  ..._buildMapMarkers(),
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
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.brandColor),
            ),

          // Bottom Property Carousel
          if (_properties.isNotEmpty)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 135,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _properties.length,
                  onPageChanged: (index) {
                    if (index >= 0 && index < _properties.length) {
                      final p = _properties[index];
                      setState(() {
                        _selectedProperty = p;
                      });
                      if (p.latitude != null && p.longitude != null) {
                        _animatedMapMove(LatLng(p.latitude!, p.longitude!), 14.5);
                      }
                    }
                  },
                  itemBuilder: (context, index) {
                    final p = _properties[index];
                    final isSelected = _selectedProperty?.id == p.id;

                    return GestureDetector(
                      onTap: () => _navigateToDetails(p),
                      child: AnimatedScale(
                        scale: isSelected ? 1.0 : 0.96,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected ? AppTheme.brandColor.withOpacity(0.5) : Colors.transparent,
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isSelected ? 0.12 : 0.06),
                                blurRadius: isSelected ? 18 : 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Left Thumbnail
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      p.imageUrl,
                                      width: 95,
                                      height: 95,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  if (p.isVerified)
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: AppTheme.brandColor,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.verified, color: Colors.white, size: 9),
                                            const SizedBox(width: 2),
                                            Text(
                                              'VERIFIED',
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 6.5,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              // Right Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      p.category.toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey[500],
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      p.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${p.bedrooms} Beds • ${p.bathrooms} Baths • ${p.area} sqft',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SvgPicture.asset(
                                                'assets/icons/vector of ruppes.svg',
                                                width: 10,
                                                height: 10,
                                                colorFilter: const ColorFilter.mode(
                                                  AppTheme.brandColor,
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                              const SizedBox(width: 2.5),
                                              Flexible(
                                                child: Text(
                                                  p.priceNight > 0
                                                      ? '${p.priceNight.toInt()}/night'
                                                      : '${(p.priceMonth > 0 ? p.priceMonth : (double.tryParse(p.price) ?? 0)).toInt()}/mo',
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontWeight: FontWeight.w900,
                                                    color: AppTheme.brandColor,
                                                    fontSize: 13.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            if (p.latitude != null && p.longitude != null) {
                                              HapticFeedback.lightImpact();
                                              MapLauncher.openMap(
                                                p.latitude!,
                                                p.longitude!,
                                                p.title,
                                              );
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                              color: AppTheme.brandColor.withOpacity(0.08),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.directions,
                                              color: AppTheme.brandColor,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 145), // Position FAB above the property carousel
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          onPressed: () async {
            HapticFeedback.mediumImpact();
            try {
              Position position = await Geolocator.getCurrentPosition();
              setState(() {
                _userLocation = LatLng(position.latitude, position.longitude);
              });
              _animatedMapMove(_userLocation!, 15.0);
            } catch (e) {
              debugPrint('Error locating user: $e');
            }
          },
          child: const Icon(Icons.my_location, color: AppTheme.brandColor),
        ),
      ),
    );
  }
}
