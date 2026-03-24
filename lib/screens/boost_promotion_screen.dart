// ============================================================
// BOOST PROMOTION SCREEN — forwards to QR Payment flow
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'qr_payment_screen.dart';

class BoostPromotionScreen extends StatefulWidget {
  final String? propertyId;
  final String? title;
  final String? imageUrl;

  const BoostPromotionScreen({super.key, this.propertyId, this.title, this.imageUrl});

  @override
  State<BoostPromotionScreen> createState() => _BoostPromotionScreenState();
}

class _BoostPromotionScreenState extends State<BoostPromotionScreen> {
  String _selectedTier = 'boost_3d';

  static const _tiers = [
    {'id': 'boost_3d',      'label': 'Boost (3 Days)',  'price': 99,  'priceLabel': 'Rs. 99',  'desc': 'Extra visibility for a short burst.',    'color': Colors.orange, 'icon': Icons.flash_on,    'isPremium': false},
    {'id': 'boost_7d',      'label': 'Boost (7 Days)',  'price': 199, 'priceLabel': 'Rs. 199', 'desc': 'Stay on top longer.',                    'color': Colors.blue,   'icon': Icons.trending_up, 'isPremium': false},
    {'id': 'top_highlight', 'label': 'Top + Highlight', 'price': 399, 'priceLabel': 'Rs. 399', 'desc': 'Maximum attention in all feeds.',        'color': Colors.purple, 'icon': Icons.stars,       'isPremium': true },
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _tiers.firstWhere((t) => t['id'] == _selectedTier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Boost Your Listing', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Hero headline
            Text('Get More Renters, Faster 🚀',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, height: 1.2)),
            const SizedBox(height: 6),
            Text(
              'तपाईंको कोठाको विज्ञापन बढाउनुहोस्! अधिक किरायेदारहरूले देख्न पाउँछन्।',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 24),

            // Property card (shown only when invoked from a listing)
            if (widget.propertyId != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  color: const Color(0xFFF8F9FB),
                ),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.imageUrl ?? 'https://via.placeholder.com/150',
                      width: 60, height: 60, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          width: 60, height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.home, color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(
                    widget.title ?? 'Property',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  )),
                ]),
              ),
              const SizedBox(height: 24),
            ],

            Text('Boost Package छान्नुहोस्',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 14),

            // Tier cards
            ..._tiers.map((tier) {
              final isSelected = _selectedTier == tier['id'];
              final color = tier['color'] as Color;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTier = tier['id'] as String);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isSelected ? color : Colors.grey.shade200,
                        width: isSelected ? 2 : 1),
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))]
                        : [],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(tier['icon'] as IconData, color: color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(tier['label'] as String,
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                              if (tier['isPremium'] == true) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('BEST VALUE',
                                      style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ]),
                            const SizedBox(height: 3),
                            Text(tier['desc'] as String,
                                style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13)),
                          ],
                        ),
                      ),
                      Column(children: [
                        Text(tier['priceLabel'] as String,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Icon(Icons.check_circle, color: color, size: 18),
                        ],
                      ]),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 50),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: ElevatedButton(
            onPressed: () {
              // If no propertyId, go directly to the QR scan screen (Discovery/Dashboard entry)
              // If propertyId exists, go through full 3-step flow
              if (widget.propertyId != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => QrScanPayScreen(
                  propertyId: widget.propertyId!,
                  boostTier: _selectedTier,
                  amount: selected['price'] as int,
                  priceLabel: selected['priceLabel'] as String,
                  label: selected['label'] as String,
                )));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a property to boost from your listing.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pay via QR • ${selected['priceLabel']}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
