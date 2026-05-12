import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/widgets/khozna_image.dart';
import 'package:flutter/services.dart';

class ProfileHeader extends StatelessWidget {
  final String? fullName;
  final String? avatarUrl;
  final String kycStatus;
  final bool isOwner;
  final bool isUploading;
  final VoidCallback onPickImage;

  const ProfileHeader({
    super.key,
    required this.fullName,
    required this.avatarUrl,
    required this.kycStatus,
    required this.isOwner,
    required this.isUploading,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.brandColor, AppTheme.brandColor.withOpacity(0.8)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative bubbles
          Positioned(
            top: -20,
            right: -30,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -20,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white.withOpacity(0.08),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.5),
                              Colors.white.withOpacity(0.2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
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
                          padding: const EdgeInsets.all(2),
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
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 54,
                                      color: Colors.grey[400],
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
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: fullName ?? (isOwner ? 'Owner' : 'Guest'),
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (kycStatus == 'verified')
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.verified_rounded,
                              color: Colors.white,
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

    Color mainColor = isVerified
        ? Colors.green
        : (isRejected ? Colors.red : Colors.orange);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: mainColor.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: mainColor.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isVerified
                      ? Colors.green.shade50
                      : (isRejected
                            ? Colors.red.shade50
                            : Colors.orange.shade50),
                  isVerified
                      ? Colors.green.shade100
                      : (isRejected
                            ? Colors.red.shade100
                            : Colors.orange.shade100),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVerified
                  ? Icons.verified_user_rounded
                  : (isPending
                        ? Icons.hourglass_empty_rounded
                        : (isRejected
                              ? Icons.error_outline_rounded
                              : Icons.gpp_maybe_rounded)),
              color: isVerified
                  ? Colors.green.shade700
                  : (isRejected ? Colors.red.shade700 : Colors.orange.shade700),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified
                      ? 'Profi\u200cle Verified (प्रमाणित)'
                      : (isPending
                            ? 'Pending KYC (प्रमाणीकरण हुँदैछ)'
                            : (isRejected
                                  ? 'KYC Rejected (अस्वीकृत)'
                                  : 'Verify Identity (पहिचान प्रमाणित)')),
                  style: GoogleFonts.mukta(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                ),
                Text(
                  isVerified
                      ? 'तपाईंको पहिचान प्रमाणित भयो।'
                      : (isPending
                            ? 'तपाईंको कागजातहरू जाँच हुँदैछ।'
                            : (isRejected
                                  ? 'कागजात अस्वीकृत भयो। फेरि प्रयास गर्नुहोस्।'
                                  : 'घरभाडामा राख्न केवाईसी भेरिफाइ गर्नुहोस्। 👉')),
                  style: GoogleFonts.mukta(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    height: 1.2,
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
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.brandColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.brandColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  isRejected ? 'Retry  ➔' : 'Verify  ➔',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF0077AA), Color(0xFF00A3E1)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        // Shadow removed as requested
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
                    'Ready to Rent Out?',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'आफ्नो प्रोपर्टी लिस्ट गर्नुहोस्',
                    style: GoogleFonts.mukta(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: onPost,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        // Button shadow removed
                      ),
                      child: Text(
                        'Post Now',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF0077AA),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
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
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? color;

  const ProfileMenuItem({
    super.key,
    required this.icon,
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
          color: (color ?? AppTheme.brandColor).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? AppTheme.brandColor, size: 20),
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
