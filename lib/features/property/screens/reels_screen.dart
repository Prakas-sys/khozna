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
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.brandColor),
                )
              : (displayReels.isEmpty
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
                            isImageView 
                                ? 'अहिले कुनै Reel छैन।\n(No reels yet)' 
                                : 'भिडियो उपलब्ध छैन।\n(No videos found)',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.mukta(
                              color: Colors.white60,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
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
                    )),
          
          // Top Toggle (Photos/Videos) - ALWAYS VISIBLE
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
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
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 24),
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
                  ),
                ],
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
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced padding
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18, // Slightly smaller icon
              color: isSelected ? Colors.black : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14, // Slightly smaller font
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
      color: Colors.black,
      child: Stack(
        children: [
          // 1. FULL SCREEN MEDIA BACKGROUND
          Positioned.fill(
            child: isImageView
                ? _buildImageCarousel(allImages, property.category)
                : _buildVideoPlaceholder(property),
          ),

          // 2. BOTTOM SHADOW GRADIENT (For text readability)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.6, 1.0],
                  colors: [
                    Colors.black.withOpacity(0),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),

          // 3. CONTENT OVERLAY
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40), // Spacing from bottom
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Owner Info Header
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/KHOZNA_app_icon_512x512.png',
                              width: 38, // Reduced from 50
                              height: 38, // Reduced from 50
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Row(
                               children: [
                                 Text(
                                   'Khozna app',
                                   style: GoogleFonts.plusJakartaSans(
                                     color: Colors.white,
                                     fontWeight: FontWeight.w800,
                                     fontSize: 16,
                                   ),
                                 ),
                                 const SizedBox(width: 5),
                                 const Icon(
                                   Icons.verified_rounded,
                                   color: Color(0xFF00A3DA),
                                   size: 16,
                                 ),
                               ],
                             ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A3DA).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF00A3DA).withOpacity(0.5)),
                              ),
                              child: Text(
                                property.category.toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Property Info Glass Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Left: Property Text Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                property.title,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18, // Reduced from 19
                                  height: 1.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6), // Reduced from 8
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, color: Color(0xFF00A3DA), size: 14), // Reduced from 16
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      property.location,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white70,
                                        fontSize: 13, // Reduced from 14
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10), // Reduced from 12
                              Flexible(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: SvgPicture.asset(
                                        'assets/icons/vector of ruppes.svg',
                                        width: 14,
                                        height: 14,
                                        colorFilter: const ColorFilter.mode(
                                          Color(0xFF00A3DA),
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        PriceFormatter.format(
                                          property.priceMonth > 0
                                              ? property.priceMonth.toInt().toString()
                                              : (property.priceNight > 0 
                                                  ? property.priceNight.toInt().toString() 
                                                  : (property.price != '0' && property.price != '0.0' && property.price.isNotEmpty ? property.price : 'Negotiable')),
                                        ),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF00A3DA),
                                          letterSpacing: -0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      property.priceMonth > 0
                                          ? '/month'
                                          : (property.priceNight > 0 ? '/night' : ''),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 12),

                        // Right: Vertical Action Buttons
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildActionButton(
                              text: 'CHAT',
                              iconPath: 'assets/icons/Message neww.svg',
                              isPrimary: false,
                              onTap: () {
                                // Chat navigation logic...
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
                            ),
                            const SizedBox(height: 12),
                            _buildActionButton(
                              text: 'VISIT',
                              icon: Icons.directions_run_rounded,
                              isPrimary: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: property)),
                                );
                              },
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
    required String text,
    IconData? icon,
    String? iconPath,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF00A3DA) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconPath != null)
              SvgPicture.asset(
                iconPath,
                width: 14,
                height: 14,
                colorFilter: ColorFilter.mode(
                  isPrimary ? Colors.white : const Color(0xFF00A3DA),
                  BlendMode.srcIn,
                ),
              )
            else
              Icon(icon, color: isPrimary ? Colors.white : const Color(0xFF00A3DA), size: 14),
            const SizedBox(width: 6),
            Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                color: isPrimary ? Colors.white : const Color(0xFF00A3DA),
                fontSize: 11, // Reduced from 12
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images, String category) {
    if (images.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(child: Icon(Icons.home_work_rounded, size: 80, color: Colors.white10)),
      );
    }
    
    return _MultiImageCarousel(images: images, category: category);
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

class _MultiImageCarousel extends StatefulWidget {
  final List<String> images;
  final String category;
  const _MultiImageCarousel({required this.images, required this.category});

  @override
  State<_MultiImageCarousel> createState() => _MultiImageCarouselState();
}

class _MultiImageCarouselState extends State<_MultiImageCarousel> {
  final PageController _carouselController = PageController();
  int _current = 0;

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _carouselController,
          itemCount: widget.images.length,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (idx) => setState(() => _current = idx),
          itemBuilder: (context, index) {
            return Stack(
              fit: StackFit.expand,
              children: [
                KhoznaImage(imageUrl: widget.images[index], fit: BoxFit.cover),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(color: Colors.black.withOpacity(0.3)),
                  ),
                ),
                KhoznaImage(
                  imageUrl: widget.images[index], 
                  fit: BoxFit.cover,
                ),
              ],
            );
          },
        ),
        
        // Navigation Arrows for Carousel
        if (widget.images.length > 1) ...[
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: () {
                  if (_current > 0) {
                    _carouselController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white.withOpacity(_current > 0 ? 0.7 : 0.2),
                  size: 20,
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: () {
                  if (_current < widget.images.length - 1) {
                    _carouselController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(_current < widget.images.length - 1 ? 0.7 : 0.2),
                  size: 20,
                ),
              ),
            ),
          ),
        ],

        if (widget.images.length > 1)
          Positioned(
            bottom: 150, // Moved up to stay above the property info card
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.images.asMap().entries.map((entry) {
                return Container(
                  width: 6.0,
                  height: 6.0,
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(_current == entry.key ? 0.9 : 0.4),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}


