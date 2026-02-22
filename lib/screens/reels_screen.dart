import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();
  final List<Map<String, dynamic>> mockReels = [
    {
      'videoUrl': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
      'title': 'Modern Villa Tour',
      'description': 'आरामदायी र आधुनिक सुविधायुक्त भिल्ला। बालुवाटारको मुटुमा अवस्थित।',
      'agentName': 'Prakash (Owner)',
      'price': '1,200',
      'location': 'Baluwatar, KTM',
      'likes': '12.4K',
    },
    {
      'videoUrl': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
      'title': 'Luxury Apartment',
      'description': 'सानेपामा अवस्थित यो अपार्टमेन्टबाट सहरको सुन्दर दृश्य देखिन्छ।',
      'agentName': 'Khozna Verified',
      'price': '850',
      'location': 'Sanepa, Lalitpur',
      'likes': '8.2K',
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
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: mockReels.length,
        itemBuilder: (context, index) {
          return _buildReelItem(mockReels[index]);
        },
      ),
    );
  }

  Widget _buildReelItem(Map<String, dynamic> reelData) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image/Video
        Image.network(
          reelData['videoUrl'],
          fit: BoxFit.cover,
        ),
        
        // Clean Gradient Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.9),
              ],
              stops: const [0.0, 0.2, 0.6, 1.0],
            ),
          ),
        ),

        // Right side interaction (Airbnb/TikTok hybrid style)
        Positioned(
          right: 16,
          bottom: 120,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(Icons.favorite, reelData['likes'], isActive: true),
              const SizedBox(height: 24),
              _buildActionButton(Icons.comment_outlined, '42'),
              const SizedBox(height: 24),
              _buildActionButton(Icons.share_outlined, 'Share'),
              const SizedBox(height: 24),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: DecorationImage(
                    image: NetworkImage(reelData['videoUrl']),
                    fit: BoxFit.cover,
                  )
                ),
              )
            ],
          ),
        ),

        // Bottom Content
        Positioned(
          left: 20,
          right: 80,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Verified Owner Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, color: Colors.blue, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      reelData['agentName'],
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                reelData['title'],
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                reelData['description'],
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),

              // Property Quick Info Row
              Row(
                children: [
                  _buildReelBadge(Icons.location_on, reelData['location']),
                  const SizedBox(width: 12),
                  _buildReelBadge(Icons.sell, '\$${reelData['price']}/mo'),
                ],
              ),
              const SizedBox(height: 24),
              
              // Call to Action
              SizedBox(
                width: 160,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('अहिले हेर्नुहोस् (View)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, {bool isActive = false}) {
    return Column(
      children: [
        Icon(icon, color: isActive ? Colors.red : Colors.white, size: 30),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildReelBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.brandColor, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
