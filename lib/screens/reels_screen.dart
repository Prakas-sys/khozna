import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'owner_profile_screen.dart';
import 'chat_screen.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();
  bool isImageView = true; // Added state for Image/Video toggle
  
  final List<Map<String, dynamic>> mockReels = [
    {
      'imageUrl': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      'title': 'Single room for student',
      'description': 'सानेपाको शान्त वातावरणमा अवस्थित यो १ कोठाको फ्ल्याट विद्यार्थीको लागि उपयुक्त छ।',
      'ownerName': 'Ram Bahadur',
      'ownerAvatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80',
      'price': 'रू 8,000',
      'location': 'Baneshwar, Kathmandu',
      'likes': '2.4K',
      'isFavorite': true,
      'totalListings': 5,
    },
    {
      'imageUrl': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
      'title': 'Modern Apartment in Sanepa',
      'description': 'सानेपाको मुटुमा अवस्थित आधुनिक अपार्टमेन्ट।',
      'ownerName': 'Jenny Wilson',
      'ownerAvatar': 'https://i.pravatar.cc/150?img=47',
      'price': 'रू 25,000',
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

  void _showNotification(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.brandColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
          // Top SafeArea Toggle
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
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
        // Background Image (Property Image)
        Image.network(
          reel['imageUrl'],
          fit: BoxFit.cover,
        ),
        
        // Premium Multi-Layer Gradient Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.4),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.9),
              ],
              stops: const [0.0, 0.25, 0.5, 1.0],
            ),
          ),
        ),

        // Modern Glass Side Icons (Right Side)
        Positioned(
          right: 16,
          bottom: 140,
          child: Column(
            children: [
              // User Avatar with "Plus" badge
              GestureDetector(
                onTap: () {
                   HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OwnerProfileScreen(
                        name: reel['ownerName'],
                        avatar: reel['ownerAvatar'],
                        location: reel['location'],
                        totalListings: reel['totalListings'],
                      ),
                    ),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(reel['ownerAvatar']),
                      ),
                    ),
                    Positioned(
                      bottom: -8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppTheme.brandColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _buildModernAction(
                icon: reel['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                label: reel['likes'],
                color: reel['isFavorite'] ? AppTheme.brandColor : Colors.white,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    reel['isFavorite'] = !reel['isFavorite'];
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildModernAction(
                icon: Icons.chat_bubble_outline_rounded,
                label: '98',
                color: Colors.white,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        name: reel['ownerName'],
                        avatar: reel['ownerAvatar'],
                        online: true,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildModernAction(
                icon: Icons.share_rounded,
                label: 'Share',
                color: Colors.white,
                onTap: () {
                  HapticFeedback.lightImpact();
                },
              ),
            ],
          ),
        ),

        // Floating Frosted Info Card (Glassmorphism)
        Positioned(
          left: 16,
          right: 80, // Leave room for side icons
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Owner Identity
              Row(
                children: [
                  Text(
                    '@${reel['ownerName'].toString().replaceAll(' ', '').toLowerCase()}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.verified, color: AppTheme.brandColor, size: 14),
                ],
              ),
              const SizedBox(height: 8),
              // Frosted Glass Content Card
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reel['title'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.place_outlined, color: AppTheme.brandColor, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                reel['location'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              reel['price'],
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.brandColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.brandColor.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                  )
                                ],
                              ),
                              child: Text(
                                'VISIT',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 1.0,
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

  Widget _buildModernAction({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [
                const Shadow(blurRadius: 4, color: Colors.black, offset: Offset(0, 2))
              ],
            ),
          ),
        ],
      ),
    );
  }
}
