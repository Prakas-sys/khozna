import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/widgets/property_card.dart';
import 'package:khozna/core/models/property_model.dart';

class OwnerListingsScreen extends StatefulWidget {
  final String ownerId;
  final String ownerName;

  const OwnerListingsScreen({
    super.key,
    required this.ownerId,
    required this.ownerName,
  });

  @override
  State<OwnerListingsScreen> createState() => _OwnerListingsScreenState();
}

class _OwnerListingsScreenState extends State<OwnerListingsScreen> {
  List<Map<String, dynamic>> _listings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOwnerListings();
  }

  Future<void> _fetchOwnerListings() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('properties')
          .select(
            '*, property_images(image_url), profiles:owner_id(full_name, avatar_url, kyc_status)',
          )
          .eq('owner_id', widget.ownerId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _listings = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching owner listings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String firstName = widget.ownerName.split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          '$firstName\'s Listings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.brandColor),
            )
          : _listings.isEmpty
              ? _buildEmptyState(firstName)
              : RefreshIndicator(
                  onRefresh: _fetchOwnerListings,
                  color: AppTheme.brandColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _listings.length,
                    itemBuilder: (context, index) {
                      final item = _listings[index];
                      final property = Property.fromMap(item);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: PropertyCard(
                          property: property,
                          width: double.infinity,
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(String firstName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_work_rounded,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No active listings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$firstName does not have any active property\nlistings available right now.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
