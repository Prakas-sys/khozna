import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:khozna/features/property/screens/property_details_screen.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/widgets/khozna_image.dart';
import 'package:khozna/widgets/khozna_video_player.dart';
import 'package:khozna/core/utils/formatters.dart';


import 'package:khozna/core/utils/app_notifiers.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();
  bool isImageView = true;
  bool isAutoScrollEnabled = false;
  List<Property> reels = [];
  bool _isLoading = true;

  List<Property> get displayReels => isImageView
      ? reels
      : reels.where((p) => p.videoUrl.isNotEmpty).toList();

  void _scrollToNext() {
    if (_pageController.hasClients) {
      final int nextPage = _pageController.page!.round() + 1;
      if (nextPage < reels.length) {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchReels();
    refreshTrigger.addListener(_onGlobalRefresh);
  }

  void _onGlobalRefresh() {
    if (mounted) {
      debugPrint('ReelsScreen: Global refresh triggered, refetching reels...');
      _fetchReels();
    }
  }

  Future<void> _fetchReels() async {
    try {
      debugPrint('ReelsScreen: Starting fetch...');
      final data = await Supabase.instance.client
          .from('properties')
          .select(
            'id, owner_id, title, area_name, price, price_night, price_month, images, video_url, category, status, bedrooms, bathrooms, profiles:owner_id(full_name, avatar_url, kyc_status, area_name)',
          )
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
    refreshTrigger.removeListener(_onGlobalRefresh);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.brandColor),
            )
          : displayReels.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.video_library_outlined,
                    color: Colors.white38,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'अहिले कुनै Reel छैन।\n(No reels yet)',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.mukta(
                      color: Colors.white60,
                      fontSize: 16,
                    ),
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
                    itemCount: displayReels.length,
                    itemBuilder: (context, index) {
                      return _buildReelItem(displayReels[index]);
                    },
                  ),
                ),
                // Top Toggle (Photos/Videos)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 48), // Balance for Menu icon
                          ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
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
                                      onTap: () {
                                        setState(() => isImageView = true);
                                        if (_pageController.hasClients) _pageController.jumpToPage(0);
                                      },
                                    ),
                                    _buildSegmentButton(
                                      title: 'Videos',
                                      icon: Icons.play_circle_fill,
                                      isSelected: !isImageView,
                                      onTap: () {
                                        setState(() => isImageView = false);
                                        if (_pageController.hasClients) _pageController.jumpToPage(0);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 28),
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onSelected: (value) {
                              if (value == 'auto_scroll') {
                                setState(() => isAutoScrollEnabled = !isAutoScrollEnabled);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'auto_scroll',
                                child: Row(
                                  children: [
                                    const Icon(Icons.swipe_down_rounded, color: Colors.black87, size: 20),
                                    const SizedBox(width: 12),
                                    Text('Auto Scroll', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black87)),
                                    const Spacer(),
                                    Icon(isAutoScrollEnabled ? Icons.toggle_on : Icons.toggle_off, color: isAutoScrollEnabled ? AppTheme.brandColor : Colors.grey, size: 32),
                                  ],
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
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.black87 : Colors.white70,
            ),
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

    return Container(
      color: const Color(0xFF1A1A1A), // Dark slate background to match screenshot
      child: Stack(
        children: [
          // 1. TOP TOGGLE is handled in the parent Stack for efficiency

          // 2. MIDDLE MEDIA SECTION
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                child: isImageView
                    ? _buildImageCarousel(allImages)
                    : _buildVideoPlaceholder(property),
              ),
            ),
          ),

          // 3. OWNER & BOTTOM CARD SECTION
          Positioned(
            top: MediaQuery.of(context).size.height * 0.60,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Owner Info Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/KHOZNA_app_icon_512x512.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Khozna app',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E88E5).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              property.category.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: const Color(0xFF64B5F6),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Bottom Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D), // Matching the dark card in screenshot
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(color: Colors.white10, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    property.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 24,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_rounded, color: Color(0xFF00A3DA), size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        property.location,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white60,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Price Alignment
                                   Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: SvgPicture.asset(
                                          'assets/icons/vector of ruppes.svg',
                                          width: 20,
                                          height: 20,
                                          colorFilter: const ColorFilter.mode(Color(0xFF00A3DA), BlendMode.srcIn),
                                        ),
                                      ),
                                      Text(
                                        PriceFormatter.format(
                                          (property.price == '0' || property.price.isEmpty || property.price == '₹0')
                                              ? (property.priceMonth > 0 ? property.priceMonth.toStringAsFixed(0) : 'Call for price')
                                              : property.price
                                        ).replaceAll('₹', ''),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF00A3DA), // Cyan blue price
                                        ),
                                      ),
                                      Text(
                                        '/month',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Side-by-side Action Buttons
                            Column(
                              children: [
                                // CHAT BUTTON (WHITE PILL)
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => chat_page.ChatScreen(
                                          ownerId: property.ownerId,
                                          name: property.ownerName,
                                          avatar: property.ownerAvatar,
                                          online: true,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF00A3DA), size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          'CHAT',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF00A3DA),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // VISIT BUTTON (BLUE PILL)
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: property)),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00A3DA),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.directions_run_rounded, color: Colors.white, size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          'VISIT',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            SvgPicture.asset(
              iconPath,
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
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
              const Icon(
                Icons.home_work_rounded,
                size: 80,
                color: Colors.white24,
              ),
              const SizedBox(height: 16),
              Text(
                'No photos available',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    
    if (images.length == 1) {
      return KhoznaImage(
        imageUrl: images[0],
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    
    return _MultiImageCarousel(images: images);
  }

  Widget _buildVideoPlaceholder(Property property) {
    return KhoznaVideoPlayer(
      videoUrl: property.videoUrl,
      thumbnailUrl: property.imageUrl,
      loop: !isAutoScrollEnabled,
      onVideoEnded: isAutoScrollEnabled ? _scrollToNext : null,
    );
  }
}

// Horizontal image carousel for multiple property photos with blurred background
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
          itemCount: widget.images.length,
          onPageChanged: (idx) => setState(() => _current = idx),
          itemBuilder: (context, index) {
            return KhoznaImage(
              imageUrl: widget.images[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );
          },
        ),
      ],
    );
  }
}
