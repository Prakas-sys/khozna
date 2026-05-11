import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/utils/supabase_service.dart';

import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:khozna/features/profile/screens/owner_profile_screen.dart';
import 'package:khozna/core/utils/formatters.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/features/property/screens/visit_request_screen.dart';
import 'package:khozna/features/property/screens/discovery_map_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:khozna/features/property/widgets/property_details_widgets.dart';
import 'package:khozna/widgets/khozna_image.dart';
import 'package:khozna/widgets/favourite_button.dart';
import 'package:khozna/widgets/khozna_video_player.dart';
import 'package:khozna/core/utils/map_launcher.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final Property property;
  const PropertyDetailsScreen({super.key, required this.property});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool _isReserved = false;
  bool _userHasPendingBooking = false;
  bool _hasAcceptedVisit = false;
  String? _pendingBookingId;
  String _pendingBookingStatus = '';
  Map<String, dynamic>? _ownerData;

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';
  bool get _isMyProperty =>
      (widget.property.ownerId == _currentUserId) &&
      !widget.property.id.contains('demo');
  bool get _hasLocation =>
      widget.property.latitude != null && widget.property.longitude != null;
  static const Color _airbnbGrey = Color(0xFF717171);

  late final List<String> displayImages;

  @override
  void initState() {
    super.initState();
    _isReserved =
        widget.property.status == 'booked' ||
        widget.property.status == 'pending_approval';

    if (widget.property.ownerName != null ||
        widget.property.ownerAvatar != null) {
      _ownerData = {
        'full_name': widget.property.ownerName,
        'avatar_url': widget.property.ownerAvatar,
        'is_verified': widget.property.isOwnerVerified ?? false,
      };
    }

    _fetchOwnerData();
    displayImages = widget.property.images.isNotEmpty
        ? widget.property.images
              .map(
                (url) => url.contains('cloudinary.com')
                    ? url.replaceAll(
                        '/upload/',
                        '/upload/q_auto,f_auto,w_1200,c_limit/',
                      )
                    : url,
              )
              .toList()
        : [widget.property.imageUrl];

    _incrementViews();
    _updateBookingStatus();
  }

  Future<void> _incrementViews() async {
    if (widget.property.id.contains('demo') || _isMyProperty) return;
    try {
      await Supabase.instance.client.rpc(
        'increment_property_views',
        params: {'property_id': widget.property.id},
      );
    } catch (_) {}
  }

  Future<void> _updateBookingStatus() async {
    if (widget.property.id.contains('demo') || _currentUserId.isEmpty) return;
    try {
      final result = await Supabase.instance.client
          .from('bookings')
          .select('id, status')
          .eq('property_id', widget.property.id)
          .eq('guest_id', _currentUserId)
          .order('created_at', ascending: false)
          .limit(1);

      if (mounted) {
        setState(() {
          if (result.isNotEmpty) {
            final status = result[0]['status'];
            _pendingBookingId = result[0]['id'];
            _pendingBookingStatus = status;

            // Define which statuses count as "pending" or "active" for the bottom bar
            _userHasPendingBooking = [
              'pending_approval',
              'visit_accepted',
              'awaiting_payment',
              'paid',
              'confirmed',
            ].contains(status);

            // Define which statuses reveal the map
            _hasAcceptedVisit = [
              'visit_accepted',
              'awaiting_payment',
              'paid',
              'confirmed',
            ].contains(status);
          } else {
            _userHasPendingBooking = false;
            _pendingBookingId = null;
            _pendingBookingStatus = '';
            _hasAcceptedVisit = false;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchOwnerData() async {
    if (widget.property.ownerId.isEmpty) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', widget.property.ownerId)
          .maybeSingle();
      if (mounted) setState(() => _ownerData = data);
    } catch (_) {}
  }

  Future<void> _openMap() async {
    if (_hasLocation) {
      if (!_isMyProperty && !_hasAcceptedVisit) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'मालिकले भ्रमण स्वीकार गरेपछि मात्र दिशा देखिनेछ। (Directions unlock after visit is accepted)',
            ),
            backgroundColor: AppTheme.brandColor,
          ),
        );
        return;
      }
      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.map_outlined,
                  color: AppTheme.brandColor,
                ),
                title: const Text('View on Khozna Map'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DiscoveryMapScreen(
                        initialCenter: LatLng(
                          widget.property.latitude!,
                          widget.property.longitude!,
                        ),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.navigation_outlined,
                  color: Colors.green,
                ),
                title: const Text('Get Directions (Google Maps)'),
                onTap: () {
                  Navigator.pop(context);
                  MapLauncher.openMap(
                    widget.property.latitude!,
                    widget.property.longitude!,
                    widget.property.title,
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    }
  }

  String _getStaticMapUrl() {
    if (!_hasLocation) return '';
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty) return '';
    return 'https://maps.googleapis.com/api/staticmap?center=${widget.property.latitude},${widget.property.longitude}&zoom=15&size=800x400&maptype=roadmap&markers=color:0x3B82F6%7C${widget.property.latitude},${widget.property.longitude}&scale=2&key=$apiKey';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Property Details',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          FavouriteButton(propertyId: widget.property.id),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.share_rounded,
              color: Colors.black87,
              size: 22,
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              Share.share(
                'Check out this ${widget.property.category} on Khozna: ${widget.property.title}\nPrice: ₹${PriceFormatter.format(widget.property.price.toString())}\nLocation: ${widget.property.areaName}\n\nDownload Khozna to see more details!',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          _buildImageSection(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeader(),
                const SizedBox(height: 12),
                _buildQuickInfoRow(),
                const SizedBox(height: 32),
                const DetailSectionTitle(title: 'सुविधाहरू (Amenities)'),
                const SizedBox(height: 20),
                _buildAmenityGrid(),
                const SizedBox(height: 44),
                const DetailSectionTitle(title: 'Description'),
                const SizedBox(height: 2),
                Text(
                  widget.property.description ??
                      'सानेपाको शान्त वातावरणमा अवस्थित यो कोठा विद्यार्थी वा सानो परिवारको लागि उपयुक्त छ।',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: _airbnbGrey,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                const DetailSectionTitle(title: 'Location'),
                const SizedBox(height: 12),
                _buildLocationDetails(),
                const SizedBox(height: 12),
                _buildMapPreview(),
                const SizedBox(height: 24),
                if (!_isMyProperty) ...[
                  const DetailSectionTitle(title: 'घरबेटीको विवरण (Owner)'),
                  const SizedBox(height: 12),
                  _buildOwnerCard(),
                  const SizedBox(height: 24),
                ],
                if (widget.property.houseRules.isNotEmpty) ...[
                  const DetailSectionTitle(title: 'नियमहरू (House Rules)'),
                  const SizedBox(height: 12),
                  ...widget.property.houseRules.map((rule) {
                    final data = _getFeatureData(rule);
                    return RuleRow(
                      icon: data.$1,
                      title: data.$2,
                    );
                  }),
                  const SizedBox(height: 24),
                ],
                const SizedBox(height: 32),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _showReportDialog(),
                    icon: const Icon(
                      Icons.report_gmailerrorred_rounded,
                      color: Colors.grey,
                      size: 18,
                    ),
                    label: Text(
                      'Report this listing',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: _isMyProperty ? 40 : 140),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isMyProperty
          ? null
          : _buildBottomActionBar(context),
    );
  }

  Widget _buildImageSection() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          SizedBox(
            height: 380,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentImageIndex = index),
                  itemCount: widget.property.videoUrl.isNotEmpty
                      ? displayImages.length + 1
                      : displayImages.length,
                  itemBuilder: (context, index) {
                    // Check if this index should show a video
                    if (index == 0 && widget.property.videoUrl.isNotEmpty) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: KhoznaVideoPlayer(
                            videoUrl: widget.property.videoUrl,
                            thumbnailUrl: widget.property.imageUrl,
                            autoPlay: false, // Don't autoplay in details
                          ),
                        ),
                      );
                    }

                    // Adjust index if video was inserted at 0
                    final imageIndex = widget.property.videoUrl.isNotEmpty
                        ? index - 1
                        : index;

                    return Hero(
                      tag:
                          widget.property.id +
                          (imageIndex == 0 ? '' : imageIndex.toString()),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: KhoznaImage(
                            imageUrl: displayImages[imageIndex],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if ((widget.property.videoUrl.isNotEmpty
                        ? displayImages.length + 1
                        : displayImages.length) >
                    1) ...[
                  Positioned(
                    left: 20,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GlassCircle(
                        icon: Icons.chevron_left_rounded,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        iconSize: 16,
                        size: 26,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GlassCircle(
                        icon: Icons.chevron_right_rounded,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        iconSize: 16,
                        size: 26,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        (widget.property.videoUrl.isNotEmpty
                            ? displayImages.length + 1
                            : displayImages.length),
                        (index) => Container(
                          width: _currentImageIndex == index ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentImageIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildQuickInfoRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickStatItem(
            icon: Icons.bed_outlined,
            label: 'Bed',
            value: widget.property.bedrooms.toString(),
            color: AppTheme.brandColor,
            bgColor: AppTheme.brandColor.withOpacity(0.08),
          ),
          _buildQuickStatItem(
            icon: Icons.layers_outlined,
            label: 'Floor',
            value: widget.property.floor,
            color: Colors.orange,
            bgColor: Colors.orange.withOpacity(0.08),
          ),
          _buildQuickStatItem(
            icon: Icons.square_foot_outlined,
            label: 'Length',
            value: widget.property.area,
            color: Colors.green,
            bgColor: Colors.green.withOpacity(0.08),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.brandColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.property.category.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandColor,
                  letterSpacing: 1,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF00C853).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF00C853),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'VERIFIED',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF00C853),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.property.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E),
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.property.priceNight > 0) ...[
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '₹',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.brandColor,
                          ),
                        ),
                        TextSpan(
                          text: PriceFormatter.format(
                            widget.property.priceNight.toString(),
                          ),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.brandColor,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'प्रति रात (Per Night)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else ...[
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '₹',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.brandColor,
                          ),
                        ),
                        TextSpan(
                          text: PriceFormatter.format(widget.property.price),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.brandColor,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'भाडा/महिना (Per Month)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: AppTheme.brandColor,
              size: 18,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.property.location,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppTheme.brandColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmenityGrid() {
    final List<Widget> items = [];

    // Core Stats
    if (widget.property.bathrooms > 0) {
      items.add(
        PropertyStatItem(
          icon: Icons.bathtub_outlined,
          value: '${widget.property.bathrooms}',
          label: 'Baths',
          accentColor: Colors.cyan,
        ),
      );
    }

  (IconData, String, Color) _getFeatureData(String feature) {
    final k = feature.toLowerCase().trim();
    if (k.contains('water'))
      return (Icons.water_drop_outlined, 'Water', Colors.lightBlue);
    if (k.contains('wifi') || k.contains('internet'))
      return (Icons.wifi, 'Internet', Colors.blue);
    if (k.contains('bike'))
      return (Icons.motorcycle_rounded, 'Bike Parking', Colors.blueGrey);
    if (k.contains('car'))
      return (Icons.directions_car_filled_rounded, 'Car Parking', Colors.indigo);
    if (k.contains('parking'))
      return (Icons.local_parking_rounded, 'Parking', Colors.indigo);
    if (k.contains('sunny'))
      return (Icons.wb_sunny_outlined, 'Sunny', Colors.amber);
    if (k.contains('cctv') || k.contains('security'))
      return (Icons.videocam_outlined, 'CCTV', Colors.redAccent);
    if (k.contains('balcony'))
      return (Icons.balcony_outlined, 'Balcony', Colors.teal);
    if (k.contains('hot water'))
      return (Icons.hot_tub_outlined, 'Hot Water', Colors.orangeAccent);
    if (k.contains('bath'))
      return (Icons.bathroom_outlined, 'Bath', Colors.cyan);
    if (k.contains('family'))
      return (Icons.family_restroom_outlined, 'Family', Colors.purple);
    if (k.contains('kitchen'))
      return (Icons.kitchen_outlined, 'Kitchen', Colors.orange);
    if (k.contains('ac') || k.contains('air cond'))
      return (Icons.ac_unit_rounded, 'AC', Colors.blueGrey);
    if (k.contains('furnish'))
      return (Icons.chair_rounded, 'Furnished', Colors.brown);
    if (k.contains('gym') || k.contains('fitness'))
      return (Icons.fitness_center_rounded, 'Gym', Colors.blueGrey);
    if (k.contains('pool')) return (Icons.pool_rounded, 'Pool', Colors.blue);
    if (k.contains('lift') || k.contains('elevat'))
      return (Icons.elevator_rounded, 'Lift', Colors.grey);

    // House Rule Specifics
    if (k.contains('smoke') || k.contains('smoking'))
      return (Icons.smoke_free_rounded, 'No Smoking', Colors.redAccent);
    if (k.contains('pet'))
      return (Icons.pets_rounded, 'Pets Allowed', Colors.brown);
    if (k.contains('party') || k.contains('event'))
      return (Icons.celebration_rounded, 'No Parties', Colors.purpleAccent);
    if (k.contains('couple'))
      return (Icons.people_outline_rounded, 'Couples Allowed', Colors.pinkAccent);
    if (k.contains('girl'))
      return (Icons.woman_rounded, 'Girls Only', Colors.pink);
    if (k.contains('boy')) return (Icons.man_rounded, 'Boys Only', Colors.indigo);

    String formatted = feature.replaceAll('_', ' ');
    if (formatted.isNotEmpty) {
      formatted = formatted[0].toUpperCase() + formatted.substring(1);
    }
    return (
      Icons.check_circle_outline_rounded,
      formatted,
      AppTheme.brandColor,
    );
  }

    final Map<IconData, String> uniqueItems = {};
    for (var feature in widget.property.amenities) {
      final data = _getFeatureData(feature);
      // Only keep the first occurrence of each icon type
      if (!uniqueItems.containsKey(data.$1)) {
        uniqueItems[data.$1] = data.$2;
      }
    }

    for (var entry in uniqueItems.entries) {
      items.add(
        PropertyStatItem(
          icon: entry.key,
          value: '',
          label: entry.value,
          accentColor: AppTheme.brandColor,
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: items.map((e) => SizedBox(width: 80, child: e)).toList(),
      ),
    );
  }

  Widget _buildLocationDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          LocationInfoRow(
            icon: Icons.location_on_rounded,
            label: 'Area',
            value: widget.property.location,
          ),
          if (widget.property.landmark.isNotEmpty) ...[
            const Divider(height: 16),
            LocationInfoRow(
              icon: Icons.assistant_navigation,
              label: 'Landmark',
              value: widget.property.landmark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    // If owner or already has accepted visit — show real map
    if (_isMyProperty || _hasAcceptedVisit) {
      return GestureDetector(
        onTap: _openMap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: _getStaticMapUrl().isEmpty
                      ? Image.asset(
                          'assets/images/Map view.png',
                          fit: BoxFit.cover,
                        )
                      : KhoznaImage(
                          imageUrl: _getStaticMapUrl(),
                          fit: BoxFit.cover,
                        ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Open Maps',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Locked state — approximate area only
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Stack(
        children: [
          // Blurred fake map background
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Image.asset(
                  'assets/images/Map view.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Lock overlay
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: AppTheme.brandColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Approximate Area: ${widget.property.areaName ?? "Kathmandu"}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Exact location reveals after visit is accepted',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyBanner() {
    final bool isVerified =
        _ownerData?['is_verified'] ?? widget.property.isOwnerVerified ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isVerified
            ? Colors.blue.withOpacity(0.05)
            : Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVerified
              ? Colors.blue.withOpacity(0.1)
              : Colors.orange.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isVerified
                    ? Icons.security_rounded
                    : Icons.warning_amber_rounded,
                color: isVerified ? Colors.blue[700] : Colors.orange[800],
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isVerified
                      ? 'Khozna Safety Tip'
                      : 'Caution: Unverified Owner',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isVerified ? Colors.blue[900] : Colors.orange[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ठगीबाट बच्न घर नहेरी अग्रिम पैसा नपठाउनुहोस्। (Never pay advance money before visiting the property in person.)',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isVerified ? Colors.blue[800] : Colors.orange[900],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 32,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Property (रिपोर्ट गर्नुहोस्)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Why are you reporting this? (तपाईं किन रिपोर्ट गर्दै हुनुहुन्छ?)',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildReportOption('Scam or Fraud (ठगी)', Icons.money_off_rounded),
            _buildReportOption(
              'Wrong Information (गलत विवरण)',
              Icons.edit_off_rounded,
            ),
            _buildReportOption(
              'Owner Misbehavior (राम्रो व्यवहार छैन)',
              Icons.person_off_rounded,
            ),
            _buildReportOption(
              'Duplicate Listing (दोहोरिएको विज्ञापन)',
              Icons.copy_rounded,
            ),
            const SizedBox(height: 24),
            Text(
              'False reports will result in a permanent ban.',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.red[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Thank you. Our team will investigate this within 24 hours.',
            ),
            backgroundColor: AppTheme.brandColor,
          ),
        );
      },
    );
  }

  Widget _buildOwnerCard() {
    final String name =
        _ownerData?['full_name'] ?? widget.property.ownerName ?? 'Khozna User';
    final String avatar =
        _ownerData?['avatar_url'] ?? widget.property.ownerAvatar ?? '';
    final bool isVerified =
        _ownerData?['is_verified'] ?? widget.property.isOwnerVerified ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OwnerProfileScreen(
                    ownerId: widget.property.ownerId,
                    name: name,
                    avatar: avatar,
                    isVerified: isVerified,
                    location: widget.property.ownerLocation,
                    totalListings: 1, // At least this one
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                ClipOval(
                  child: KhoznaImage(
                    imageUrl: avatar,
                    width: 60,
                    height: 60,
                    errorWidget: Container(
                      color: Colors.grey[100],
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isVerified)
                            const Icon(
                              Icons.verified,
                              size: 18,
                              color: Colors.green,
                            ),
                        ],
                      ),
                      Text(
                        'Verified Owner',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!_isMyProperty) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => chat_page.ChatScreen(
                      ownerId: widget.property.ownerId,
                      name: name,
                      avatar: avatar,
                      isVerified: isVerified,
                      online: true,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Color(0xFFE0E0E0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: SvgPicture.asset(
                        'assets/icons/message.svg',
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Message Owner",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Side: Price Details
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '₹',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text:
                              '${PriceFormatter.format((widget.property.priceNight > 0 ? widget.property.priceNight : widget.property.price).toString())} ',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: widget.property.priceNight > 0
                              ? '/night'
                              : '/mo',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '✓ Meet First, Pay Later',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF00C853),
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Right Side: Action Button(s)
            if (!_isMyProperty)
              Expanded(
                flex: 2,
                child: _buildBottomActionButtons(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionButtons(BuildContext context) {
    if (widget.property.status == 'booked') {
      return _buildDisabledButton('Booked');
    }

    if (_userHasPendingBooking) {
      if (_pendingBookingStatus == 'pending_approval') {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDisabledButton('Pending Approval'),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _cancelRequest,
              child: Text(
                'Cancel Request',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.red[400],
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        );
      }

      return _buildDisabledButton(
        _pendingBookingStatus == 'visit_accepted'
            ? 'Visit Accepted'
            : 'Visit Scheduled',
      );
    }

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VisitRequestScreen(property: widget.property),
          ),
        ).then((v) => v == true ? _updateBookingStatus() : null),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.brandColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          'SCHEDULE VISIT',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledButton(String label) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Colors.grey[500],
        ),
      ),
    );
  }


  Future<void> _cancelRequest() async {
    if (_pendingBookingId == null) return;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text('Are you sure you want to cancel this visit request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.cancelVisit(_pendingBookingId!);
        await BookingRepository.fetchBookedPropertyIds(); // Update global store
        _updateBookingStatus();
      } catch (_) {}
    }
  }

  (IconData, String) _getFeatureData(String feature) {
    final f = feature.toLowerCase();
    if (f.contains('wifi') || f.contains('internet'))
      return (Icons.wifi_rounded, 'Free Wi-Fi');
    if (f.contains('park') || f.contains('garage'))
      return (Icons.local_parking_rounded, 'Parking');
    if (f.contains('water') || f.contains('shower'))
      return (Icons.water_drop_rounded, '24/7 Water');
    if (f.contains('power') || f.contains('backup'))
      return (Icons.battery_charging_full_rounded, 'Power Backup');
    if (f.contains('student'))
      return (Icons.school_rounded, 'Student Friendly');
    if (f.contains('family')) return (Icons.family_restroom_rounded, 'Families');
    if (f.contains('no smok')) return (Icons.smoke_free_rounded, 'No Smoking');
    if (f.contains('pet')) return (Icons.pets_rounded, 'Pets Allowed');
    if (f.contains('security') || f.contains('cctv'))
      return (Icons.security_rounded, 'Security');

    // Default
    return (Icons.check_circle_outline_rounded, feature);
  }
}
