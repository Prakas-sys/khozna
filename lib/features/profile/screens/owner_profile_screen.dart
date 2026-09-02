import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:intl/intl.dart';
import 'package:khozna/core/models/review_model.dart';
import 'package:khozna/features/profile/repositories/vote_repository.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/features/profile/screens/owner_listings_screen.dart';

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
  String? _gender;
  String? _education;
  String? _languages;
  String? _interests;
  String? _fetchedAvatar;
  bool _isProfileVerified = false;
  List<String> _socialLinks = [];

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
              'created_at, area_name, bio, phone_number, email, user_type, organization, gender, education, school, languages, interests, avatar_url, kyc_status, is_verified, facebook_url, instagram_url, linkedin_url, website, social_links',
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
            _gender = profileData['gender'] as String?;
            _education = (profileData['education'] ?? profileData['school']) as String?;
            _languages = profileData['languages'] as String?;
            _interests = profileData['interests'] as String?;
            if (profileData['avatar_url'] != null &&
                profileData['avatar_url'].toString().isNotEmpty) {
              _fetchedAvatar = profileData['avatar_url'].toString();
            }

            // Parse social media links
            final List<String> links = [];
            if (profileData['facebook_url'] != null &&
                profileData['facebook_url'].toString().isNotEmpty) {
              links.add(profileData['facebook_url'].toString());
            }
            if (profileData['instagram_url'] != null &&
                profileData['instagram_url'].toString().isNotEmpty) {
              links.add(profileData['instagram_url'].toString());
            }
            if (profileData['linkedin_url'] != null &&
                profileData['linkedin_url'].toString().isNotEmpty) {
              links.add(profileData['linkedin_url'].toString());
            }
            if (profileData['website'] != null &&
                profileData['website'].toString().isNotEmpty) {
              links.add(profileData['website'].toString());
            }
            if (profileData['social_links'] != null) {
              final raw = profileData['social_links'];
              if (raw is List) {
                for (var item in raw) {
                  if (item != null && item.toString().isNotEmpty) {
                    links.add(item.toString());
                  }
                }
              }
            }
            _socialLinks = links;

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
            actions: [
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
                  margin: const EdgeInsets.only(top: 10, bottom: 10, right: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.paperPlane,
                    size: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showReportDialog(context),
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    children: [
                      // Avatar
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AppTheme.buildAvatarWidget(
                            avatarUrl: avatarUrl,
                            radius: 50,
                            name: widget.name,
                          ),
                          if (_isProfileVerified)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2.5),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_rounded,
                                  color: AppTheme.brandColor,
                                  size: 22,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Name
                      Text(
                        widget.name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── 3-Stat Row (borderless, clean) ──────────────
                      Row(
                        children: [
                          // Reviews
                          Expanded(
                            child: _buildCleanStat(
                              value: '${_ownerReviews.length}',
                              label: 'Reviews',
                            ),
                          ),
                          Container(height: 32, width: 1, color: const Color(0xFFE2E8F0)),
                          // Rating
                          Expanded(
                            child: _buildCleanStat(
                              value: avgRating != null
                                  ? avgRating.toStringAsFixed(1)
                                  : '–',
                              label: 'Rating',
                              trailing: avgRating != null
                                  ? const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 16)
                                  : null,
                            ),
                          ),
                          Container(height: 32, width: 1, color: const Color(0xFFE2E8F0)),
                          // Years
                          Expanded(
                            child: _buildCleanStat(
                              value: '$_yearsHosting',
                              label: _yearsHosting == 1 ? 'Year hosting' : 'Years hosting',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
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
                        'Confirmed info',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Identity Row
                      _buildConfirmedRow(
                        icon: _isProfileVerified
                            ? Icons.verified_user_rounded
                            : Icons.shield_outlined,
                        iconColor: _isProfileVerified
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF64748B),
                        label: 'Identity',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _isProfileVerified
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isProfileVerified) ...[
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: Color(0xFF166534),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                _isProfileVerified ? 'Verified' : 'Unverified',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _isProfileVerified
                                      ? const Color(0xFF166534)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Location Row
                      if (_realLocation.isNotEmpty)
                        _buildConfirmedRow(
                          icon: Icons.location_on_outlined,
                          iconColor: const Color(0xFF64748B),
                          label: 'Location',
                          value: _realLocation,
                        ),

                      // Joined Row
                      _buildConfirmedRow(
                        icon: Icons.calendar_today_outlined,
                        iconColor: const Color(0xFF64748B),
                        label: 'Joined',
                        value: _joinedDate,
                      ),

                      // Clickable Listings Row
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OwnerListingsScreen(
                                ownerId: widget.ownerId,
                                ownerName: widget.name,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.home_work_rounded,
                                color: Color(0xFF64748B),
                                size: 22,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  '${widget.totalListings > 0 ? widget.totalListings : 1} ${widget.totalListings == 1 ? 'listing' : 'listings'} on Khozna',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // ── About Section ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Metadata Chips (Work, Gender, Education, Role, Interests, Languages)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_organization != null && _organization!.isNotEmpty)
                            _buildInfoChip(Icons.work_outline_rounded, 'Work: $_organization'),
                          if (_gender != null && _gender!.isNotEmpty)
                            _buildInfoChip(Icons.person_outline_rounded, 'Gender: $_gender'),
                          if (_education != null && _education!.isNotEmpty)
                            _buildInfoChip(Icons.school_outlined, 'Education: $_education'),
                          if (_userType != null && _userType!.isNotEmpty)
                            _buildInfoChip(Icons.badge_outlined, _userType!),
                          if (_languages != null && _languages!.isNotEmpty)
                            _buildInfoChip(Icons.translate_rounded, 'Speaks: $_languages'),
                          if (_interests != null && _interests!.isNotEmpty)
                            _buildInfoChip(Icons.interests_outlined, _interests!),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Bio
                      if (_bio != null && _bio!.trim().isNotEmpty) ...[
                        Text(
                          _bio!,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            color: const Color(0xFF475569),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Social Media Links
                      _buildSocialMediaSection(),

                      const SizedBox(height: 24),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ],
                  ),
                ),

                // ── Warning Banner (unverified) ──────────────────────────
                if (!_isProfileVerified)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEFCE8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFCA8A04),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This owner\'s identity hasn\'t been verified yet.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF854D0E),
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
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
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
                      icon: const FaIcon(
                        FontAwesomeIcons.paperPlane,
                        size: 15,
                        color: Color(0xFF0F172A),
                      ),
                      label: Text(
                        'Message ${widget.name.split(' ').first}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF0F172A),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
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

  Widget _buildCleanStat({
    required String value,
    required String label,
    Widget? trailing,
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
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
                height: 1,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 3), trailing],
          ],
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmedRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    String? value,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          if (trailing != null) trailing,
          if (value != null && trailing == null)
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaSection() {
    final List<String> linksToDisplay = _socialLinks.isNotEmpty
        ? _socialLinks
        : [
            'https://facebook.com',
            'https://instagram.com',
            'https://tiktok.com',
            'https://linkedin.com',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connected Social Accounts',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: linksToDisplay
              .map((url) => _buildSocialIconBadge(url))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSocialIconBadge(String rawUrl) {
    final String urlLower = rawUrl.toLowerCase();
    IconData iconData = FontAwesomeIcons.globe;
    Color brandColor = const Color(0xFF475569);
    String label = 'Website';

    if (urlLower.contains('facebook')) {
      iconData = FontAwesomeIcons.facebook;
      brandColor = const Color(0xFF1877F2);
      label = 'Facebook';
    } else if (urlLower.contains('instagram')) {
      iconData = FontAwesomeIcons.instagram;
      brandColor = const Color(0xFFE4405F);
      label = 'Instagram';
    } else if (urlLower.contains('linkedin')) {
      iconData = FontAwesomeIcons.linkedin;
      brandColor = const Color(0xFF0A66C2);
      label = 'LinkedIn';
    } else if (urlLower.contains('tiktok')) {
      iconData = FontAwesomeIcons.tiktok;
      brandColor = const Color(0xFF000000);
      label = 'TikTok';
    } else if (urlLower.contains('twitter') || urlLower.contains('x.com')) {
      iconData = FontAwesomeIcons.xTwitter;
      brandColor = const Color(0xFF000000);
      label = 'X / Twitter';
    } else if (urlLower.contains('whatsapp') || urlLower.contains('wa.me')) {
      iconData = FontAwesomeIcons.whatsapp;
      brandColor = const Color(0xFF25D366);
      label = 'WhatsApp';
    }

    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        final Uri? uri = Uri.tryParse(rawUrl);
        if (uri != null) {
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            debugPrint('Error launching URL: $e');
          }
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(iconData, size: 17, color: brandColor),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(double? avgRating) {
    if (_isLoadingReviews) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            color: AppTheme.brandColor,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Reviews',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            if (_ownerReviews.isNotEmpty && avgRating != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
              const SizedBox(width: 3),
              Text(
                avgRating.toStringAsFixed(1),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '·',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFFCBD5E1),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${_ownerReviews.length}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        'No reviews from guests yet.',
        style: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFFCBD5E1),
          fontWeight: FontWeight.w500,
        ),
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
