import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:khozna/core/utils/formatters.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:khozna/features/property/screens/booking_request_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:khozna/features/property/widgets/property_details_widgets.dart';
import 'package:khozna/widgets/khozna_image.dart';
import 'package:khozna/widgets/favourite_button.dart';

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
  Map<String, dynamic>? _ownerData;

  String get _currentUserId => Supabase.instance.client.auth.currentUser?.id ?? '';
  bool get _isMyProperty => (widget.property.ownerId == _currentUserId) && !widget.property.id.contains('demo');
  bool get _hasLocation => widget.property.latitude != null && widget.property.longitude != null;
  static const Color _airbnbGrey = Color(0xFF717171);

  late final List<String> displayImages;

  @override
  void initState() {
    super.initState();
    _isReserved = widget.property.status == 'booked' || widget.property.status == 'pending_approval';
    
    if (widget.property.ownerName != null || widget.property.ownerAvatar != null) {
      _ownerData = {
        'full_name': widget.property.ownerName,
        'avatar_url': widget.property.ownerAvatar,
        'is_verified': widget.property.isOwnerVerified ?? false,
      };
    }

    _fetchOwnerData();
    displayImages = widget.property.images.isNotEmpty 
        ? widget.property.images.map((url) => url.contains('cloudinary.com') ? url.replaceAll('/upload/', '/upload/q_auto,f_auto,w_1200,c_limit/') : url).toList()
        : [widget.property.imageUrl];
    
    _incrementViews();
    _userHasPendingBooking = bookedPropertiesStore.value.contains(widget.property.id);
    _checkUserBookingStatus();
  }

  Future<void> _incrementViews() async {
    if (widget.property.id.contains('demo') || _isMyProperty) return;
    try {
      await Supabase.instance.client.rpc('increment_property_views', params: {'property_id': widget.property.id});
    } catch (_) {}
  }

  Future<void> _checkUserBookingStatus() async {
    if (widget.property.id.contains('demo') || _currentUserId.isEmpty) return;
    try {
      final result = await Supabase.instance.client.from('bookings').select('id, status').eq('property_id', widget.property.id).eq('guest_id', _currentUserId).inFilter('status', ['pending', 'confirmed']).limit(1);
      if (mounted) setState(() => _userHasPendingBooking = result.isNotEmpty);
    } catch (_) {}
  }

  Future<void> _fetchOwnerData() async {
    if (widget.property.ownerId.isEmpty) return;
    try {
      final data = await Supabase.instance.client.from('profiles').select().eq('id', widget.property.ownerId).maybeSingle();
      if (mounted) setState(() => _ownerData = data);
    } catch (_) {}
  }

  Future<void> _openMap() async {
    if (_hasLocation) {
      final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${widget.property.latitude},${widget.property.longitude}');
      try { await launchUrl(url, mode: LaunchMode.externalApplication); } catch (e) { await launchUrl(url, mode: LaunchMode.inAppBrowserView); }
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
      extendBody: true,
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverCarousel(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeader(),
                const SizedBox(height: 24),
                const DetailSectionTitle(title: 'सुविधाहरू (Amenities)'),
                const SizedBox(height: 20), 
                _buildAmenityGrid(),
                const SizedBox(height: 44),
                const DetailSectionTitle(title: 'Description'),
                const SizedBox(height: 2),
                Text(widget.property.description ?? 'सानेपाको शान्त वातावरणमा अवस्थित यो कोठा विद्यार्थी वा सानो परिवारको लागि उपयुक्त छ।', style: GoogleFonts.inter(fontSize: 15, color: _airbnbGrey, height: 1.6)),
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
                  ...widget.property.houseRules.map((rule) => RuleRow(icon: Icons.info_outline, title: rule)),
                  const SizedBox(height: 24),
                ],
                SizedBox(height: _isMyProperty ? 40 : 140),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(context),
    );
  }

  Widget _buildSliverCarousel() {
    return SliverAppBar(
      expandedHeight: 380,
      backgroundColor: Colors.white,
      pinned: true,
      automaticallyImplyLeading: false,
      leading: Center(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B), size: 20),
          ),
        ),
      ),
      actions: [
        Center(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Share.share('Check out ${widget.property.title} on Khozna!');
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.ios_share_rounded, color: Color(0xFF1E293B), size: 18),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Center(
          child: FavouriteButton(propertyId: widget.property.id),
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentImageIndex = index),
              itemCount: displayImages.length,
              itemBuilder: (context, index) => Hero(
                tag: widget.property.id + (index == 0 ? '' : index.toString()),
                child: KhoznaImage(
                  imageUrl: displayImages[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (displayImages.length > 1) ...[
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GlassCircle(
                    icon: Icons.chevron_left_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    },
                    iconSize: 24,
                    size: 36,
                  ),
                ),
              ),
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GlassCircle(
                    icon: Icons.chevron_right_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    },
                    iconSize: 24,
                    size: 36,
                  ),
                ),
              ),
            ],
            Positioned(bottom: 42, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(displayImages.length, (index) => AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 3), height: 5, width: _currentImageIndex == index ? 22 : 5, decoration: BoxDecoration(color: _currentImageIndex == index ? Colors.white : Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(10)))))),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppTheme.brandColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(widget.property.category.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.brandColor, letterSpacing: 1))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF00C853).withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF00C853).withOpacity(0.3))), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.verified_rounded, color: Color(0xFF00C853), size: 14), const SizedBox(width: 4), Text('VERIFIED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF00C853), letterSpacing: 1))])),
        ]),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Expanded(child: Text(widget.property.title, style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFF1A1A2E), height: 1.1, letterSpacing: -1.0))),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            RichText(text: TextSpan(children: [TextSpan(text: 'Rs. ', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.brandColor)), TextSpan(text: PriceFormatter.format(widget.property.price), style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.brandColor, letterSpacing: -1))])),
            Text('भाडा/महिना', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          ]),
        ]),
        const SizedBox(height: 8),
        Row(children: [const Icon(Icons.location_on_outlined, color: AppTheme.brandColor, size: 18), const SizedBox(width: 6), Expanded(child: Text(widget.property.location, style: GoogleFonts.inter(fontSize: 16, color: AppTheme.brandColor, fontWeight: FontWeight.w600)))]),
      ],
    );
  }

  Widget _buildAmenityGrid() {
    final List<Widget> items = [];
    
    // Core Stats (Show only if valid)
    if (widget.property.bedrooms > 0) {
      items.add(PropertyStatItem(icon: Icons.bed_outlined, value: '${widget.property.bedrooms}', label: 'Beds', accentColor: AppTheme.brandColor));
    }
    if (widget.property.bathrooms > 0) {
      items.add(PropertyStatItem(icon: Icons.bathtub_outlined, value: '${widget.property.bathrooms}', label: 'Baths', accentColor: Colors.cyan));
    }
    if (widget.property.area != '0' && widget.property.area.isNotEmpty) {
      items.add(PropertyStatItem(icon: Icons.square_foot_outlined, value: widget.property.area, label: 'Area', accentColor: Colors.green));
    }
    if (widget.property.floor != 'N/A' && widget.property.floor.isNotEmpty) {
      items.add(PropertyStatItem(icon: Icons.layers_outlined, value: widget.property.floor, label: 'Floor', accentColor: Colors.orange));
    }

    // Fuzzy Matching for Amenities
    (IconData, String, Color) _getAmenityData(String feature) {
      final k = feature.toLowerCase().trim();
      if (k.contains('water')) return (Icons.water_drop_outlined, 'Water', Colors.lightBlue);
      if (k.contains('wifi') || k.contains('internet')) return (Icons.wifi, 'Internet', Colors.blue);
      if (k.contains('bike')) return (Icons.motorcycle_rounded, 'Bike Parking', Colors.blueGrey);
      if (k.contains('car')) return (Icons.directions_car_filled_rounded, 'Car Parking', Colors.indigo);
      if (k.contains('parking')) return (Icons.local_parking_rounded, 'Parking', Colors.indigo);
      if (k.contains('sunny')) return (Icons.wb_sunny_outlined, 'Sunny', Colors.amber);
      if (k.contains('cctv') || k.contains('security')) return (Icons.videocam_outlined, 'CCTV', Colors.redAccent);
      if (k.contains('balcony')) return (Icons.balcony_outlined, 'Balcony', Colors.teal);
      if (k.contains('hot water')) return (Icons.hot_tub_outlined, 'Hot Water', Colors.orangeAccent);
      if (k.contains('bath')) return (Icons.bathroom_outlined, 'Bath', Colors.cyan);
      if (k.contains('family')) return (Icons.family_restroom_outlined, 'Family', Colors.purple);
      if (k.contains('kitchen')) return (Icons.kitchen_outlined, 'Kitchen', Colors.orange);
      if (k.contains('ac') || k.contains('air cond')) return (Icons.ac_unit_rounded, 'AC', Colors.blueGrey);
      if (k.contains('furnish')) return (Icons.chair_rounded, 'Furnished', Colors.brown);
      if (k.contains('gym') || k.contains('fitness')) return (Icons.fitness_center_rounded, 'Gym', Colors.blueGrey);
      if (k.contains('pool')) return (Icons.pool_rounded, 'Pool', Colors.blue);
      if (k.contains('lift') || k.contains('elevat')) return (Icons.elevator_rounded, 'Lift', Colors.grey);
      
      String formatted = feature.replaceAll('_', ' ');
      if (formatted.isNotEmpty) {
        formatted = formatted[0].toUpperCase() + formatted.substring(1);
      }
      return (Icons.check_circle_outline_rounded, formatted, AppTheme.brandColor);
    }

    final combinedFeatures = {...widget.property.amenities, ...widget.property.houseRules};
    for (var feature in combinedFeatures) {
      final data = _getAmenityData(feature);
      items.add(PropertyStatItem(
        icon: data.$1,
        value: '',
        label: data.$2,
        accentColor: data.$3,
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFE2E8F0))),
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
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
      child: Column(children: [
        LocationInfoRow(icon: Icons.location_on_rounded, label: 'Area', value: widget.property.location),
        if (widget.property.landmark.isNotEmpty) ...[const Divider(height: 16), LocationInfoRow(icon: Icons.assistant_navigation, label: 'Landmark', value: widget.property.landmark)],
      ]),
    );
  }

  Widget _buildMapPreview() {
    return GestureDetector(
      onTap: _openMap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 200,
          decoration: BoxDecoration(color: Colors.grey[200], border: Border.all(color: Colors.black.withOpacity(0.05))),
          child: Stack(children: [
            Positioned.fill(
              child: _getStaticMapUrl().isEmpty 
                  ? Image.asset('assets/images/Map view.png', fit: BoxFit.cover) 
                  : KhoznaImage(imageUrl: _getStaticMapUrl(), fit: BoxFit.cover),
            ),
            Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(50)), child: Text("Open Maps", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.brandColor)))),
          ]),
        ),
      ),
    );
  }

  Widget _buildOwnerCard() {
    final String name = _ownerData?['full_name'] ?? widget.property.ownerName ?? 'Khozna User';
    final String avatar = _ownerData?['avatar_url'] ?? widget.property.ownerAvatar ?? '';
    final bool isVerified = _ownerData?['is_verified'] ?? widget.property.isOwnerVerified ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(children: [
        Row(children: [
          ClipOval(
            child: KhoznaImage(
              imageUrl: avatar,
              width: 60,
              height: 60,
              errorWidget: Container(color: Colors.grey[100], child: const Icon(Icons.person, color: Colors.grey)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Text(name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)), if (isVerified) const Icon(Icons.verified, size: 18, color: Colors.green)]),
            Text('Verified Owner', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
          ])),
        ]),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(width: 8),
                Text("Message Owner", style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: (widget.property.status == 'booked' || _userHasPendingBooking) 
                  ? null 
                  : () => Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (_) => BookingRequestScreen(
                          propertyId: widget.property.id, 
                          propertyTitle: widget.property.title, 
                          ownerId: widget.property.ownerId, 
                          ownerName: widget.property.ownerName ?? 'Owner'
                        )
                      )
                    ).then((v) => v == true ? setState(() => _userHasPendingBooking = true) : null), 
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor, 
                  foregroundColor: Colors.white, 
                  padding: const EdgeInsets.symmetric(vertical: 18), 
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ), 
                child: Text(
                  widget.property.status == 'booked' 
                    ? 'BOOKED' 
                    : (_userHasPendingBooking ? 'PENDING APPROVAL' : 'BOOK NOW'),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                )
              )
            ),
          ]
        )
      ),
    );
  }
}
