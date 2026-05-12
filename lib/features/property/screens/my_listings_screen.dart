import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/property/screens/add_property_screen.dart';
import 'package:khozna/features/property/screens/edit_property_screen.dart';
import 'package:khozna/widgets/property_card.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/core/guards/auth_guard.dart';

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
    if (user == null) {
      if (mounted) {
        AuthGuard.checkAuth(context);
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('properties')
          .select(
            '*, property_images(image_url), profiles:owner_id(full_name, avatar_url, kyc_status)',
          )
          .eq('owner_id', user!.id)
          .order('status', ascending: true)
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
        title: Text(
          'Delete Property?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        content: Text(
          'This will permanently delete your property listing from Khozna. This action cannot be undone.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Delete Forever',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Premium light grey background
      appBar: AppBar(
        title: Text(
          'My Listings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: -0.5,
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
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.brandColor),
            )
          : _listings.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _fetchListings,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _listings.length,
                itemBuilder: (context, index) {
                  try {
                    return _buildListingCard(_listings[index]);
                  } catch (e) {
                    debugPrint('Error building listing card: $e');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Error loading this listing. Please contact support.',
                              style: GoogleFonts.outfit(
                                color: Colors.red[700],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!await AuthGuard.checkKyc(context)) return;
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
          ).then((_) => _fetchListings());
        },
        backgroundColor: AppTheme.brandColor,
        elevation: 3,
        hoverElevation: 4,
        highlightElevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }


  Widget _buildListingCard(Map<String, dynamic> item) {
    final property = Property.fromMap(item);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: PropertyCard(
        property: property,
        isOwnerView: true,
        onEdit: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditPropertyScreen(property: item),
            ),
          );
          if (result == true) {
            _fetchListings();
          }
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
            child: Icon(
              Icons.home_work_rounded,
              size: 72,
              color: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No active listings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your property listings will appear here\nonce you publish them.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }
}
