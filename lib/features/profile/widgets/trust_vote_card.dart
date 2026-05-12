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

  final String? _currentUserId = Supabase.instance.client.auth.currentUser?.id;

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
    if (_isLoading) {
      return const SizedBox(
        height: 40,
        width: 40,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brandColor),
      );
    }

    return GestureDetector(
      onTap: _handleVote,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _hasVoted ? AppTheme.brandColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.brandColor,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _hasVoted ? Icons.stars_rounded : Icons.stars_outlined,
                color: _hasVoted ? Colors.white : AppTheme.brandColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_voteCount Voted',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _hasVoted ? Colors.white : AppTheme.brandColor,
                    ),
                  ),
                  Text(
                    _hasVoted ? 'Trusted Owner' : 'Trust this Owner',
                    style: GoogleFonts.mukta(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: (_hasVoted ? Colors.white : AppTheme.brandColor).withOpacity(0.8),
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              if (_isVoting) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _hasVoted ? Colors.white : AppTheme.brandColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

}
