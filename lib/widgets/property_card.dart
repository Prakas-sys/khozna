import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../screens/property_details_screen.dart';
import '../screens/login_screen.dart';
import '../screens/kyc_screen.dart';
import '../screens/chat_screen.dart';
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
  final bool isFullWidth;
  final String ownerId;
  final String status;
  final String ownerName;
  final String ownerAvatar;

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
    this.isFullWidth = false,
    this.ownerId = '',
    this.status = 'available',
    this.ownerName = 'Khozna Owner',
    this.ownerAvatar = 'https://i.pravatar.cc/150?img=47',
  });

  Future<void> _checkAuthAndNavigate(BuildContext context, Widget screen) async {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final bool isBooked = status == 'booked';
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bool isMyProperty = ownerId == currentUserId;

    return GestureDetector(
      onTap: () async {
        if (FirebaseAuth.instance.currentUser == null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          return;
        }

        final userId = FirebaseAuth.instance.currentUser!.uid;
        final profile = await Supabase.instance.client.from('profiles').select('kyc_status').eq('id', userId).single();
        
        if (profile['kyc_status'] != 'verified') {
          if (context.mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const KycScreen()));
          }
        } else {
          if (context.mounted) {
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
                ),
              ),
            );
          }
        }
      },
      child: Container(
        width: isFullWidth ? double.infinity : 260,
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
              Stack(
                children: [
                  ColorFiltered(
                    colorFilter: isBooked 
                        ? ColorFilter.mode(Colors.black.withValues(alpha: 0.2), BlendMode.darken)
                        : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                    child: SizedBox(
                      height: 190,
                      width: double.infinity,
                      child: Image.network(imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isMyProperty 
                            ? Colors.blue 
                            : isBooked 
                                ? Colors.red 
                                : const Color(0xFF2ECC71),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        isMyProperty 
                            ? 'Your Ad (तपाईंको विज्ञापन)' 
                            : isBooked 
                                ? 'Booked' 
                                : 'For Rent',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (isMyProperty)
                    Positioned(
                      top: 10,
                      left: 75,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'Your Ad',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 10,
                    child: FavouriteButton(propertyId: id),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 1, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
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
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.brandColor,
                                ),
                              ),
                              TextSpan(
                                text: '/mo',
                                style: GoogleFonts.outfit(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.place_outlined, color: AppTheme.brandColor, size: 13),
                            const SizedBox(width: 2),
                            Text(
                              location,
                              style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _buildInfoIcon(Icons.bed_outlined, 'Bed'),
                            const SizedBox(width: 8),
                            _buildInfoIcon(Icons.directions_car_outlined, 'Parking'),
                            const SizedBox(width: 8),
                            _buildInfoIcon(Icons.wifi, 'Wifi'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Action Buttons (Hidden if booked)
                    if (!isBooked)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _checkAuthAndNavigate(
                              context,
                              PropertyDetailsScreen(
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
                              ),
                            ),
                            icon: const Icon(Icons.directions_walk, size: 17),
                            label: Text(
                              'Visit Now',
                              style: GoogleFonts.outfit(
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isMyProperty ? null : () => _checkAuthAndNavigate(
                              context,
                              ChatScreen(
                                name: ownerName,
                                avatar: ownerAvatar,
                                online: true,
                              ),
                            ),
                            icon: SvgPicture.asset(
                              'assets/icons/message.svg',
                              width: 17,
                              height: 17,
                              colorFilter: ColorFilter.mode(
                                isMyProperty ? Colors.grey : Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                            label: Text(
                              'Message',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isMyProperty ? Colors.grey[200] : AppTheme.brandColor,
                              foregroundColor: isMyProperty ? Colors.grey : Colors.white,
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
                    )
                    else 
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Already Booked ❌',
                          style: GoogleFonts.outfit(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
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

  Widget _buildInfoIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.brandColor, size: 14),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 8,
            color: Colors.grey[700],
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}
