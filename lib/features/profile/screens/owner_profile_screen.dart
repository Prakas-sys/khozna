import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:intl/intl.dart';
import 'package:khozna/core/models/review_model.dart';
import 'package:khozna/features/profile/repositories/vote_repository.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';

class OwnerProfileScreen extends StatefulWidget {
  final String ownerId;
  final String name;
  final String avatar;
  final bool isVerified;
  final String location;
  final int totalListings;

  const OwnerProfileScreen({
    super.key,
    required this.ownerId,
    required this.name,
    required this.avatar,
    this.isVerified = true,
    required this.location,
    required this.totalListings,
  });

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  int _voteCount = 0;
  bool _isLoadingVotes = true;
  String _joinedDate = '...';
  late String _realLocation;
  List<ReviewModel> _ownerReviews = [];
  bool _isLoadingReviews = true;

  String? _bio;
  String? _phoneNumber;
  String? _email;
  String? _userType;
  String? _organization;
  bool _isProfileVerified = false;

  @override
  void initState() {
    super.initState();
    _realLocation = widget.location;
    _isProfileVerified = widget.isVerified;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final results = await Future.wait<dynamic>([
        VoteRepository.getVoteCount(widget.ownerId),
        Supabase.instance.client
            .from('profiles')
            .select('created_at, area_name, bio, phone_number, email, user_type, organization, is_verified')
            .eq('id', widget.ownerId)
            .maybeSingle(),
        BookingRepository.fetchReviewsForOwner(widget.ownerId),
      ]);

      if (mounted) {
        setState(() {
          _voteCount = results[0] as int;
          final profileData = results[1] as Map<String, dynamic>?;
          if (profileData != null) {
            if (profileData['created_at'] != null) {
              final date = DateTime.parse(profileData['created_at']);
              _joinedDate = DateFormat('MMMM yyyy').format(date);
            }
            if (profileData['area_name'] != null && profileData['area_name'].toString().isNotEmpty) {
              _realLocation = profileData['area_name'].toString();
            }
            _bio = profileData['bio'] as String?;
            _phoneNumber = profileData['phone_number'] as String?;
            _email = profileData['email'] as String?;
            _userType = profileData['user_type'] as String?;
            _organization = profileData['organization'] as String?;
            _isProfileVerified = (profileData['is_verified'] as bool?) ?? widget.isVerified;
          }
          _ownerReviews = results[2] as List<ReviewModel>;
          _isLoadingReviews = false;
          _isLoadingVotes = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      if (mounted) {
        setState(() {
          _isLoadingVotes = false;
          _isLoadingReviews = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double avgRating = _ownerReviews.isNotEmpty
        ? (_ownerReviews.map((e) => e.rating).reduce((a, b) => a + b) / _ownerReviews.length)
        : 4.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Airbnb-style Host Passport Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    // Passport Left: Large Photo with overlapping verified badge
                    Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [AppTheme.brandColor, Color(0xFF00C853)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 46,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  backgroundImage: (widget.avatar.isNotEmpty && !widget.avatar.contains('pravatar.cc'))
                                      ? CachedNetworkImageProvider(widget.avatar)
                                      : null,
                                  child: (widget.avatar.isEmpty || widget.avatar.contains('pravatar.cc'))
                                      ? const Icon(Icons.person, size: 44, color: Colors.grey)
                                      : null,
                                ),
                              ),
                              if (_isProfileVerified)
                                Positioned(
                                  bottom: 0,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified_rounded,
                                      color: const Color(0xFF00C853), // Green
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.name,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.brandColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Verified Owner',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.brandColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(height: 120, width: 1, color: Colors.grey.shade200),
                    const SizedBox(width: 16),
                    // Passport Right: Passport Stats Blocks
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPassportStat('${_ownerReviews.length}', 'Votes'),
                          const SizedBox(height: 16),
                          _buildPassportStat(
                            avgRating.toStringAsFixed(1),
                            'Rating',
                            suffixIcon: const Icon(Icons.star_rounded, color: Colors.black, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // About the Owner Section
            Text(
              'About ${widget.name}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_bio != null && _bio!.trim().isNotEmpty) ...[
                    Text(
                      _bio!,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        color: const Color(0xFF475569),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                  ],
                  if (_realLocation.isNotEmpty && _realLocation != 'Unknown') ...[
                    _buildAboutMetaItem(Icons.location_on_outlined, _realLocation),
                    const SizedBox(height: 12),
                  ],
                  if (_organization != null && _organization!.isNotEmpty) ...[
                    _buildAboutMetaItem(Icons.work_outline_rounded, _organization!),
                    const SizedBox(height: 12),
                  ],
                  _buildAboutMetaItem(Icons.calendar_month_outlined, 'Joined in $_joinedDate'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Confirmed Information Section
            Text(
              '${widget.name}\'s Confirmed Info',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  _buildConfirmedInfoRow('Identity Verified', true),
                  const SizedBox(height: 14),
                  _buildConfirmedInfoRow('Phone Number Confirmed', (widget.name.toLowerCase().contains('khozna') || (_phoneNumber != null && _phoneNumber!.isNotEmpty))),
                  const SizedBox(height: 14),
                  _buildConfirmedInfoRow('Email Address Confirmed', (widget.name.toLowerCase().contains('khozna') || (_email != null && _email!.isNotEmpty))),
                  const SizedBox(height: 14),
                  _buildConfirmedInfoRow('Active Property Listings', widget.totalListings > 0 || widget.name.toLowerCase().contains('khozna')),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Send Message & Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => chat_page.ChatScreen(
                              ownerId: widget.ownerId,
                              name: widget.name,
                              avatar: widget.avatar,
                              online: true,
                            ),
                          ),
                        );
                      },
                      icon: SvgPicture.asset(
                        'assets/icons/Message neww.svg',
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                      label: Text(
                        'Send Message',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.black87, size: 20),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      // Share implementation
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            const Divider(),
            const SizedBox(height: 24),

            _buildReviewsSection(),
            const SizedBox(height: 40),

            // Safety Section
            Center(
              child: TextButton.icon(
                onPressed: () => _showReportDialog(context),
                icon: Icon(Icons.gpp_maybe_rounded, size: 16, color: Colors.grey.shade400),
                label: Text(
                  'Report this landlord',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPassportStat(String value, String label, {Widget? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1,
              ),
            ),
            if (suffixIcon != null) ...[
              const SizedBox(width: 4),
              suffixIcon,
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutMetaItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmedInfoRow(String text, bool isConfirmed) {
    return Row(
      children: [
        Icon(
          isConfirmed ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
          color: isConfirmed ? const Color(0xFF00C853) : Colors.grey[300],
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isConfirmed ? const Color(0xFF1E293B) : Colors.grey[500],
            fontWeight: isConfirmed ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showReportDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Report ${widget.name}',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Why are you reporting this user? Your report helps us keep Khozna safe.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter reason (e.g. Scammer, Abusive)...',
                hintStyle: GoogleFonts.inter(fontSize: 13),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              final reporterId =
                  Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';

              try {
                await SupabaseService.reportUser(
                  widget.ownerId,
                  reporterId,
                  reasonController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report submitted. Thank you.'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Submit Report',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatGrid(String label, IconData icon, {String? subLabel, Color? iconColor, Color? bgColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor ?? const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? const Color(0xFF64748B), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subLabel != null)
                Text(
                  subLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRowItem(String label, String value, IconData? icon, {bool isJoined = false}) {
    return Column(
      children: [
        if (icon != null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00A3FF).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF00A3FF), size: 20),
          ),
        if (icon != null) const SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isJoined ? 16 : 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: isJoined ? GoogleFonts.notoSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.grey[500],
          ) : GoogleFonts.mukta(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryButton(String label, IconData icon) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    if (_isLoadingReviews) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.brandColor),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'पाहुनाहरूको सिफारिस (Guest Recommendations)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            if (_ownerReviews.isNotEmpty)
              Text(
                '★ ${(_ownerReviews.map((e) => e.rating).reduce((a, b) => a + b) / _ownerReviews.length).toStringAsFixed(1)} (${_ownerReviews.length})',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.amber[800],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_ownerReviews.isEmpty)
           const SizedBox.shrink()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _ownerReviews.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildReviewCard(_ownerReviews[index]);
            },
          ),
      ],
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final String name = review.reviewerName ?? 'Khozna Renter';
    final String avatar = review.reviewerAvatar ?? '';
    final String dateStr = DateFormat('MMMM yyyy').format(review.createdAt);
    final bool isKycVerified = review.reviewerKycStatus == 'verified';

    // Parse out tags like [Clean Room] or [सफा कोठा] from comment
    final comment = review.comment ?? '';
    final List<String> tags = [];
    String description = comment;
    
    final tagRegex = RegExp(r'\[(.*?)\]');
    final matches = tagRegex.allMatches(comment);
    for (var m in matches) {
      if (m.group(1) != null) {
        tags.add(m.group(1)!);
      }
    }
    description = comment.replaceAll(tagRegex, '').trim();

    final isPositive = review.rating >= 3;
    final tagBgColor = isPositive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final tagTextColor = isPositive ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final tagBorderColor = isPositive ? const Color(0xFFC8E6C9) : const Color(0xFFFFCDD2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFF1F5F9),
                backgroundImage: (avatar.isNotEmpty && !avatar.contains('pravatar.cc'))
                    ? NetworkImage(avatar)
                    : null,
                child: (avatar.isEmpty || avatar.contains('pravatar.cc'))
                    ? const Icon(Icons.person, size: 16, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isKycVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            color: Colors.blue,
                            size: 15,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (starIdx) {
                  return Icon(
                    starIdx < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 13,
                  );
                }),
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tagBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tagBorderColor, width: 0.8),
                ),
                child: Text(
                  t,
                  style: GoogleFonts.mukta(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: tagTextColor,
                  ),
                ),
              )).toList(),
            ),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFF334155),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
