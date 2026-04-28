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
        border: Border.all(
          color: mainColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isVerified ? Colors.green.shade50 : (isRejected ? Colors.red.shade50 : Colors.orange.shade50),
                  isVerified ? Colors.green.shade100 : (isRejected ? Colors.red.shade100 : Colors.orange.shade100),
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
                        : (isRejected ? Icons.error_outline_rounded : Icons.gpp_maybe_rounded)),
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
                      ? 'Profile Verified'
                      : (isPending 
                          ? 'Pending Verification' 
                          : (isRejected ? 'Verification Rejected' : 'Verify Identity')),
                                    style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.black87,
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
      height: 175,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F9FE),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A3E1).withOpacity(0.10),
            blurRadius: 30,
            offset: const Offset(0, 10),
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
            // Text + Button — left column, icon above title
            Positioned(
              left: 22,
              top: 22,
              bottom: 22,
              right: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon badge
                  Container(
                    padding: const EdgeInsets.all(9),
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

                  // Title — full column width, no row competition
                  Text(
                    'Ready to Rent?',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'List your property easily',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Spacer(),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Post Property',
                        style: GoogleFonts.inter(
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

            // House — pushed to right edge, width forced to fill the space
            Positioned(
              right: -30,
              bottom: 0,
              width: 165,
              child: Image.asset(
                'assets/images/tiny house.png',
                height: 170,
                fit: BoxFit.fitHeight,
              ),
            ),

            // Shimmer sweep
            AnimatedBuilder(
              animation: shimmerAnimation,
              builder: (context, child) {
                return Positioned.fill(
                  child: FractionallySizedBox(
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
                  ),
                );
              },
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
