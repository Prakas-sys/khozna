import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'owner_profile_screen.dart';

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
              style: GoogleFonts.outfit(
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
        
        // Premium Gradient Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.85),
              ],
              stops: const [0.0, 0.2, 0.6, 1.0],
            ),
          ),
        ),

        // Modern "Wow" Side Icons (Right Side)
        Positioned(
          right: 12,
          bottom: 120,
          child: Column(
            children: [
              _buildModernAction(
                icon: reel['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                label: reel['likes'],
                color: reel['isFavorite'] ? Colors.redAccent : Colors.white,
              ),
              const SizedBox(height: 18),
              _buildModernAction(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Message',
                color: Colors.white,
              ),
              const SizedBox(height: 18),
              _buildModernAction(
                icon: Icons.chat_bubble_rounded,
                label: 'Chat',
                color: Colors.white,
              ),
              const SizedBox(height: 18),
              _buildModernAction(
                icon: Icons.share_rounded,
                label: 'Share',
                color: Colors.white,
              ),
              const SizedBox(height: 22),
              // Owner Avatar - Clickable
              GestureDetector(
                onTap: () {
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
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(reel['ownerAvatar']),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Content Area (Bottom)
        Positioned(
          left: 16,
          right: 16,
          bottom: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title First
              Text(
                reel['title'],
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              // Location Tag Below Title
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.brandColor, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    reel['location'],
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      shadows: [const Shadow(blurRadius: 4, color: Colors.black45, offset: Offset(0, 1))],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              
              // Action Buttons Row - Visual Upgrade
              Row(
                children: [
                  // Price Tag - Styled as a badge
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Center(
                      child: Text(
                        reel['price'],
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Reserve Button - Prominent Action
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.brandColor, Color(0xFF00D1FF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.brandColor.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(15),
                          child: Center(
                            child: Text(
                              'Reserve (बुक गर्नुहोस्)',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernAction({required IconData icon, required String label, required Color color}) {
    return Column(
      children: [
        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            shadows: [const Shadow(blurRadius: 2, color: Colors.black, offset: Offset(0, 1))],
          ),
        ),
      ],
    );
  }
}
