import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'add_property_screen.dart';
import '../widgets/property_card.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final User? user = Supabase.instance.client.auth.currentUser;
  List<Map<String, dynamic>> _listings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchListings();
  }

  Future<void> _fetchListings() async {
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('properties')
          .select('*, property_images(image_url)')
          .eq('owner_id', user!.id)
          .order('created_at', ascending: false);
          
      if (mounted) {
        setState(() {
          _listings = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching listings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteListing(String id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete Property?', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20)),
        content: Text('This will permanently delete your property listing from Khozna. This action cannot be undone.', 
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600], height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Permanently Delete', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('properties').delete().eq('id', id);
        _fetchListings(); // Refresh UI
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property deleted permanently.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black),
            children: [
              const TextSpan(text: 'मेरो प्रोपर्टी '),
              TextSpan(
                text: '(My Listings)',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandColor))
          : _listings.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchListings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _listings.length,
                    itemBuilder: (context, index) => _buildListingCard(_listings[index]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPropertyScreen())).then((_) => _fetchListings()),
        backgroundColor: AppTheme.brandColor,
        elevation: 6,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        label: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'नयाँ थप्नुहोस्',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.1,
              ),
            ),
            Text(
              'Add New',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.85),
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> item) {
    final List joinImages = item['property_images'] as List? ?? [];
    final List arrayImages = item['images'] as List? ?? [];
    List<String> finalImages = [];
    
    if (joinImages.isNotEmpty) {
      finalImages = joinImages.map((i) => i['image_url'].toString()).toList();
    } else if (arrayImages.isNotEmpty) {
      finalImages = arrayImages.map((i) => i.toString()).toList();
    }

    final String mainImage = finalImages.isNotEmpty ? finalImages[0] : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: PropertyCard(
        id: item['id'].toString(),
        imageUrl: mainImage,
        title: item['title'] ?? 'Apartment',
        location: item['area_name'] ?? 'Kathmandu',
        price: (item['price'] ?? 0).toString(),
        bedrooms: item['bedrooms'] ?? 0,
        bathrooms: item['bathrooms'] ?? 0,
        area: (item['sq_ft'] ?? 0).toString(),
        floor: item['floor'] ?? 'N/A',
        description: item['description'] ?? '',
        images: finalImages,
        ownerId: item['owner_id'] ?? '',
        amenities: List<String>.from(item['amenities'] ?? []),
        houseRules: List<String>.from(item['house_rules'] ?? []),
        isOwnerView: true,
        views: item['views'] ?? 0,
        onEdit: () {
          // Future Edit implementation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Edit feature coming soon!')),
          );
        },
        onDelete: () => _deleteListing(item['id'].toString()),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.home_work_rounded, size: 72, color: Colors.grey[200]),
          ),
          const SizedBox(height: 24),
          Text(
            'No active listings',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your property listings will appear here\nonce you publish them.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }
}
