import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/supabase_service.dart';
import '../widgets/property_card.dart';

class SavedPropertiesScreen extends StatefulWidget {
  const SavedPropertiesScreen({super.key});

  @override
  State<SavedPropertiesScreen> createState() => _SavedPropertiesScreenState();
}

class _SavedPropertiesScreenState extends State<SavedPropertiesScreen> {
  List<Map<String, dynamic>> _savedProperties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSavedProperties();
  }

  Future<void> _fetchSavedProperties() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.getSavedProperties();
    setState(() {
      _savedProperties = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'सुरक्षित गरिएका (Saved)',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTextColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.brandColor),
            )
          : RefreshIndicator(
              onRefresh: _fetchSavedProperties,
              color: AppTheme.brandColor,
              child: _savedProperties.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      itemCount: _savedProperties.length,
                      itemBuilder: (context, index) {
                        final savedItem = _savedProperties[index];
                        final p = savedItem['properties'];
                        if (p == null) return const SizedBox.shrink();

                        final List joinImages = p['property_images'] ?? [];
                        final List arrayImages = p['images'] ?? [];
                        List<String> finalImages = [];

                        if (joinImages.isNotEmpty) {
                          finalImages = joinImages
                              .map((i) => i['image_url'].toString())
                              .toList();
                        } else if (arrayImages.isNotEmpty) {
                          finalImages = arrayImages
                              .map((i) => i.toString())
                              .toList();
                        }

                        final String mainImage = finalImages.isNotEmpty
                            ? finalImages[0]
                            : 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: PropertyCard(
                            id: p['id'].toString(), // Ensure string
                            imageUrl: mainImage,
                            title: p['title'] ?? 'Property',
                            location: p['area_name'] ?? 'Location',
                            price: p['price'].toString(),
                            bedrooms: p['bedrooms'] ?? 0,
                            bathrooms: p['bathrooms'] ?? 0,
                            area: (p['sq_ft'] ?? 0).toString(),
                            ownerId: p['owner_id'] ?? '',
                            images: finalImages,
                            amenities: List<String>.from(p['amenities'] ?? []),
                            houseRules: List<String>.from(
                              p['house_rules'] ?? [],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bookmark_border_rounded,
                  size: 48,
                  color: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No saved properties',
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Properties you save will appear here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
