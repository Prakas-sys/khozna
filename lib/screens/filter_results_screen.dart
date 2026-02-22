import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'property_details_screen.dart';

class FilterResultsScreen extends StatelessWidget {
  final String location;
  final String priceRange;

  const FilterResultsScreen({
    super.key,
    this.location = 'Baluwatar, KTM',
    this.priceRange = 'Up to Rs. 30,000',
  });

  @override
  Widget build(BuildContext context) {
    const Color airbnbGrey = Color(0xFF717171);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(location, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            Text(priceRange, style: GoogleFonts.outfit(fontSize: 12, color: airbnbGrey)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.tune, color: AppTheme.brandColor), onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: 5,
            itemBuilder: (context, index) {
              return _buildResultCard(context, index.toString());
            },
          ),
          
          // FLOATING MAP BUTTON (Airbnb Style)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF222222), // Dark Airbnb map button
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Map', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Icon(Icons.map_outlined, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, String id) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PropertyDetailsScreen(id: id, imageUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80', title: 'Modern Flat', location: 'Baluwatar', price: '850'))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: Image.network(
                      'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(top: 16, right: 16, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.favorite_border, size: 20))),
                Positioned(
                  top: 16, left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                    child: Row(children: [
                      const Icon(Icons.verified, size: 14, color: AppTheme.brandColor),
                      const SizedBox(width: 4),
                      Text('VERIFIED', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.brandColor)),
                    ]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Modern 2BHK Flat', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                Row(children: [const Icon(Icons.star, size: 14), const SizedBox(width: 4), Text('4.8', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold))]),
              ],
            ),
            Text('Baluwatar, Kathmandu', style: GoogleFonts.outfit(color: const Color(0xFF717171), fontSize: 14)),
            const SizedBox(height: 4),
            RichText(text: TextSpan(children: [
              TextSpan(text: 'Rs. 25,000', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              TextSpan(text: ' / month', style: GoogleFonts.outfit(color: Colors.black, fontSize: 14)),
            ])),
          ],
        ),
      ),
    );
  }
}
