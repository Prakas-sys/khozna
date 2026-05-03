import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/profile/screens/owner_profile_screen.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:khozna/features/property/screens/property_details_screen.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/widgets/khozna_image.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();
  bool isImageView = true;
  List<Property> reels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReels();
  }

  Future<void> _fetchReels() async {
    try {
      debugPrint('ReelsScreen: Starting fetch...');
      final data = await Supabase.instance.client
          .from('properties')
          .select('*, profiles:owner_id(full_name, avatar_url, kyc_status)')
          .order('created_at', ascending: false)
          .limit(30);

      debugPrint('ReelsScreen: Fetched ${data.length} items');
      
      if (mounted) {
        setState(() {
          reels = (data as List).map((p) => Property.fromMap(p)).toList();
          _isLoading = false;
        });
        debugPrint('ReelsScreen: Mapped ${reels.length} properties');
      }
    } catch (e) {
      debugPrint('ReelsScreen fetch error: $e');
      // Fallback: fetch without join to ensure we at least show something
      try {
        final data = await Supabase.instance.client
            .from('properties')
            .select('*')
            .order('created_at', ascending: false)
            .limit(30);
        
        debugPrint('ReelsScreen fallback: Fetched ${data.length} items');

        if (mounted) {
          setState(() {
            reels = (data as List).map((p) => Property.fromMap(p)).toList();
            _isLoading = false;
          });
        }
      } catch (e2) {
        debugPrint('ReelsScreen fallback error: $e2');
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandColor))
          : reels.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.video_library_outlined, color: Colors.white38, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'अहिले कुनै Reel छैन।\n(No reels yet)',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.mukta(color: Colors.white60, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: _fetchReels,
                      color: AppTheme.brandColor,
                      backgroundColor: Colors.white,
                      child: PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.vertical,
                        physics: const BouncingScrollPhysics(),
                        itemCount: reels.length,
                        itemBuilder: (context, index) {
                          return _buildReelItem(reels[index]);
                        },
                      ),
                    ),
                    // Top Toggle (Photos/Videos)
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildSegmentButton(
                                      title: 'Photos',
                                      icon: Icons.image_rounded,
                                      isSelected: isImageView,
                                      onTap: () => setState(() => isImageView = true),
                                    ),
                                    _buildSegmentButton(
                                      title: 'Videos',
                                      icon: Icons.play_circle_fill,
                                      isSelected: !isImageView,
                                      onTap: () => setState(() => isImageView = false),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.black87 : Colors.white70),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.black87 : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReelItem(Property property) {
    final List<String> allImages = property.images.isNotEmpty
        ? property.images
        : (property.imageUrl.isNotEmpty ? [property.imageUrl] : []);

    return Stack(
      fit: StackFit.expand,
      children: [
        // BACKGROUND CONTENT
        isImageView
            ? _buildImageCarousel(allImages)
            : _buildVideoPlaceholder(property),

        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.5),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.85),
              ],
              stops: const [0.0, 0.2, 0.55, 1.0],
            ),
          ),
        ),

        // Bottom info overlay
        Positioned(
          left: 12,
          right: 12,
          bottom: 95,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Owner row
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OwnerProfileScreen(
                            ownerId: property.ownerId,
                            name: property.ownerName,
                            avatar: property.ownerAvatar,
                            location: property.location,
                            totalListings: 1,
                          ),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.brandColor, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[200],
                          child: ClipOval(
                            child: KhoznaImage(
                              imageUrl: property.ownerAvatar,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                property.ownerName.isNotEmpty ? property.ownerName : 'Owner',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  shadows: [const Shadow(color: Colors.black54, blurRadius: 6)],
                                ),
                              ),
                              if (property.isOwnerVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, color: AppTheme.brandColor, size: 14),
                              ],
                            ],
                          ),
                          Text(
                            property.category.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Image count badge (Photos mode only)
                    if (isImageView && allImages.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.photo_library_rounded, color: Colors.white70, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '${allImages.length}',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Main glass info card
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // LEFT: Property Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                property.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: AppTheme.brandColor, size: 13),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      property.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (property.bedrooms > 0) ...[
                                    const Icon(Icons.bed_outlined, color: Colors.white54, size: 13),
                                    const SizedBox(width: 3),
                                    Text('${property.bedrooms}', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                                    const SizedBox(width: 8),
                                  ],
                                  if (property.bathrooms > 0) ...[
                                    const Icon(Icons.bathtub_outlined, color: Colors.white54, size: 13),
                                    const SizedBox(width: 3),
                                    Text('${property.bathrooms}', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Rs. ',
                                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.brandColor),
                                    ),
                                    TextSpan(
                                      text: '${property.price} /mo',
                                      style: GoogleFonts.inter(color: AppTheme.brandColor, fontWeight: FontWeight.w900, fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // RIGHT: VISIT & CHAT BUTTONS
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: property)));
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.directions_walk_rounded, color: Colors.black, size: 16),
                                    const SizedBox(width: 6),
                                    Text('VISIT', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => chat_page.ChatScreen(
                                    ownerId: property.ownerId,
                                    name: property.ownerName,
                                    avatar: property.ownerAvatar,
                                    online: true,
                                  ),
                                ));
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(color: AppTheme.brandColor, borderRadius: BorderRadius.circular(30)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/message.svg',
                                      width: 14,
                                      height: 14,
                                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                    ),
                                    const SizedBox(width: 6),
                                    Text('CHAT', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    if (images.isEmpty) {
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home_work_rounded, size: 80, color: Colors.white24),
              const SizedBox(height: 16),
              Text('No photos available', style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
            ],
          ),
        ),
      );
    }
    if (images.length == 1) {
      return KhoznaImage(imageUrl: images[0], width: double.infinity, height: double.infinity, fit: BoxFit.cover);
    }
    return _MultiImageCarousel(images: images);
  }

  Widget _buildVideoPlaceholder(Property property) {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (property.imageUrl.isNotEmpty)
            Opacity(
              opacity: 0.3,
              child: KhoznaImage(
                imageUrl: property.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 56),
                ),
                const SizedBox(height: 16),
                Text('Video Coming Soon', style: GoogleFonts.inter(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Horizontal image carousel for multiple property photos
class _MultiImageCarousel extends StatefulWidget {
  final List<String> images;
  const _MultiImageCarousel({required this.images});

  @override
  State<_MultiImageCarousel> createState() => _MultiImageCarouselState();
}

class _MultiImageCarouselState extends State<_MultiImageCarousel> {
  final PageController _ctrl = PageController();
  int _current = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _ctrl,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (context, i) => KhoznaImage(
            imageUrl: widget.images[i],
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        // Horizontal dot indicators at the bottom center
        Positioned(
          bottom: 260, // Positioned above the info card
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _current == i ? 12 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _current == i ? Colors.white : Colors.white38,
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
