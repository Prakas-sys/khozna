import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final String id;
  final String imageUrl;
  final String title;
  final String location;
  final String price;

  const PropertyDetailsScreen({
    super.key,
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    const Color airbnbGrey = Color(0xFF717171);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, id, imageUrl),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // VERIFIED BADGE & TITLE
                  _buildHeader(title, location),
                  const SizedBox(height: 24),

                  // PRICE BOX
                  _buildPriceBox(price, airbnbGrey),
                  const SizedBox(height: 32),

                  // THE NEPAL ESSENTIALS
                  _buildSectionTitle('आधारभूत सुविधाहरू (Essentials)'),
                  const SizedBox(height: 16),
                  _buildEssentialRow(Icons.water_drop_outlined, 'पानी (Water)', 'Melamchi + Well (24/7)'),
                  _buildEssentialRow(Icons.bolt_outlined, 'बिजुली (Electricity)', 'Separate Sub-meter'),
                  _buildEssentialRow(Icons.directions_car_outlined, 'पार्किङ (Parking)', 'Available (Bike/Car)'),
                  _buildEssentialRow(Icons.wifi, 'इन्टरनेट (Internet)', 'Included (50 Mbps)'),
                  const SizedBox(height: 32),

                  // LOCATION FOCUS SECTION (NEW)
                  _buildSectionTitle('लोकेशन र वरपरका सुविधाहरू (Location)'),
                  const SizedBox(height: 16),
                  _buildLocationDetails(location, airbnbGrey),
                  const SizedBox(height: 16),
                  // Fake Map View
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                      image: const DecorationImage(
                        image: NetworkImage('https://miro.medium.com/v2/resize:fit:1400/1*q69O5N7I6kUf6J39sP5nPQ.png'), // Placeholder map
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.location_on, color: AppTheme.brandColor, size: 30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // NEARBY PLACES
                  _buildSectionTitle('वरपरका मुख्य ठाउँहरू (Nearby Places)'),
                  const SizedBox(height: 12),
                  _buildNearbyItem(Icons.local_hospital_outlined, 'Hospital', '200m (Civil Hospital)'),
                  _buildNearbyItem(Icons.school_outlined, 'School', '500m (St. Xavier\'s)'),
                  _buildNearbyItem(Icons.shopping_cart_outlined, 'Market', '100m (Local Bazaar)'),
                  _buildNearbyItem(Icons.bus_alert_outlined, 'Bus Stop', '50m (Main Road)'),

                  const SizedBox(height: 32),
                  // DESCRIPTION
                  _buildSectionTitle('विवरण (Description)'),
                  const SizedBox(height: 12),
                  Text(
                    'सानेपाको शान्त वातावरणमा अवस्थित यो २ कोठाको फ्ल्याट विद्यार्थी वा सानो परिवारको लागि उपयुक्त छ। उज्यालो कोठाहरू र खुल्ला पार्किङको सुविधा उपलब्ध छ। मुख्य बाटोबाट मात्र ५ मिनेटको दुरीमा।',
                    style: GoogleFonts.outfit(fontSize: 15, color: airbnbGrey, height: 1.6),
                  ),
                  const SizedBox(height: 120), 
                ],
              ),
            ),
          )
        ],
      ),
      bottomSheet: _buildBottomActionBar(context),
    );
  }

  // --- COMPONENT BUILDERS ---

  Widget _buildSliverAppBar(BuildContext context, String id, String imageUrl) {
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black),
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'property-image-$id',
          child: Image.network(imageUrl, fit: BoxFit.cover),
        ),
      ),
      actions: [
        Container(margin: const EdgeInsets.only(right: 16), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: IconButton(icon: const Icon(Icons.share_outlined, color: Colors.black, size: 20), onPressed: () {})),
        Container(margin: const EdgeInsets.only(right: 16), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: IconButton(icon: const Icon(Icons.favorite_border, color: Colors.black, size: 20), onPressed: () {})),
      ],
    );
  }

  Widget _buildHeader(String title, String location) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppTheme.brandColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
          child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
            const Icon(Icons.verified, color: AppTheme.brandColor, size: 14),
            const SizedBox(width: 4),
            Text('VERIFIED OWNER', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.brandColor)),
          ]),
        ),
        const SizedBox(height: 12),
        Text(title, style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryTextColor)),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(top: 2.0),
            child: Icon(Icons.location_on, color: Colors.grey, size: 16),
          ),
          const SizedBox(width: 4),
          Expanded(child: Text(location, style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey[600]))),
        ]),
      ],
    );
  }

  Widget _buildPriceBox(String price, Color airbnbGrey) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('महिनाको भाडा (Monthly Rent)', style: GoogleFonts.outfit(fontSize: 12, color: airbnbGrey)),
            const SizedBox(height: 4),
            RichText(text: TextSpan(children: [
              TextSpan(text: price, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryTextColor)),
              TextSpan(text: ' /mo', style: GoogleFonts.outfit(fontSize: 16, color: airbnbGrey)),
            ])),
          ]),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)), child: Text('Negotiable', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildLocationDetails(String location, Color airbnbGrey) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.directions_outlined, color: AppTheme.brandColor, size: 18),
          const SizedBox(width: 8),
          Text('मुख्य बाटोबाट मात्र ५ मिनेट', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
        const SizedBox(height: 8),
        Text(
          'शान्त टोल, ढल र पिच रोडको सुविधा भएको ठाउँ।',
          style: GoogleFonts.outfit(fontSize: 13, color: airbnbGrey),
        ),
      ],
    );
  }

  Widget _buildNearbyItem(IconData icon, String title, String distance) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(icon, size: 18, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Text('$title: ', style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[800])),
          Expanded(child: Text(distance, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryTextColor));
  }

  Widget _buildEssentialRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.brandColor.withOpacity(0.05), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppTheme.brandColor, size: 20)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF717171))),
            Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, -5))]),
      child: Row(
        children: [
          Container(
            height: 56, width: 56,
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.chat, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), minimumSize: const Size(double.infinity, 56)),
              child: Text('सम्पर्क गर्नुहोस् (Contact Owner)', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
