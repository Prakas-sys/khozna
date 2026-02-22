import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'filter_results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  double _priceValue = 5000;
  final List<String> _recentSearches = ['Baluwatar', '2BHK Sanepa', 'Flat under 20k', 'Baneshwor Room'];

  @override
  Widget build(BuildContext context) {
    const Color airbnbGrey = Color(0xFF717171);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Where are you looking?',
              hintStyle: GoogleFonts.outfit(color: airbnbGrey, fontSize: 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.brandColor),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price Range (भाडाको सीमा)', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Min: Rs. 2,000', style: GoogleFonts.outfit(color: airbnbGrey)),
                      Text('Max: Rs. 1,00,000+', style: GoogleFonts.outfit(color: airbnbGrey)),
                    ],
                  ),
                  Slider(
                    value: _priceValue,
                    min: 2000,
                    max: 100000,
                    activeColor: AppTheme.brandColor,
                    onChanged: (val) => setState(() => _priceValue = val),
                  ),
                  Text(
                    'Up to Rs. ${_priceValue.toInt()}',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.brandColor, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('भर्खरै खोजिएका (Recently Searched)', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: Text('Clear', style: GoogleFonts.outfit(color: airbnbGrey))),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 12,
              children: _recentSearches.map((search) => _buildRecentTag(search)).toList(),
            ),
            const SizedBox(height: 40),
            Text('लोकप्रिय ठाउँहरू (Popular Areas)', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildAreaItem('Baluwatar, Kathmandu', '450+ Listings'),
            _buildAreaItem('Sanepa, Lalitpur', '320+ Listings'),
            _buildAreaItem('Baneshwor, Kathmandu', '580+ Listings'),
            _buildAreaItem('Jhamsikhel, Lalitpur', '210+ Listings'),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => FilterResultsScreen(priceRange: 'Up to Rs. ${_priceValue.toInt()}')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('Apply Filters & Search', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey[300]!)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.history, size: 14, color: Colors.grey), const SizedBox(width: 8), Text(text, style: GoogleFonts.outfit(fontSize: 13, color: Colors.black87))]),
    );
  }

  Widget _buildAreaItem(String title, String count) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.brandColor.withOpacity(0.05), shape: BoxShape.circle), child: const Icon(Icons.location_on_outlined, color: AppTheme.brandColor, size: 20)),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      subtitle: Text(count, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () {},
    );
  }
}
