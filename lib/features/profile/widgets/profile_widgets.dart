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
          colors: [
            AppTheme.brandColor,
            AppTheme.brandColor.withOpacity(0.8),
          ],
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        border: Border.all(
          color: mainColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVerified
                  ? Icons.verified_user_rounded
                  : (isPending
                        ? Icons.hourglass_empty_rounded
                        : (isRejected ? Icons.error_outline_rounded : Icons.gpp_maybe_rounded)),
              color: mainColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified
                      ? 'Profile Verified'
                      : (isPending 
                          ? 'Pending Verification' 
                          : (isRejected ? 'Verification Rejected' : 'Verify Identity')),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  isVerified
                      ? 'Your identity has been verified.'
                      : (isPending 
                          ? 'Your documents are being reviewed.' 
                          : (isRejected ? 'Documents rejected. Please try again.' : 'Verify KYC to list your property.')),
                                    style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
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
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.brandColor.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  isRejected ? 'Retry ➔' : 'Verify ➔',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
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
      height: 148,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF1F9FE),
            Color(0xFFE6F4FD),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A3E1).withOpacity(0.12),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Left content column
            Positioned(
              left: 20,
              top: 16,
              bottom: 16,
              right: 135,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.brandColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.home_work_rounded,
                      color: AppTheme.brandColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ready to Rent?',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'List your property easily',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: onPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Post Property',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // House — bleeds off right edge
            Positioned(
              right: -30,
              bottom: 0,
              width: 165,
              child: Image.asset(
                'assets/images/tiny house.png',
                height: 158,
                fit: BoxFit.fitHeight,
              ),
            ),

            // Shimmer sweep
            Positioned.fill(
              child: AnimatedBuilder(
                animation: shimmerAnimation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    widthFactor: 1.5,
                    alignment: Alignment(shimmerAnimation.value, 0.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.4, 0.5, 0.6],
                          colors: [
                            Colors.white.withOpacity(0),
                            Colors.white.withOpacity(0.18),
                            Colors.white.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
          padding: const EdgeInsets.only(left: 12, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF94A3B8),
              letterSpacing: 1.5,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E1E1E),
          letterSpacing: -0.2,
        ),
      ),
      subtitle: Text(
        subtitle,
                style: GoogleFonts.outfit(
          fontSize: 12,
          color: Colors.grey[500],
          fontWeight: FontWeight.w400,
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
