import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import 'owner_profile_screen.dart';
import 'chat_screen.dart';
import 'property_details_screen.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();
  bool isImageView = true; 
  
  final List<Map<String, dynamic>> mockReels = [
    {
      'id': '1',
      'imageUrl': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      'title': 'Single room for student',
      'ownerName': 'Ram Bahadur',
      'ownerAvatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80',
      'ownerId': 'owner_ram_bahadur',
      'price': '8,000',
      'location': 'Baneshwar, Kathmandu',
      'likes': '2.4K',
      'isFavorite': true,
      'totalListings': 5,
    },
    {
      'id': '2',
      'imageUrl': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      'title': 'Modern Apartment in Sanepa',
      'ownerName': 'Jenny Wilson',
      'ownerAvatar': 'https://i.pravatar.cc/150?img=47',
      'ownerId': 'owner_jenny_wilson',
      'price': '25,000',
      'location': 'Sanepa, Lalitpur',
      'likes': '1.8K',
      'isFavorite': false,
      'totalListings': 3,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: mockReels.length,
            itemBuilder: (context, index) {
              return _buildReelItem(mockReels[index]);
            },
          ),
          // Top Toggle (Photo/Video)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
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

  Widget _buildSegmentButton({required String title, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
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

        // Slim, Long Bottom Glass Box
        Positioned(
          left: 12,
          right: 12,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Owner Header (outside glass or integrated)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerProfileScreen(
                        ownerId: reel['ownerId'] ?? 'unknown',
                        name: reel['ownerName'],
                        avatar: reel['ownerAvatar'],
                        location: reel['location'],
                        totalListings: reel['totalListings'],
                      ))),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                        child: CircleAvatar(radius: 18, backgroundImage: NetworkImage(reel['ownerAvatar'])),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              reel['ownerName'],
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: AppTheme.brandColor, size: 12),
                          ],
                        ),
                        Text(
                          '@${reel['ownerName'].toString().split(' ')[0].toLowerCase()}',
                          style: GoogleFonts.inter(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // THE MAIN SLIM GLASS BOX
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reel['title'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: AppTheme.brandColor, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        reel['location'],
                                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'रू ${reel['price']} /month',
                                    style: GoogleFonts.inter(color: AppTheme.brandColor, fontWeight: FontWeight.w900, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Visit Button (More Premium)
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PropertyDetailsScreen(
                                      id: reel['id'],
                                      imageUrl: reel['imageUrl'],
                                      images: [reel['imageUrl']],
                                      title: reel['title'],
                                      location: reel['location'],
                                      price: reel['price'],
                                      bedrooms: 0,
                                      bathrooms: 0,
                                      area: 'N/A',
                                      floor: 'N/A',
                                      description: 'Detailed view of ${reel['title']}',
                                    ),
                                  ),
                                );
                              },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'VISIT',
                                        style: GoogleFonts.inter(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black, size: 10),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 12),
                        // RE-ALIGNED ACTIONS ROW (Integrated into box)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCompactAction(
                              icon: reel['isFavorite'] ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              label: reel['likes'],
                              isActive: reel['isFavorite'],
                              activeColor: AppTheme.brandColor,
                              onTap: () => setState(() => reel['isFavorite'] = !reel['isFavorite']),
                            ),
                            _buildCompactAction(
                              isSvg: true,
                              svgPath: 'assets/icons/message.svg',
                              icon: Icons.chat_bubble_rounded, // Fallback
                              label: 'Direct Chat',
                              isActive: false,
                              activeColor: Colors.white,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                                name: reel['ownerName'],
                                avatar: reel['ownerAvatar'],
                                online: true,
                              ))),
                            ),
                             _buildCompactAction(
                              icon: Icons.send_rounded,
                              label: 'Share',
                              isActive: false,
                              activeColor: Colors.white,
                              onTap: () {
                                Share.share(
                                  'Check out this property: ${reel['title']} at ${reel['location']} for रू ${reel['price']}/month on Khozna!\n\nDownload the app to see more.',
                                  subject: 'Khozna Property Share',
                                );
                              },
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

  Widget _buildCompactAction({
    required IconData icon, 
    required String label, 
    required bool isActive, 
    required Color activeColor, 
    required VoidCallback onTap,
    bool isSvg = false,
    String? svgPath,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            isSvg && svgPath != null
              ? SvgPicture.asset(
                  svgPath,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    isActive ? activeColor : Colors.white,
                    BlendMode.srcIn,
                  ),
                )
              : Icon(icon, color: isActive ? activeColor : Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
