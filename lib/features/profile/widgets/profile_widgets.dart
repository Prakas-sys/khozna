import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/widgets/khozna_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileHeader extends StatelessWidget {
  final String? fullName;
  final String? avatarUrl;
  final String? qrCodeUrl;
  final String kycStatus;
  final bool isOwner;
  final bool isUploading;
  final VoidCallback onPickImage;
  final VoidCallback? onTapAvatar;

  const ProfileHeader({
    super.key,
    required this.fullName,
    required this.avatarUrl,
    required this.qrCodeUrl,
    required this.kycStatus,
    required this.isOwner,
    required this.isUploading,
    required this.onPickImage,
    this.onTapAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // White Background
      ),
      child: Stack(
        children: [
          // Subtle decorative shapes for white theme
          Positioned(
            top: -20,
            right: -30,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[50],
            ),
          ),
          Positioned(
            bottom: 40,
            left: -20,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[50],
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: GestureDetector(
                onTap: onTapAvatar,
                child: Stack(
                    children: [
                      Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                        child: Container(
                          padding: EdgeInsets.zero,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: Colors.grey[50],
                            child: isUploading
                                ? const CircularProgressIndicator(
                                    color: AppTheme.brandColor,
                                    strokeWidth: 2,
                                  )
                                : avatarUrl != null
                                ? ClipOval(
                                    child: KhoznaImage(
                                      imageUrl: avatarUrl!,
                                      width: 108,
                                      height: 108,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    width: 108,
                                    height: 108,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey[200]!,
                                          Colors.grey[100]!,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Center(
                                      child: SvgPicture.asset(
                                        'assets/icons/Vector profile.svg',
                                        width: 48,
                                        height: 48,
                                        colorFilter: ColorFilter.mode(
                                          Colors.grey[400]!,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: onPickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: AppTheme.brandColor,
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                  ),
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: fullName ?? (isOwner ? 'Owner' : 'Guest'),
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1A1A1A), // Black text for white header
                        ),
                      ),
                      if (kycStatus == 'verified')
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.verified_rounded,
                              color: AppTheme.brandColor,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullQR(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                children: [
                   ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: KhoznaImage(
                      imageUrl: qrCodeUrl!,
                      width: 280,
                      height: 280,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your Payout QR',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Show this to receive instant payments',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VerificationCard extends StatelessWidget {
  final String kycStatus;
  final VoidCallback onTap;

  const VerificationCard({
    super.key,
    required this.kycStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isVerified = kycStatus == 'verified';
    final bool isPending = kycStatus == 'pending';
    final bool isRejected = kycStatus == 'rejected';

    final Color mainColor = isVerified
        ? Colors.green.shade700
        : (isPending ? Colors.orange.shade800 : Colors.red.shade700);

    final Color bgColorStart = isVerified
        ? Colors.green.shade50
        : (isPending ? Colors.orange.shade50 : Colors.red.shade50);

    final Color bgColorEnd = isVerified
        ? Colors.green.shade100
        : (isPending ? Colors.orange.shade100 : Colors.red.shade100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bgColorStart, bgColorEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVerified
                  ? Icons.verified_user_rounded
                  : (isPending
                        ? Icons.pending_actions_rounded
                        : Icons.gpp_maybe_rounded),
              color: mainColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (isVerified
                      ? 'Profile Verified'
                      : (isPending
                            ? 'Pending KYC'
                            : (isRejected
                                  ? 'KYC Rejected'
                                  : 'Verify Identity'))).toUpperCase(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
                if (!isVerified)
                  Text(
                    isPending
                          ? '(प्रमाणीकरण हुँदैछ)'
                          : (isRejected
                                ? '(अस्वीकृत)'
                                : '(पहिचान प्रमाणित)'),
                    style: GoogleFonts.mukta(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.1,
                    ),
                  ),
              ],
            ),
          ),
          if (!isVerified && !isPending)
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.brandColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isRejected ? 'Retry' : 'Verify',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PostPropertyCard extends StatelessWidget {
  final Animation<double> shimmerAnimation;
  final VoidCallback onPost;

  const PostPropertyCard({
    super.key,
    required this.shimmerAnimation,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white, // White Background for card
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2), // Perfected border
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Shimmer effect removed as requested, but 3D image restored
            Positioned(
              right: -100,
              bottom: -130,
              child: Image.asset(
                'assets/images/tiny house.png',
                width: 386,
                height: 386,
                fit: BoxFit.contain,
              ),
            ),
            // Main content row
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 70, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'READY TO RENT OUT',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF1A1A1A), // Black Text
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'आफ्नो प्रोपर्टी लिस्ट गर्नुहोस्',
                    style: GoogleFonts.notoSansDevanagari(
                      color: Colors.grey[700], // Darker Grey Subtitle
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: onPost,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.brandColor, // Blue Button
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'List Now',
                        style: GoogleFonts.inter(
                          color: Colors.white, // White Font
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
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
    );
  }
}

class ProfileMenuSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const ProfileMenuSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 6),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black38,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2), // Perfect border
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02), // Subtler shadow for 60% neutral background
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(children: items),
          ),
        ),
      ],
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  final IconData? icon;
  final String? svgPath;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? color;

  const ProfileMenuItem({
    super.key,
    this.icon,
    this.svgPath,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[100], // Neutral background for icons
          shape: BoxShape.circle,
        ),
        child: svgPath != null
            ? SvgPicture.asset(
                svgPath!,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  color ?? const Color(0xFF1A1A1A), // Black icons
                  BlendMode.srcIn,
                ),
              )
            : Icon(icon ?? Icons.person_outline, color: color ?? const Color(0xFF1A1A1A), size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1E1E1E),
          letterSpacing: -0.3,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.grey[500],
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: Colors.grey,
        ),
      ),
    );
  }
}
