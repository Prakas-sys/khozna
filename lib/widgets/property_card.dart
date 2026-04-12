import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/chat_screen.dart';
import '../screens/property_details_screen.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'favourite_button.dart';

class PropertyCard extends StatelessWidget {
  final String id;
  final String imageUrl;
  final String title;
  final String location;
  final String price;
  final int bedrooms;
  final int bathrooms;
  final String area;
  final String floor;
  final String description;
  final List<String> images;
  final String ownerId;
  final String status;
  final List<String> amenities;

  const PropertyCard({
    super.key,
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.price,
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.area = '0',
    this.floor = 'N/A',
    this.description = '',
    this.images = const [],
    this.ownerId = '',
    this.status = 'available',
    this.amenities = const [],
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PropertyDetailsScreen(
              id: id,
              imageUrl: imageUrl,
              images: images,
              title: title,
              location: location,
              price: price,
              bedrooms: bedrooms,
              bathrooms: bathrooms,
              area: area,
              floor: floor,
              description: description,
              ownerId: ownerId,
              status: status,
              amenities: amenities,
            ),
          ),
        );
      },
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF2F2F2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Image (unchanged height) ---
              Stack(
                children: [
                  SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: Hero(
                      tag: id,
                      child: Image.network(imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                  // Status Badges
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Builder(
                      builder: (context) {
                        final isBooked = status == 'booked';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isBooked ? Colors.red : const Color(0xFF2ECC71),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            isBooked ? 'Booked' : 'For Rent',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                  // Favourite button
                  Positioned(
                    top: 6,
                    right: 10,
                    child: FavouriteButton(propertyId: id),
                  ),
                ],
              ),
              // --- Content below image ---
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 1, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'रू ${PriceFormatter.format(price)}',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.brandColor,
                                ),
                              ),
                              TextSpan(
                                text: '/mo',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildAmenityItems(),
                    const SizedBox(height: 8),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PropertyDetailsScreen(
                                  id: id,
                                  imageUrl: imageUrl,
                                  images: images,
                                  title: title,
                                  location: location,
                                  price: price,
                                  bedrooms: bedrooms,
                                  bathrooms: bathrooms,
                                  area: area,
                                  floor: floor,
                                  description: description,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.directions_walk, size: 17),
                            label: Text('Visit Now', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brandColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChatScreen(
                                  name: 'Jenny Wilson',
                                  avatar: 'https://i.pravatar.cc/150?img=47',
                                  online: true,
                                ),
                              ),
                            ),
                            icon: SvgPicture.asset(
                              'assets/icons/message.svg',
                              width: 17,
                              height: 17,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                            label: Text(
                              'Message',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brandColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmenityItems() {
    // Top priority icons for the card
    final Map<String, IconData> amenityIcons = {
      'water_melamchi': Icons.water_drop_outlined,
      'parking_bike': Icons.pedal_bike_outlined,
      'parking_car': Icons.directions_car_outlined,
      'sunny_room': Icons.wb_sunny_outlined,
      'hot_water': Icons.hot_tub_outlined,
      'waste_mgmt': Icons.delete_outline,
      'peaceful': Icons.nature_people_outlined,
    };

    List<Widget> items = [];
    
    // 1. Show Location first in the summary row
    // 1. Show Location first in the summary row
    items.add(Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.place_outlined, color: AppTheme.brandColor, size: 13),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    ));

    // 2. Always show Bedroom if count > 0
    if (bedrooms > 0) {
      items.add(_amenityIcon(Icons.bed_outlined, '$bedrooms Bed'));
    }

    // 3. Add priority Kathmandu amenities (up to 1-2 for card brevity)
    int count = 0;
    for (var amenity in amenities) {
      if (count >= 1) break;
      if (amenityIcons.containsKey(amenity)) {
        items.add(_amenityIcon(amenityIcons[amenity]!, _getShortLabel(amenity)));
        count++;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items,
    );
  }

  String _getShortLabel(String key) {
    switch (key) {
      case 'water_melamchi': return 'Water';
      case 'parking_bike': return 'Bike';
      case 'parking_car': return 'Car';
      case 'sunny_room': return 'Sunny';
      case 'hot_water': return 'Hot';
      case 'waste_mgmt': return 'Waste';
      case 'peaceful': return 'Quiet';
      default: return '';
    }
  }

  Widget _amenityIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.brandColor, size: 14),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8,
            color: Colors.grey[700],
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}
