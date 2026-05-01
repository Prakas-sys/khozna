import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/widgets/property_card.dart';
import 'package:khozna/widgets/skeleton_card.dart';
import 'package:khozna/widgets/voice_search_overlay.dart';
import 'package:khozna/features/property/screens/search_screen.dart';
import 'package:khozna/features/property/screens/filter_results_screen.dart';

class HomeHeader extends StatelessWidget {
  final String locationName;
  final VoidCallback onLocationTap;
  final VoidCallback onNotificationTap;

  const HomeHeader({
    super.key,
    required this.locationName,
    required this.onLocationTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Image.asset('assets/images/original logo.png', height: 48, fit: BoxFit.contain),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onLocationTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: AppTheme.brandColor.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(CupertinoIcons.location_solid, color: AppTheme.brandColor, size: 14),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          locationName,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black.withOpacity(0.8), height: 1.1, letterSpacing: -0.2),
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.brandColor.withOpacity(0.5), size: 18),
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
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                      child: const Icon(CupertinoIcons.bell, color: Colors.black87, size: 28),
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(color: Color(0xFFFF0000), shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                        child: Center(
                          child: Text(
                            badgeCount > 9 ? '9+' : '$badgeCount',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
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
              'Find your Next Home',
              style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1.0, color: Colors.black),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              'No middleman',
              style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1.0, color: AppTheme.brandColor),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeSearchBar extends StatelessWidget {
  final VoidCallback onTap;
  final Function(String) onVoiceResult;

  const HomeSearchBar({super.key, required this.onTap, required this.onVoiceResult});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'search_bar_container',
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200, width: 1.2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.search, color: AppTheme.brandColor, size: 26),
                const SizedBox(width: 14),
                Expanded(child: Text('Search properties', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 16))),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => VoiceSearchOverlay(onResult: onVoiceResult),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: AppTheme.brandColor, shape: BoxShape.circle),
                      child: const Icon(Icons.mic, color: Colors.white, size: 22),
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
  final Future<List<Property>> future;
  final Function(String, String) onViewAll;
  final int? index;

  const HomeHorizontalSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.future,
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
            Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            Transform.translate(
              offset: const Offset(0, -4),
              child: InkWell(
                onTap: () => onViewAll(title, subtitle),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.east, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Property>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return _buildSkeletonList();
            final properties = snapshot.data ?? [];
            if (properties.isEmpty) return snapshot.hasError ? _buildErrorState() : _buildSkeletonList();

            return SizedBox(
              height: 285,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                physics: const BouncingScrollPhysics(),
                itemCount: 4,
                itemBuilder: (context, index) {
                  if (index < properties.length) {
                    return _buildPropertyCard(properties[index]);
                  } else {
                    return const Padding(padding: EdgeInsets.only(right: 16), child: SkeletonCard());
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
      height: 285,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(padding: EdgeInsets.only(right: 16), child: SkeletonCard()),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.grey[400], size: 48),
          const SizedBox(height: 12),
          Text('Offline Mode', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text('Check internet to refresh', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
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
