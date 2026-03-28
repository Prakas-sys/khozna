import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class OwnerProfileScreen extends StatelessWidget {
  final String name;
  final String avatar;
  final bool isVerified;
  final String location;
  final int totalListings;

  const OwnerProfileScreen({
    super.key,
    required this.name,
    required this.avatar,
    this.isVerified = true,
    required this.location,
    required this.totalListings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Owner Profile', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(avatar),
                  ),
                  if (isVerified)
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.verified, color: Colors.blue, size: 28),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(name, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                Text(location, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
            const SizedBox(height: 32),
            
            // Stats Row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Listings', totalListings.toString()),
                  _buildStatItem('Experience', '2 Years'),
                  _buildStatItem('Rating', '4.9'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // KYC Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isVerified ? Colors.green.withValues(alpha: 0.05) : Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isVerified ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isVerified ? Colors.green : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(isVerified ? Icons.verified_user : Icons.gpp_maybe, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVerified ? 'KYC Verified' : 'KYC Pending',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: isVerified ? Colors.green[800] : Colors.orange[800]),
                        ),
                        Text(
                          isVerified ? 'Identity is fully verified and trusted.' : 'Owner is in the process of verification.',
                          style: GoogleFonts.inter(fontSize: 12, color: isVerified ? Colors.green[700] : Colors.orange[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: Text('Message Owner', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppTheme.brandColor),
                  ),
                  child: const Icon(Icons.phone_outlined, color: AppTheme.brandColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }
}
