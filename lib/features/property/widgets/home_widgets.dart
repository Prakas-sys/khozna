import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/widgets/property_card.dart';
import 'package:khozna/widgets/skeleton_card.dart';
import 'package:khozna/widgets/voice_search_overlay.dart';
import 'package:khozna/core/guards/auth_guard.dart';

// ── Marquee (ticker) — always scrolls regardless of text length ─────────────
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeText({super.key, required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final ScrollController _sc;
  late final AnimationController _ac;
  bool _running = false;

  // Pad text so it ALWAYS has overflow to scroll
  String get _paddedText => '${widget.text}          ${widget.text}';

  @override
  void initState() {
    super.initState();
    _sc = ScrollController();
    _ac = AnimationController(vsync: this, duration: Duration.zero);
    // Give layout time to settle before measuring
    Future.delayed(const Duration(milliseconds: 600), _startLoop);
  }

  @override
  void didUpdateWidget(_MarqueeText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _running = false;
      if (_sc.hasClients) _sc.jumpTo(0);
      Future.delayed(const Duration(milliseconds: 400), _startLoop);
    }
  }

  Future<void> _startLoop() async {
    if (!mounted) return;
    _running = true;
    while (mounted && _running) {
      if (!_sc.hasClients) break;
      final max = _sc.position.maxScrollExtent;
      if (max <= 0) break;
      // natural pause before sliding
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted || !_running) break;
      // slide across
      await _sc.animateTo(
        max,
        duration: Duration(milliseconds: (max * 18).round().clamp(800, 6000)),
        curve: Curves.linear,
      );
      if (!mounted || !_running) break;
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted || !_running) break;
      if (_sc.hasClients) _sc.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _running = false;
    _ac.dispose();
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _sc,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        _paddedText,
        style: widget.style,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}

class HomeHeader extends StatelessWidget {
  final String locationName;
  final VoidCallback onLocationTap;
  final VoidCallback onNotificationTap;
  final VoidCallback? onLogoTap;

  const HomeHeader({
    super.key,
    required this.locationName,
    required this.onLocationTap,
    required this.onNotificationTap,
    this.onLogoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onLogoTap,
            child: Image.asset(
              'assets/images/logo 2.png',
              height: 48,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onLocationTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.brandColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.location_solid,
                        color: AppTheme.brandColor,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRect(
                        child: _MarqueeText(
                          key: ValueKey(locationName),
                          text: locationName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.black.withOpacity(0.8),
                            height: 1.1,
                            letterSpacing: -0.25,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.brandColor.withOpacity(0.5),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ValueListenableBuilder<int>(
            valueListenable: notificationBadgeCount,
            builder: (context, badgeCount, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  InkWell(
                    onTap: onNotificationTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Icon(
                        CupertinoIcons.bell,
                        color: Colors.black87,
                        size: 28,
                      ),
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF0000),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
                        ),
                        child: Center(
                          child: Text(
                            badgeCount > 9 ? '9+' : '$badgeCount',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class HomeHeroSection extends StatelessWidget {
  const HomeHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          FittedBox(
            child: Text(
              'Find Your Next Home',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              'No Middleman',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
                color: AppTheme.brandColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeSearchBar extends StatefulWidget {
  final VoidCallback onTap;
  final Function(String) onVoiceResult;

  const HomeSearchBar({
    super.key,
    required this.onTap,
    required this.onVoiceResult,
  });

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final Animation<double> _spinAnim;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _spinAnim = CurvedAnimation(
      parent: _spinCtrl,
      curve: Curves.easeInOutBack,
    );
    // Wait for page transition to finish then spin
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _spinCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'search_bar_container',
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.transparent, width: 0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(1, 0),
                ),
              ],
            ),
            child: Row(
              children: [
                // 🔍 Full 360° spin on app open
                RotationTransition(
                  turns: _spinAnim,
                  child: SvgPicture.asset(
                    'assets/icons/Search vector.svg',
                    width: 26,
                    height: 26,
                    colorFilter: const ColorFilter.mode(
                      AppTheme.brandColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Search properties',
                    style: GoogleFonts.inter(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: InkWell(
                    onTap: () {
                      if (!AuthGuard.checkAuth(
                        context,
                        title: 'Search Properties',
                        message: 'Log in to search and discover matching properties.',
                      )) {
                        return;
                      }
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) =>
                            VoiceSearchOverlay(onResult: widget.onVoiceResult),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppTheme.brandColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class HomeHorizontalSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Property> properties;
  final bool isLoading;
  final Function(String, String) onViewAll;
  final int? index;

  const HomeHorizontalSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.properties,
    required this.isLoading,
    required this.onViewAll,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -4),
              child: InkWell(
                onTap: () => onViewAll(title, subtitle),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.east, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            if (isLoading && properties.isEmpty) {
              return _buildSkeletonList();
            }
            if (properties.isEmpty) {
              return _buildErrorState();
            }

            return SizedBox(
              height: 282,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                physics: const BouncingScrollPhysics(),
                itemCount: 4,
                itemBuilder: (context, index) {
                  if (index < properties.length) {
                    return _buildPropertyCard(properties[index]);
                  } else {
                    return const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: SkeletonCard(),
                    );
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSkeletonList() {
    return SizedBox(
      height: 282,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 3,
        itemBuilder: (_, _) => const Padding(
          padding: EdgeInsets.only(right: 16),
          child: SkeletonCard(),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.grey[400], size: 48),
          const SizedBox(height: 12),
          Text(
            'Offline Mode',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check internet to refresh',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Property p) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: PropertyCard(property: p),
    );
  }
}
