import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/profile/repositories/vote_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrustVoteCard extends StatefulWidget {
  final String targetUserId;
  final String targetName;

  const TrustVoteCard({
    super.key,
    required this.targetUserId,
    required this.targetName,
  });

  @override
  State<TrustVoteCard> createState() => _TrustVoteCardState();
}

class _TrustVoteCardState extends State<TrustVoteCard>
    with SingleTickerProviderStateMixin {
  bool _hasVoted = false;
  int _voteCount = 0;
  bool _isLoading = true;
  bool _isVoting = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  final String? _currentUserId =
      Supabase.instance.client.auth.currentUser?.id;

  bool get _isOwnProfile => _currentUserId == widget.targetUserId;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _loadVoteData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadVoteData() async {
    final count = await VoteRepository.getVoteCount(widget.targetUserId);
    final voted = await VoteRepository.hasVoted(widget.targetUserId);
    if (mounted) {
      setState(() {
        _voteCount = count;
        _hasVoted = voted;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleVote() async {
    if (_isVoting || _isOwnProfile) return;
    setState(() => _isVoting = true);
    HapticFeedback.mediumImpact();

    final result = await VoteRepository.toggleVote(
      widget.targetUserId,
      _voteCount,
      _hasVoted,
    );

    if (mounted) {
      setState(() {
        _hasVoted = result.hasVoted;
        _voteCount = result.count;
        _isVoting = false;
      });
      if (result.hasVoted) {
        _animController.forward().then((_) => _animController.reverse());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _hasVoted
              ? [
                  AppTheme.brandColor.withOpacity(0.08),
                  AppTheme.brandColor.withOpacity(0.03),
                ]
              : [
                  Colors.grey.shade50,
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _hasVoted
              ? AppTheme.brandColor.withOpacity(0.3)
              : Colors.grey.shade200,
          width: _hasVoted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _hasVoted
                ? AppTheme.brandColor.withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isLoading
          ? const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.brandColor,
                ),
              ),
            )
          : Column(
              children: [
                Row(
                  children: [
                    // Vote count display
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.verified_user_rounded, // Changed to verified user for more "Owner" feel
                                color: AppTheme.brandColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isOwnProfile ? 'Your Trust Score' : 'Owner Trust Score',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'पाहुनाको भरोसा',
                                    style: GoogleFonts.mukta(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                      color: AppTheme.brandColor,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$_voteCount ',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 28,
                                    color: AppTheme.brandColor,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Votes / भरोसा',
                                  style: GoogleFonts.mukta(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppTheme.brandColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _isOwnProfile 
                              ? 'तपाईंलाई $_voteCount जनाले भरोसा गरेका छन्\n($_voteCount people trust on you)' 
                              : 'यो घरधनीलाई $_voteCount जनाले भरोसा गरेका छन्\n($_voteCount people trust this Owner)',
                            style: GoogleFonts.mukta(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Vote Button
                    if (!_isOwnProfile) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _handleVote,
                        child: AnimatedBuilder(
                          animation: _scaleAnim,
                          builder: (context, child) => Transform.scale(
                            scale: _scaleAnim.value,
                            child: child,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: _hasVoted
                                  ? AppTheme.brandColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.brandColor,
                                width: 1.5,
                              ),
                              boxShadow: _hasVoted
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.brandColor
                                            .withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [],
                            ),
                            child: _isVoting
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _hasVoted
                                          ? Colors.white
                                          : AppTheme.brandColor,
                                    ),
                                  )
                                : Column(
                                    children: [
                                      Icon(
                                        _hasVoted
                                            ? Icons.thumb_up_rounded
                                            : Icons.thumb_up_alt_outlined,
                                        color: _hasVoted
                                            ? Colors.white
                                            : AppTheme.brandColor,
                                        size: 22,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _hasVoted ? 'भरोसा गरियो / Voted' : 'भरोसा दिनुहोस् / Vote',
                                        style: GoogleFonts.mukta(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: _hasVoted
                                              ? Colors.white
                                              : AppTheme.brandColor,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Own profile — show Premium Seal
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFD700).withOpacity(0.25), // Gold
                              const Color(0xFFDAA520).withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.stars_rounded,
                              color: Color(0xFFDAA520),
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your Trust\nAchievement',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF8B4513),
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                // Trust level bar
                const SizedBox(height: 16),
                _buildTrustBar(),
              ],
            ),
    );
  }

  Widget _buildTrustBar() {
    final String trustLabel;
    final Color trustColor;
    final double trustProgress;

    if (_voteCount == 0) {
      trustLabel = 'नयाँ सदस्य · New Member';
      trustColor = Colors.grey;
      trustProgress = 0.05;
    } else if (_voteCount < 10) {
      trustLabel = 'उदाउँदो · Rising';
      trustColor = Colors.orange;
      trustProgress = _voteCount / 10;
    } else if (_voteCount < 30) {
      trustLabel = 'भरोसायोग्य · Trustworthy';
      trustColor = Colors.green;
      trustProgress = _voteCount / 30;
    } else if (_voteCount < 60) {
      trustLabel = 'पाहुना प्रिय · Guest Favourite';
      trustColor = AppTheme.brandColor;
      trustProgress = _voteCount / 60;
    } else if (_voteCount < 100) {
      trustLabel = '💎 प्रबुद्ध सदस्य · Elite Member';
      trustColor = const Color(0xFF00CED1); // Dark Cyan / Diamond
      trustProgress = _voteCount / 100;
    } else {
      trustLabel = '⭐ खोज्न लेजेन्ड · Khozna Legend';
      trustColor = const Color(0xFFFFD700); // Gold
      trustProgress = 1.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              trustLabel,
              style: GoogleFonts.mukta(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: trustColor,
              ),
            ),
            Text(
              '$_voteCount votes',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: trustProgress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(trustColor),
            ),
          ),
        ),
      ],
    );
  }
}
