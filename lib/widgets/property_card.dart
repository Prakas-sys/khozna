import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/chat_screen.dart';
import '../screens/property_details_screen.dart';
import '../theme/app_theme.dart';
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
                padding: const EdgeInsets.fromLTRB(12, 1, 12, 0),
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
                                text: price,
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
                    // Location + Amenity icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              color: AppTheme.brandColor,
                              size: 13,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              location,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Column(
                              children: [
                                const Icon(
                                  Icons.bed_outlined,
                                  color: AppTheme.brandColor,
                                  size: 14,
                                ),
                                Text(
                                  'Bed',
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                const Icon(
                                  Icons.directions_car_outlined,
                                  color: AppTheme.brandColor,
                                  size: 14,
                                ),
                                Text(
                                  'Parking',
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                const Icon(
                                  Icons.wifi,
                                  color: AppTheme.brandColor,
                                  size: 14,
                                ),
                                Text(
                                  'Wifi',
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
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
}
