import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:khozna/features/property/screens/property_details_screen.dart';
import 'package:khozna/features/profile/screens/owner_profile_screen.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/widgets/khozna_image.dart';
import 'package:khozna/widgets/khozna_video_player.dart';
import 'package:khozna/widgets/favourite_button.dart';
import 'package:khozna/core/utils/formatters.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/core/utils/supabase_service.dart';

class ToursScreen extends StatefulWidget {
  const ToursScreen({super.key});

  @override
  State<ToursScreen> createState() => _ToursScreenState();
}

class _ToursScreenState extends State<ToursScreen> {
  final PageController _pageController = PageController();
  bool isImageView = true;
  bool isAutoScrollEnabled = false;
  List<Property> reels = [];
  bool _isLoading = true;

  List<Property> get displayReels =>
      isImageView ? reels : reels.where((p) => p.videoUrl.isNotEmpty).toList();

  void _scrollToNext() {
    if (_pageController.hasClients) {
      final int nextPage = _pageController.page!.round() + 1;
      if (nextPage < displayReels.length) {
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
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      _fetchReels();
    }
  }

  Future<void> _fetchReels() async {
    try {
      debugPrint('ReelsScreen: Starting fetch...');
      final data = await Supabase.instance.client
          .from('properties')
          .select(
            'id, owner_id, title, area_name, price, price_night, price_month, images, video_url, category, status, bedrooms, bathrooms, amenities, house_rules, profiles:owner_id(full_name, avatar_url, kyc_status, area_name)',
          )
          .order('created_at', ascending: false)
          .limit(30);

      debugPrint('ReelsScreen: Fetched ${data.length} items');

      if (mounted) {
        setState(() {
          reels = (data as List).map((p) => Property.fromMap(p)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ReelsScreen fetch error: $e');
      try {
        final data = await Supabase.instance.client
            .from('properties')
            .select('*')
            .order('created_at', ascending: false)
            .limit(30);

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
          // 1. MAIN VERTICAL PAGE SWIPER
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.brandColor),
                )
              : (displayReels.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: const Icon(
                              Icons.video_library_outlined,
                              color: Colors.white38,
                              size: 56,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            isImageView
                                ? 'अहिले कुनै Tour छैन।\n(No tour yet)'
                                : 'भिडियो उपलब्ध छैन।\n(No videos found)',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.mukta(
                              color: Colors.white70,
                              fontSize: 18,
                              height: 1.4,
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
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: displayReels.length,
                        itemBuilder: (context, index) {
                          return _ReelItem(
                            key: ValueKey(displayReels[index].id),
                            property: displayReels[index],
                            isImageView: isImageView,
                            isAutoScrollEnabled: isAutoScrollEnabled,
                            onVideoEnded: isAutoScrollEnabled ? _scrollToNext : null,
                          );
                        },
                      ),
                    )),

          // 2. ULTRA SLEEK FLOATING GLASS HEADER
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Back button
                    _buildBlurIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),

                    // Central Photos / Videos Pill Switcher
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.30),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildSegmentButton(
                                title: 'Photos',
                                icon: Icons.photo_library_rounded,
                                isSelected: isImageView,
                                onTap: () => setState(() => isImageView = true),
                              ),
                              _buildSegmentButton(
                                title: 'Videos',
                                icon: Icons.play_circle_fill_rounded,
                                isSelected: !isImageView,
                                onTap: () => setState(() => isImageView = false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Options menu
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.30),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      color: const Color(0xFF1E1E24),
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.white.withOpacity(0.12)),
                      ),
                      onSelected: (value) {
                        if (value == 'auto_scroll') {
                          setState(
                            () => isAutoScrollEnabled = !isAutoScrollEnabled,
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'auto_scroll',
                          child: Row(
                            children: [
                              Icon(
                                Icons.swipe_down_rounded,
                                color: isAutoScrollEnabled
                                    ? AppTheme.brandColor
                                    : Colors.white70,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Auto Scroll',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Switch.adaptive(
                                value: isAutoScrollEnabled,
                                activeColor: AppTheme.brandColor,
                                onChanged: (val) {
                                  Navigator.pop(context, 'auto_scroll');
                                },
                              ),
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

  Widget _buildBlurIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.black.withOpacity(0.30),
          shape: CircleBorder(
            side: BorderSide(color: Colors.white.withOpacity(0.15)),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
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
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.black87 : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? Colors.black87 : Colors.white,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single Tour Page Item with immersive media, double-tap like, right sidebar, and bottom info card.
class _ReelItem extends StatefulWidget {
  final Property property;
  final bool isImageView;
  final bool isAutoScrollEnabled;
  final VoidCallback? onVideoEnded;

  const _ReelItem({
    super.key,
    required this.property,
    required this.isImageView,
    required this.isAutoScrollEnabled,
    this.onVideoEnded,
  });

  @override
  State<_ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<_ReelItem> with SingleTickerProviderStateMixin {
  bool _showHeartAnimation = false;
  late AnimationController _heartAnimController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartAnimController);
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    super.dispose();
  }

  void _triggerDoubleTapLike() {
    HapticFeedback.heavyImpact();
    setState(() => _showHeartAnimation = true);
    _heartAnimController.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _showHeartAnimation = false);
    });
    // Trigger save
    if (!savedPropertiesStore.value.contains(widget.property.id)) {
      SupabaseService.toggleSaveProperty(widget.property.id);
    }
  }

  void _shareProperty() {
    HapticFeedback.lightImpact();
    final String shareText =
        'Check out ${widget.property.title} on Khozna!\nLocation: ${widget.property.location}\nCategory: ${widget.property.category.toUpperCase()}\nPrice: NRs ${widget.property.price}';
    Share.share(shareText, subject: widget.property.title);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> allImages = widget.property.images.isNotEmpty
        ? widget.property.images
        : (widget.property.imageUrl.isNotEmpty ? [widget.property.imageUrl] : []);

    return GestureDetector(
      onDoubleTap: _triggerDoubleTapLike,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. FULL-SCREEN MEDIA BACKGROUND
          widget.isImageView
              ? _FullImageCarousel(images: allImages, category: widget.property.category)
              : _FullVideoPlayer(
                  property: widget.property,
                  isAutoScrollEnabled: widget.isAutoScrollEnabled,
                  onVideoEnded: widget.onVideoEnded,
                ),

          // 2. CINEMATIC GRADIENT OVERLAY (For contrast & readability)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.25, 0.55, 1.0],
                    colors: [
                      Colors.black.withOpacity(0.65),
                      Colors.transparent,
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.92),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. DOUBLE TAP LIKE ANIMATION OVERLAY
          if (_showHeartAnimation)
            Center(
              child: ScaleTransition(
                scale: _heartScale,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF385C).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFFF385C),
                    size: 100,
                  ),
                ),
              ),
            ),

          // 4. RIGHT-SIDE FLOATING ACTION SIDEBAR
          Positioned(
            right: 14,
            bottom: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Host Avatar with Verified Ring
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OwnerProfileScreen(
                          ownerId: widget.property.ownerId,
                          name: widget.property.ownerName,
                          avatar: widget.property.ownerAvatar,
                          isVerified: widget.property.isOwnerVerified,
                          location: widget.property.location,
                          totalListings: 1,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.property.isOwnerVerified
                            ? AppTheme.brandColor
                            : Colors.white,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: AppTheme.buildAvatarWidget(
                      avatarUrl: widget.property.ownerAvatar,
                      radius: 24,
                      name: widget.property.ownerName,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Wishlist / Favourite Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: FavouriteButton(
                    propertyId: widget.property.id,
                    size: 26,
                    showShadow: false,
                  ),
                ),
                const SizedBox(height: 18),

                // Instant Chat Button
                _buildSidebarIconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/Vectorproepty card meeasge.svg',
                    width: 22,
                    height: 22,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: 'Chat',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => chat_page.ChatScreen(
                          ownerId: widget.property.ownerId,
                          name: widget.property.ownerName,
                          avatar: widget.property.ownerAvatar,
                          online: true,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Share Button
                _buildSidebarIconButton(
                  icon: const Icon(
                    Icons.share_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  label: 'Share',
                  onTap: _shareProperty,
                ),
                const SizedBox(height: 18),

                // Direct Visit Button
                _buildSidebarIconButton(
                  icon: const Icon(
                    Icons.explore_rounded,
                    color: AppTheme.brandColor,
                    size: 24,
                  ),
                  label: 'Details',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PropertyDetailsScreen(property: widget.property),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 5. BOTTOM GLASSMORPHIC PROPERTY INFORMATION CARD
          Positioned(
            left: 14,
            right: 76, // Leaves space for the right sidebar
            bottom: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D12).withOpacity(0.65),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Property Title
                      Text(
                        widget.property.title,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Host + Location Row combined
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: AppTheme.brandColor,
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OwnerProfileScreen(
                                      ownerId: widget.property.ownerId,
                                      name: widget.property.ownerName,
                                      avatar: widget.property.ownerAvatar,
                                      isVerified: widget.property.isOwnerVerified,
                                      location: widget.property.location,
                                      totalListings: 1,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                widget.property.location,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withOpacity(0.70),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Price Tag & CTA Button Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Formatted Price Tag
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/icons/vector of ruppes.svg',
                                width: 14.0, // 0.5 number smaller as requested
                                height: 14.0,
                                colorFilter: const ColorFilter.mode(
                                  AppTheme.brandColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                PriceFormatter.format(
                                  widget.property.priceMonth > 0
                                      ? widget.property.priceMonth.toInt().toString()
                                      : (widget.property.priceNight > 0
                                            ? widget.property.priceNight.toInt().toString()
                                            : (widget.property.price != '0' &&
                                                    widget.property.price != '0.0' &&
                                                    widget.property.price.isNotEmpty
                                                ? widget.property.price
                                                : 'Negotiable')),
                                ),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                widget.property.priceMonth > 0
                                    ? '/mo'
                                    : (widget.property.priceNight > 0 ? '/night' : ''),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),

                          // Visit Now CTA — full pill shape
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PropertyDetailsScreen(
                                    property: widget.property,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.brandColor,
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    'assets/images/view now.svg',
                                    width: 16.5,
                                    height: 11,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'View Now',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarIconButton({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              shadows: [
                const Shadow(
                  color: Colors.black87,
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen responsive image carousel with story-style progress indicators.
/// Uses tap-to-advance (left/right) to avoid conflicting with outer vertical reel swipe.
class _FullImageCarousel extends StatefulWidget {
  final List<String> images;
  final String category;

  const _FullImageCarousel({
    required this.images,
    required this.category,
  });

  @override
  State<_FullImageCarousel> createState() => _FullImageCarouselState();
}

class _FullImageCarouselState extends State<_FullImageCarousel> {
  int _currentIndex = 0;

  void _goNext() {
    if (_currentIndex < widget.images.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _goPrev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        color: const Color(0xFF0F0F14),
        child: const Center(
          child: Icon(Icons.home_work_rounded, size: 80, color: Colors.white10),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Dark Atmospheric Blurred Backdrop
        Positioned.fill(
          child: Container(
            color: const Color(0xFF0F0F14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                KhoznaImage(
                  key: ValueKey('bg_$_currentIndex'),
                  imageUrl: widget.images[_currentIndex],
                  fit: BoxFit.cover,
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      color: Colors.black.withOpacity(0.50),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Centered Medium-Sized Photo Card
        Center(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.58, // Medium height (58% screen)
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: KhoznaImage(
                  key: ValueKey(_currentIndex),
                  imageUrl: widget.images[_currentIndex],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),

        // Dual Gesture Layer: Horizontal Swipe + Tap (Vertical swipe passes to reel PageView)
        if (widget.images.length > 1)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < -120) {
                    _goNext();
                  } else if (details.primaryVelocity! > 120) {
                    _goPrev();
                  }
                }
              },
              onTapUp: (details) {
                final screenWidth = MediaQuery.of(context).size.width;
                if (details.globalPosition.dx < screenWidth * 0.45) {
                  _goPrev();
                } else if (details.globalPosition.dx > screenWidth * 0.55) {
                  _goNext();
                }
              },
              child: const SizedBox.expand(),
            ),
          ),

        // Progress bars — positioned BELOW the floating header
        if (widget.images.length > 1)
          Positioned(
            top: MediaQuery.of(context).padding.top + 82,
            left: 16,
            right: 16,
            child: Row(
              children: List.generate(widget.images.length, (idx) {
                final bool isActive = idx == _currentIndex;
                final bool isPast = idx < _currentIndex;

                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: isActive ? 3.5 : 2.5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isPast || isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

/// Full-screen Video Player with automatic autoplay & tap to pause/play functionality.
class _FullVideoPlayer extends StatefulWidget {
  final Property property;
  final bool isAutoScrollEnabled;
  final VoidCallback? onVideoEnded;

  const _FullVideoPlayer({
    required this.property,
    required this.isAutoScrollEnabled,
    this.onVideoEnded,
  });

  @override
  State<_FullVideoPlayer> createState() => _FullVideoPlayerState();
}

class _FullVideoPlayerState extends State<_FullVideoPlayer> {
  @override
  Widget build(BuildContext context) {
    if (widget.property.videoUrl.isEmpty) {
      return Container(
        color: const Color(0xFF0F0F14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_rounded, size: 64, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              'No video available for this tour',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white60,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return Positioned.fill(
      child: KhoznaVideoPlayer(
        videoUrl: widget.property.videoUrl,
        thumbnailUrl: widget.property.imageUrl,
        loop: !widget.isAutoScrollEnabled,
        onVideoEnded: widget.isAutoScrollEnabled ? widget.onVideoEnded : null,
      ),
    );
  }
}
