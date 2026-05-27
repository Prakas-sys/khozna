import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:khozna/features/profile/widgets/trust_vote_card.dart';
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

  @override
  void initState() {
    super.initState();
    _realLocation = widget.location;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final results = await Future.wait<dynamic>([
        VoteRepository.getVoteCount(widget.ownerId),
        Supabase.instance.client
            .from('profiles')
            .select('created_at, area_name')
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
              _joinedDate = DateFormat.yMMMM().format(date);
            }
            if (profileData['area_name'] != null && profileData['area_name'].toString().isNotEmpty) {
              _realLocation = profileData['area_name'].toString();
            }
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.name,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Top Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar with overlap badge
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: const Color(0xFFF1F5F9),
                              backgroundImage: (widget.avatar.isNotEmpty && !widget.avatar.contains('pravatar.cc'))
                                  ? CachedNetworkImageProvider(widget.avatar)
                                  : null,
                              child: (widget.avatar.isEmpty || widget.avatar.contains('pravatar.cc'))
                                  ? const Icon(Icons.person, size: 40, color: Colors.grey)
                                  : null,
                            ),
                          ),
                          if (widget.isVerified)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF4CAF50),
                                  size: 24,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Info Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.location_on_rounded, color: Colors.grey[400], size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  _realLocation,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(Icons.circle, color: Color(0xFF4CAF50), size: 8),
                                const SizedBox(width: 6),
                                Text(
                                  'Active this week',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Trust Score Section
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00A3FF).withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Premium Glowing Icon
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00A3FF), Color(0xFF0077FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00A3FF).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        // Trust Score Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trust Score',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    _isLoadingVotes ? '...' : '$_voteCount',
                                    style: GoogleFonts.outfit(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _voteCount <= 1 ? 'Total Vote' : 'Total Votes',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[500],
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
                  const SizedBox(height: 32),
                  // Bottom Row of Verifications
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeaderStatGrid(
                          'KYC Verified', 
                          Icons.verified_user_rounded, 
                          iconColor: Colors.green,
                          bgColor: const Color(0xFFE8F5E9),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildHeaderStatGrid('Phone Verified', Icons.phone_android_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats Card (Listings, Trust, Joined)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _buildStatsRowItem(
                      'सूचीहरू (Listings)',
                      widget.totalListings.toString(),
                      null,
                    ),
                  ),
                  Container(height: 40, width: 1, color: const Color(0xFFF1F5F9)),
                  Expanded(
                    child: _buildStatsRowItem(
                      'भरोसा (Trust)',
                      _isLoadingVotes ? '...' : '$_voteCount',
                      null, // Icon removed as requested
                    ),
                  ),
                  Container(height: 40, width: 1, color: const Color(0xFFF1F5F9)),
                  Expanded(
                    child: _buildStatsRowItem(
                      'Joined',
                      _joinedDate,
                      null,
                      isJoined: true,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            GestureDetector(
              onTap: () {
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
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.brandColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/Message neww.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Send Message',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: _buildSecondaryButton('Share Profile', Icons.share_rounded),
            ),

            const SizedBox(height: 32),
            _buildReviewsSection(),
            const SizedBox(height: 48),

            // Safety Section
            TextButton.icon(
              onPressed: () => _showReportDialog(context),
              icon: Icon(Icons.gpp_maybe_rounded, size: 16, color: Colors.grey.shade400),
              label: Text(
                'Report Suspicious Activity',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
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
            Text(
              'घरबेटीको समीक्षाहरू (Landlord Reviews)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black,
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined, color: Colors.grey[400], size: 36),
                const SizedBox(height: 12),
                Text(
                  'No reviews yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'यस घरबेटीको अहिलेसम्म कुनै समीक्षा छैन। (This landlord has no reviews yet.)',
                  style: GoogleFonts.mukta(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
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
