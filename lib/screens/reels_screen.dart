import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import 'owner_profile_screen.dart';
import 'package:khozna/screens/chat_screen.dart' as chat_page;
import 'package:url_launcher/url_launcher.dart';
import 'property_details_screen.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();
  bool isImageView = true;
  List<Map<String, dynamic>> reels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReels();
  }

  Future<void> _fetchReels() async {
    try {
      final data = await Supabase.instance.client
          .from('properties')
          .select('*, profiles:owner_id(full_name, avatar_url)')
          .eq('status', 'available')
          .not('images', 'is', null)
          .order('created_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          reels = (data as List).map((p) {
            final profile = p['profiles'] as Map<String, dynamic>? ?? {};
            final images = (p['images'] as List?)?.cast<String>() ?? [];
            return {
              'id': p['id'] ?? '',
              'imageUrl': images.isNotEmpty ? images.first : 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
              'images': images,
              'video_url': p['video_url'],
              'title': p['title'] ?? 'Property for rent',
              'ownerName': profile['full_name'] ?? 'Owner',
              'ownerAvatar': profile['avatar_url'] ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
              'ownerId': p['owner_id'] ?? '',
              'price': p['price']?.toString() ?? '0',
              'location': [p['area_name'], p['landmark']].where((e) => e != null && e.toString().isNotEmpty).join(' • '),
              'area_name': p['area_name'] ?? '',
              'landmark': p['landmark'] ?? '',
              'category': p['category'] ?? 'Room',
              'bedrooms': p['bedrooms'] ?? 0,
              'bathrooms': p['bathrooms'] ?? 0,
              'area': p['sq_ft'] ?? 'N/A',
              'floor': p['floor'] ?? 'N/A',
              'description': p['description'] ?? '',
              'latitude': p['latitude'],
              'longitude': p['longitude'],
              'amenities': (p['amenities'] as List?)?.cast<String>() ?? [],
              'house_rules': (p['house_rules'] as List?)?.cast<String>() ?? [],
              'likes': '0',
              'isFavorite': false,
              'totalListings': 1,
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: reels.length,
            itemBuilder: (context, index) {
              return _buildReelItem(reels[index]);
            },
          ),
          // Top Toggle (Photo/Video)
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
                            title: 'Photo',
                            icon: Icons.image_rounded,
                            isSelected: isImageView,
                            onTap: () => setState(() => isImageView = true),
                          ),
                          _buildSegmentButton(
                            title: 'Video',
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

  Widget _buildReelItem(Map<String, dynamic> reel) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Content (Image)
        Image.network(reel['imageUrl'], fit: BoxFit.cover),

        // Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
              stops: const [0.0, 0.2, 0.6, 1.0],
            ),
          ),
        ),

        // Slim, High-End Bottom Glass Box
        Positioned(
          left: 12,
          right: 12,
          bottom: 95, // Clears navbar + adds luxury padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Owner Header
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OwnerProfileScreen(
                            ownerId: reel['ownerId'] ?? 'unknown',
                            name: reel['ownerName'],
                            avatar: reel['ownerAvatar'],
                            location: reel['location'],
                            totalListings: reel['totalListings'],
                          ),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(reel['ownerAvatar']),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Row(
                      children: [
                        Text(
                          reel['ownerName'],
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: AppTheme.brandColor,
                          size: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // THE MAIN COMPACT GLASS BOX
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
                                reel['title'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: AppTheme.brandColor,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      reel['location'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '₹ ',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.brandColor,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '${reel['price']} /month',
                                      style: GoogleFonts.inter(
                                        color: AppTheme.brandColor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
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
                            // Visit Button
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PropertyDetailsScreen(
                                      id: reel['id'],
                                      imageUrl: reel['imageUrl'],
                                      images: reel['images'],
                                      title: reel['title'],
                                      location: reel['location'],
                                      price: reel['price'],
                                      description: reel['description'],
                                      bedrooms: reel['bedrooms'],
                                      bathrooms: reel['bathrooms'],
                                      area: reel['area'],
                                      floor: reel['floor'],
                                      ownerId: reel['ownerId'],
                                      landmark: reel['landmark'],
                                      latitude: reel['latitude'],
                                      longitude: reel['longitude'],
                                      amenities: reel['amenities'],
                                      houseRules: reel['house_rules'],
                                      category: reel['category'],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.directions_walk_rounded, color: Colors.black, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'VISIT',
                                      style: GoogleFonts.inter(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // CHAT BUTTON
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => chat_page.ChatScreen(
                                      ownerId: reel['ownerId'] ?? '',
                                      name: reel['ownerName'],
                                      avatar: reel['ownerAvatar'],
                                      online: true,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandColor,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/message.svg',
                                      width: 16,
                                      height: 16,
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'CHAT',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
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
            ],
          ),
        ),
      ],
    );
  }
}
