import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color airbnbGrey = Color(0xFF717171);

    final List<Map<String, dynamic>> myListings = [
      {
        'id': '101',
        'title': 'Modern Villa in Baluwatar',
        'price': '1,200',
        'image': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80',
        'status': 'Verified',
        'views': '1.2K',
        'inquiries': '12',
      },
      {
        'id': '102',
        'title': 'Cozy 2BHK Flat',
        'price': '450',
        'image': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80',
        'status': 'Pending Review',
        'views': '145',
        'inquiries': '2',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'मेरो प्रोपर्टी (My Listings)',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: myListings.isEmpty 
        ? _buildEmptyState(context)
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: myListings.length,
            itemBuilder: (context, index) {
              return _buildListingCard(context, myListings[index], airbnbGrey);
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppTheme.brandColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('नयाँ थप्नुहोस् (Add New)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildListingCard(BuildContext context, Map<String, dynamic> item, Color airbnbGrey) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(item['image'], width: 80, height: 80, fit: BoxFit.cover),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('रू ${item['price']} /month', style: GoogleFonts.inter(color: AppTheme.brandColor, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _buildStatusBadge(item['status']),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(Icons.visibility_outlined, '${item['views']} Views'),
                _buildStatItem(Icons.chat_bubble_outline, '${item['inquiries']} Chats'),
                Row(
                  children: [
                    IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey)),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isVerified = status == 'Verified';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isVerified ? Icons.verified : Icons.access_time, size: 12, color: isVerified ? Colors.green : Colors.orange),
          const SizedBox(width: 4),
          Text(
            status,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isVerified ? Colors.green : Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text('No Listings Yet', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Start by adding your first property.', style: GoogleFonts.inter(color: Colors.grey)),
        ],
      ),
    );
  }
}
