import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/core/models/user_model.dart';
import 'package:khozna/core/models/booking_model.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/features/property/screens/payment_choice_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingStatusScreen extends StatefulWidget {
  final BookingModel booking;
  const BookingStatusScreen({super.key, required this.booking});

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends State<BookingStatusScreen> {
  late BookingModel _booking;
  bool _isLoading = false;
  UserModel? _ownerProfile;
  Timer? _countdownTimer;
  Duration _timeUntilVisit = Duration.zero;

  // Post-visit states
  bool _showVisitedQuestion = false;
  bool _showLikedQuestion = false;
  bool _isActing = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _loadOwnerProfile();
    _startCountdown();
    _checkPostVisit();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    final now = DateTime.now();
    final visitTime = _booking.checkIn;
    if (visitTime.isAfter(now)) {
      _timeUntilVisit = visitTime.difference(now);
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final remaining = _booking.checkIn.difference(DateTime.now());
        if (mounted)
          setState(
            () => _timeUntilVisit = remaining.isNegative
                ? Duration.zero
                : remaining,
          );
      });
    }
  }

  void _checkPostVisit() {
    final isPastVisit = DateTime.now().isAfter(_booking.checkIn);
    final isAccepted =
        _booking.status == 'awaiting_payment' ||
        _booking.status == 'visit_accepted';
    // show "did you visit?" if past visit time, accepted, and not yet confirmed
    if (isPastVisit && isAccepted && (_booking.visitConfirmed == null)) {
      setState(() => _showVisitedQuestion = true);
    }
  }

  Future<void> _loadOwnerProfile() async {
    final profile = await SupabaseService.getUserProfile(_booking.ownerId);
    if (mounted) setState(() => _ownerProfile = profile);
  }

  Future<void> _refreshBooking() async {
    setState(() => _isLoading = true);
    try {
      final updated = await SupabaseService.getVisitById(_booking.id);
      if (updated != null && mounted) {
        setState(() => _booking = updated);
        _checkPostVisit();
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _remindOwner() async {
    setState(() => _isActing = true);
    try {
      await BookingRepository.remindOwner(_booking.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🔔 Reminder sent to owner!',
              style: GoogleFonts.mukta(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.brandColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _cancelRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel Visit?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to cancel this visit request?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isActing = true);
    try {
      await BookingRepository.rejectWithReason(
        _booking.id,
        reason: 'Cancelled by guest',
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _handleVisitedAnswer(bool visited) async {
    setState(() => _isActing = true);
    try {
      await BookingRepository.confirmVisitDone(_booking.id, visited: visited);
      await _refreshBooking();
      if (visited) {
        setState(() {
          _showVisitedQuestion = false;
          _showLikedQuestion = true;
        });
      } else {
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _handleLikedAnswer(bool liked) async {
    if (!liked) {
      final reasons = [
        'Too expensive',
        'Not as described',
        'Bad location',
        'Owner behavior',
      ];
      String? selected;
      await showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setS) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why didn\'t you like it? (Optional)',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                ...reasons.map(
                  (r) => RadioListTile<String>(
                    title: Text(r, style: GoogleFonts.inter()),
                    value: r,
                    groupValue: selected,
                    activeColor: AppTheme.brandColor,
                    onChanged: (v) => setS(() => selected = v),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Continue Browsing',
                      style: GoogleFonts.mukta(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      setState(() => _isActing = true);
      try {
        await BookingRepository.confirmVisitLiked(
          _booking.id,
          liked: false,
          feedbackReason: selected,
        );
      } catch (_) {
      } finally {
        if (mounted) {
          setState(() => _isActing = false);
          Navigator.pop(context);
        }
      }
      return;
    }
    // Liked — unlock payment
    setState(() => _isActing = true);
    try {
      await BookingRepository.confirmVisitLiked(_booking.id, liked: true);
      await _refreshBooking();
      setState(() {
        _showLikedQuestion = false;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
          'Visit Status',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.brandColor),
            onPressed: _refreshBooking,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.brandColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildStepProgress(),
                  const SizedBox(height: 24),
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildPropertyCard(),
                  const SizedBox(height: 16),
                  if (_booking.status == 'visit_accepted' ||
                      _booking.status == 'awaiting_payment')
                    _buildMapPreview(),
                  const SizedBox(height: 16),
                  if (_showVisitedQuestion) _buildVisitedQuestion(),
                  if (_showLikedQuestion && !_showVisitedQuestion)
                    _buildLikedQuestion(),
                  if (!_showVisitedQuestion && !_showLikedQuestion)
                    _buildActionArea(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildStepProgress() {
    int currentStep = 0;
    if (_booking.status == 'pending_approval') currentStep = 0;
    else if (_booking.status == 'visit_accepted') currentStep = 1;
    else if (_booking.status == 'awaiting_payment' || _booking.visitLiked == true) currentStep = 2;
    else if (_booking.status == 'confirmed') currentStep = 3;
    else if (_booking.status == 'paid') currentStep = 3;

    final steps = [
      {'label': 'Requested', 'icon': Icons.send_rounded},
      {'label': 'Approved', 'icon': Icons.check_circle_rounded},
      {'label': 'Liked', 'icon': Icons.favorite_rounded},
      {'label': 'Move-In', 'icon': Icons.home_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCompleted = index < currentStep;
          final isActive = index == currentStep;
          final isLast = index == steps.length - 1;
          final color = isCompleted || isActive ? AppTheme.brandColor : Colors.grey.shade300;

          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isCompleted ? AppTheme.brandColor : (isActive ? Colors.white : Colors.grey.shade50),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color,
                          width: 2,
                        ),
                        boxShadow: isActive ? [
                          BoxShadow(
                            color: AppTheme.brandColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ] : null,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : (steps[index]['icon'] as IconData),
                        size: 16,
                        color: isCompleted ? Colors.white : color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[index]['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: isCompleted ? AppTheme.brandColor : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatusCard() {
    final cfg = _getStatusConfig(_booking.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cfg.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cfg.color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(cfg.icon, color: cfg.color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cfg.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: cfg.color,
                      ),
                    ),
                    Text(
                      cfg.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: cfg.color.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Trust Hint: Only show for accepted visits that aren't yet liked
          if ((_booking.status == 'visit_accepted' ||
                  _booking.status == 'awaiting_payment') &&
              (_booking.visitLiked != true)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.security_rounded,
                    color: Colors.blue,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'सुरक्षित रहनुहोस्: कोठा हेरेर मन परेपछि मात्र भुक्तानी विवरण खुल्नेछ। (Payment unlocks after visit)',
                      style: GoogleFonts.mukta(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Rejection reason
          if (_booking.status == 'rejected' &&
              _booking.rejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Declined Reason: ${_booking.rejectionReason}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Countdown timer (when accepted and visit is in the future)
          if ((_booking.status == 'awaiting_payment' ||
                  _booking.status == 'visit_accepted') &&
              _timeUntilVisit > Duration.zero) ...[
            const SizedBox(height: 16),
            _buildCountdown(),
          ],

          // Visit date
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'Visit: ${DateFormat('EEE, MMM dd, yyyy').format(_booking.checkIn)}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    final h = _timeUntilVisit.inHours;
    final m = _timeUntilVisit.inMinutes % 60;
    final s = _timeUntilVisit.inSeconds % 60;
    final label = h > 24
        ? 'Visit ${DateFormat('EEE, hh:mm a').format(_booking.checkIn)}'
        : h > 0
        ? 'Visit in ${h}h ${m}m'
        : 'Visit in ${m}m ${s}s';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandColor.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: AppTheme.brandColor),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppTheme.brandColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.brandColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              color: AppTheme.brandColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _booking.propertyTitle ?? 'Property',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Owner: ${_ownerProfile?.fullName ?? "..."}',
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_ownerProfile != null)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => chat_page.ChatScreen(
                    ownerId: _booking.ownerId,
                    name: _ownerProfile?.fullName ?? 'Owner',
                    avatar: _ownerProfile?.avatarUrl ?? '',
                    online: true,
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.brandColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  'Chat',
                  style: GoogleFonts.mukta(
                    color: AppTheme.brandColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'कोठाको स्थान (Room Location)',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 150,
              width: double.infinity,
              color: Colors.blue.shade50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // This would be a real Google Map widget in production
                  Icon(Icons.map_outlined, color: Colors.blue.shade200, size: 50),
                  Positioned(
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        'Map Unlocked! 🔓',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Launch Google Maps
                final url =
                    'https://www.google.com/maps/search/?api=1&query=${_booking.checkIn.toIso8601String()}'; // Placeholder logic
                launchUrl(Uri.parse(url));
              },
              icon: const Icon(Icons.directions_rounded),
              label: Text(
                'बाटो हेर्नुहोस् (Get Directions)',
                style: GoogleFonts.mukta(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A3E1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea() {
    if (_isActing)
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.brandColor),
      );

    switch (_booking.status) {
      case 'pending_approval':
        return _buildPendingActions();
      case 'awaiting_payment':
      case 'visit_accepted':
        return _buildAcceptedActions();
      case 'rejected':
        return _buildRejectedActions();
      case 'visit_completed':
        return _buildCompletedNoLike();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPendingActions() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.hourglass_empty_rounded, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'मालिकको जवाफको प्रतीक्षा गर्दैछौं…\n(Waiting for owner response)',
                  style: GoogleFonts.mukta(fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _actionBtn(
          label: '🔔 Remind Owner',
          color: AppTheme.brandColor,
          onTap: _remindOwner,
        ),
        const SizedBox(height: 10),
        _actionBtn(
          label: 'Cancel Request',
          color: Colors.red,
          outlined: true,
          onTap: _cancelRequest,
        ),
      ],
    );
  }

  Widget _buildAcceptedActions() {
    final isPast = DateTime.now().isAfter(_booking.checkIn);
    return Column(
      children: [
        if (isPast) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '👀 कोठा हेर्न जानुभयो? (Did you visit the room?)',
              style: GoogleFonts.mukta(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  label: 'Yes',
                  color: AppTheme.brandColor,
                  onTap: () => _handleVisitedAnswer(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionBtn(
                  label: 'No',
                  color: Colors.grey,
                  outlined: true,
                  onTap: () => _handleVisitedAnswer(false),
                ),
              ),
            ],
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.brandColor.withOpacity(0.05),
                  Colors.blue.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.brandColor.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  'भ्रमण स्वीकृत भयो!',
                  style: GoogleFonts.mukta(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'कोठा हेर्न जानुहोस् र मन पराएपछि मात्र भुक्तानी गर्नुहोस्।',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRejectedActions() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'मालिकले भ्रमण स्वीकार गर्न सक्नुभएन।',
                style: GoogleFonts.mukta(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              if (_booking.rejectionReason != null) ...[
                const SizedBox(height: 6),
                Text(
                  'कारण: ${_booking.rejectionReason}',
                  style: GoogleFonts.inter(
                    color: Colors.red.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _actionBtn(
          label: 'Browse More Rooms',
          color: AppTheme.brandColor,
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildCompletedNoLike() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'भ्रमण पूरा भयो। धन्यवाद!',
            style: GoogleFonts.mukta(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          _actionBtn(
            label: 'Browse More Rooms',
            color: AppTheme.brandColor,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitedQuestion() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppTheme.brandColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.brandColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_walk_rounded,
              color: AppTheme.brandColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '🚶‍♂️ कोठा हेर्न जानुभयो?',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            'Did you visit the room?',
            style: GoogleFonts.inter(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _premiumChoiceBtn(
                  label: 'Yes, I visited',
                  icon: Icons.check_circle_rounded,
                  color: AppTheme.brandColor,
                  onTap: () => _handleVisitedAnswer(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _premiumChoiceBtn(
                  label: 'No',
                  icon: Icons.cancel_rounded,
                  color: Colors.grey.shade400,
                  isOutlined: true,
                  onTap: () => _handleVisitedAnswer(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLikedQuestion() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFF00C853).withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFF00C853),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'कोठा मन पर्यो?',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            'Did you like the room?',
            style: GoogleFonts.inter(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'कोठा मन परेमा, यहाँबाट भुक्तानीको प्रक्रिया अगाडि बढाउन सक्नुहुन्छ।',
              style: GoogleFonts.mukta(
                fontSize: 12,
                color: const Color(0xFF1B5E20),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _premiumChoiceBtn(
                  label: 'Yes! ❤️',
                  icon: Icons.thumb_up_rounded,
                  color: const Color(0xFF00C853),
                  onTap: () => _handleLikedAnswer(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _premiumChoiceBtn(
                  label: 'No',
                  icon: Icons.thumb_down_rounded,
                  color: Colors.grey.shade400,
                  isOutlined: true,
                  onTap: () => _handleLikedAnswer(false),
                ),
              ),
            ],
          ),
          if (_booking.status == 'awaiting_payment' && (_booking.visitLiked == true)) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            _actionBtn(
              label: '💳 PROCEED TO PAYMENT',
              color: const Color(0xFF00C853),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentChoiceScreen(
                    booking: _booking,
                    propertyTitle: _booking.propertyTitle ?? '',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _premiumChoiceBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.white : color,
          borderRadius: BorderRadius.circular(20),
          border: isOutlined ? Border.all(color: color.withOpacity(0.3), width: 2) : null,
          boxShadow: isOutlined ? null : [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: isOutlined ? color : Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isOutlined ? color : Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required Color color,
    bool outlined = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(30),
          border: outlined ? Border.all(color: color, width: 1.5) : null,
          boxShadow: outlined
              ? null
              : [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Text(
          label,
          style: GoogleFonts.mukta(
            color: outlined ? color : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'pending_approval':
        return _StatusConfig(
          Icons.hourglass_top_rounded,
          Colors.orange,
          'Pending Response',
          'मालिकले भ्रमण स्वीकृत गर्न बाँकी छ',
        );
      case 'visit_accepted':
        return _StatusConfig(
          Icons.check_circle_rounded,
          Colors.blue,
          'Visit Accepted',
          'भ्रमण स्वीकृत — कोठा हेर्न जानुहोस्',
        );
      case 'awaiting_payment':
      case 'visit_liked':
        return _StatusConfig(
          Icons.favorite_rounded,
          Colors.green,
          'Room Liked! 🎉',
          'कोठा मन पराउनुभयो — अब भुक्तानी गर्न सक्नुहुन्छ',
        );
      case 'rejected':
        return _StatusConfig(
          Icons.cancel_rounded,
          Colors.red,
          'Visit Declined ❌',
          'यो भ्रमण अहिले सम्भव भएन',
        );
      case 'paid':
        return _StatusConfig(
          Icons.payment_rounded,
          const Color(0xFF00C853),
          'Payment Submitted',
          'भुक्तानी पुष्टि हुँदैछ',
        );
      case 'confirmed':
        return _StatusConfig(
          Icons.home_rounded,
          AppTheme.brandColor,
          'Move-In Confirmed 🎉',
          'बधाई! कोठा तपाईंको भयो।',
        );
      case 'visit_completed':
        return _StatusConfig(
          Icons.done_all_rounded,
          Colors.grey,
          'Visit Completed',
          'भ्रमण सम्पन्न',
        );
      default:
        return _StatusConfig(Icons.info_rounded, Colors.grey, status, '');
    }
  }
}

class _StatusConfig {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _StatusConfig(this.icon, this.color, this.title, this.subtitle);
}
