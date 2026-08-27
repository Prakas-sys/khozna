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
    this.isVerified = false,
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
  int _yearsHosting = 0;
  late String _realLocation;
  List<ReviewModel> _ownerReviews = [];
  bool _isLoadingReviews = true;

  String? _bio;
  String? _phoneNumber;
  String? _email;
  String? _userType;
  String? _organization;
  String? _fetchedAvatar;
  bool _isProfileVerified = false;
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;

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
            .select(
              'created_at, area_name, bio, phone_number, email, user_type, organization, avatar_url, kyc_status, is_verified',
            )
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
              final now = DateTime.now();
              _yearsHosting = now.year - date.year;
              if (_yearsHosting == 0) _yearsHosting = 1;
            }
            if (profileData['area_name'] != null &&
                profileData['area_name'].toString().isNotEmpty) {
              _realLocation = profileData['area_name'].toString();
            }
            _bio = profileData['bio'] as String?;
            _phoneNumber = profileData['phone_number'] as String?;
            _email = profileData['email'] as String?;
            _userType = profileData['user_type'] as String?;
            _organization = profileData['organization'] as String?;
            if (profileData['avatar_url'] != null &&
                profileData['avatar_url'].toString().isNotEmpty) {
              _fetchedAvatar = profileData['avatar_url'].toString();
            }
            final String profStatus = (profileData['kyc_status'] ?? '')
                .toString()
                .trim()
                .toLowerCase();
            final bool dbVerified = profStatus == 'verified' ||
                profStatus == 'approved' ||
                profStatus == 'completed' ||
                profStatus == 'true' ||
                (profileData['is_verified'] == true);

            _isProfileVerified = dbVerified || widget.isVerified;

            _isEmailVerified = _email != null && _email!.trim().isNotEmpty;
            _isPhoneVerified = _phoneNumber != null && _phoneNumber!.trim().isNotEmpty;
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
    final double? avgRating = _ownerReviews.isNotEmpty
        ? (_ownerReviews.map((e) => e.rating).reduce((a, b) => a + b) /
              _ownerReviews.length)
        : null;
    final String avatarUrl =
        (_fetchedAvatar != null && _fetchedAvatar!.isNotEmpty)
        ? _fetchedAvatar!
        : widget.avatar;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            floating: false,
            pinned: true,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.black87,
                  size: 16,
                ),
              ),
            ),
            title: Text(
              widget.name.split(' ').first,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            centerTitle: true,
            actions: [
              GestureDetector(
                onTap: () => _showReportDialog(context),
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.flag_outlined,
                      color: Colors.black54,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Profile Card ────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: AppTheme.buildAvatarWidget(
                              avatarUrl: avatarUrl,
                              radius: 52,
                              name: widget.name,
                            ),
                          ),
                          if (_isProfileVerified)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_rounded,
                                  color: AppTheme.brandColor,
                                  size: 24,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Name
                      Text(
                        widget.name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Joined date
                      Text(
                        'Joined $_joinedDate',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── 3-Stat Row ──────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Reviews
                            _buildBigStat(
                              value: '${_ownerReviews.length}',
                              label: 'Reviews',
                            ),
                            _buildStatDivider(),
                            // Rating
                            _buildBigStat(
                              value: avgRating != null
                                  ? avgRating.toStringAsFixed(1)
                                  : '–',
                              label: 'Rating',
                              icon: avgRating != null
                                  ? const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 18,
                                    )
                                  : null,
                            ),
                            _buildStatDivider(),
                            // Years on Khozna
                            _buildBigStat(
                              value: '$_yearsHosting',
                              label: _yearsHosting == 1
                                  ? 'Year on Khozna'
                                  : 'Years on Khozna',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Trust & Verification Section ────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.name.split(' ').first}\'s confirmed info',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Identity verified / not verified
                      _buildVerificationRow(
                        label: 'Identity',
                        isVerified: _isProfileVerified,
                      ),
                      _buildVerificationRow(
                        label: 'Email address',
                        isVerified: _isEmailVerified,
                      ),
                      _buildVerificationRow(
                        label: 'Phone number',
                        isVerified: _isPhoneVerified,
                      ),

                      const SizedBox(height: 28),
                      const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),

                // ── Host Highlights ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About ${widget.name.split(' ').first}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Location
                      if (_realLocation.isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.location_on_outlined,
                          text: 'Lives in $_realLocation',
                        ),

                      // Listings count
                      _buildInfoRow(
                        icon: Icons.home_work_outlined,
                        text:
                            '${widget.totalListings > 0 ? widget.totalListings : 1} ${widget.totalListings == 1 ? 'listing' : 'listings'} on Khozna',
                      ),

                      // Organization
                      if (_organization != null && _organization!.isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.work_outline_rounded,
                          text: _organization!,
                        ),

                      // User type
                      if (_userType != null && _userType!.isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.person_outline_rounded,
                          text: _userType!,
                        ),

                      // Bio
                      if (_bio != null && _bio!.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          _bio!,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            color: const Color(0xFF475569),
                            height: 1.55,
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),
                      const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),

                // ── If NOT verified — warning banner ────────────────────
                if (!_isProfileVerified)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFFCD34D),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFD97706),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This owner\'s identity has not been verified yet. Proceed with caution.',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: const Color(0xFF92400E),
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Message Button ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
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
                        'assets/icons/Vectorproepty card meeasge.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: Text(
                        'Send a Message',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(color: Color(0xFFF1F5F9), thickness: 1),
                ),
                const SizedBox(height: 28),

                // ── Reviews Section ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildReviewsSection(avgRating),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Widget _buildBigStat({
    required String value,
    required String label,
    Widget? icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                height: 1,
              ),
            ),
            if (icon != null) ...[const SizedBox(width: 3), icon],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 36,
      width: 1,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildVerificationRow({
    required String label,
    required bool isVerified,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isVerified ? Icons.check_circle_rounded : Icons.cancel_outlined,
                color: isVerified
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF94A3B8),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          Text(
            isVerified ? 'Verified' : 'Not verified',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: isVerified ? FontWeight.w600 : FontWeight.w500,
              color: isVerified ? const Color(0xFF166534) : const Color(0xFF64748B),
              decoration: isVerified ? TextDecoration.none : TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(double? avgRating) {
    if (_isLoadingReviews) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppTheme.brandColor),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (avgRating != null) ...[
              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                avgRating.toStringAsFixed(1),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              _ownerReviews.isEmpty
                  ? 'No reviews yet'
                  : '${_ownerReviews.length} ${_ownerReviews.length == 1 ? 'Review' : 'Reviews'}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_ownerReviews.isEmpty)
          _buildEmptyReviews()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _ownerReviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _buildReviewCard(_ownerReviews[i]),
          ),
      ],
    );
  }

  Widget _buildEmptyReviews() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No guest reviews yet',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final String name = review.reviewerName ?? 'Khozna Renter';
    final String avatar = review.reviewerAvatar ?? '';
    final String dateStr = DateFormat('MMMM yyyy').format(review.createdAt);
    final bool isKycVerified = review.reviewerKycStatus == 'verified';

    final comment = review.comment ?? '';
    final List<String> tags = [];
    String description = comment;
    final tagRegex = RegExp(r'\[(.*?)\]');
    final matches = tagRegex.allMatches(comment);
    for (var m in matches) {
      if (m.group(1) != null) tags.add(m.group(1)!);
    }
    description = comment.replaceAll(tagRegex, '').trim();

    final isPositive = review.rating >= 3;
    final tagBgColor =
        isPositive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final tagTextColor =
        isPositive ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final tagBorderColor =
        isPositive ? const Color(0xFFC8E6C9) : const Color(0xFFFFCDD2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppTheme.buildAvatarWidget(
                avatarUrl: avatar,
                radius: 18,
                name: review.reviewerName,
              ),
              const SizedBox(width: 12),
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
                              fontWeight: FontWeight.w700,
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
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Star rating
              Row(
                children: List.generate(5, (starIdx) {
                  return Icon(
                    starIdx < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 14,
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
              children: tags
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tagBgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: tagBorderColor, width: 0.8),
                      ),
                      child: Text(
                        t,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: tagTextColor,
                        ),
                      ),
                    ),
                  )
                  .toList(),
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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
