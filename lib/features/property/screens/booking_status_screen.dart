import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/core/models/user_model.dart';
import 'package:khozna/core/models/booking_model.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/features/property/screens/payment_choice_screen.dart';
import 'package:khozna/features/property/screens/visit_request_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────
const _bg         = Color(0xFFF7F8FA);
const _card       = Colors.white;
const _ink        = Color(0xFF111827);
const _inkSub     = Color(0xFF6B7280);
const _border     = Color(0xFFE9EAED);
const _brand      = AppTheme.brandColor;

// ─────────────────────────────────────────────────────────────────────────────

class BookingStatusScreen extends StatefulWidget {
  final BookingModel booking;
  final Property? property; // pass property so "Try Again" can navigate back
  const BookingStatusScreen({super.key, required this.booking, this.property});

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends State<BookingStatusScreen>
    with SingleTickerProviderStateMixin {
  late BookingModel _booking;
  bool _isLoading = false;
  UserModel? _ownerProfile;
  Timer? _countdownTimer;
  Duration _timeUntilVisit = Duration.zero;

  bool _showVisitedQuestion = false;
  bool _showLikedQuestion   = false;
  bool _isActing            = false;

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _loadOwnerProfile();
    _startCountdown();
    _checkPostVisit();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  void _startCountdown() {
    final now  = DateTime.now();
    final visit = _booking.checkIn;
    if (visit.isAfter(now)) {
      _timeUntilVisit = visit.difference(now);
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        final rem = _booking.checkIn.difference(DateTime.now());
        if (!mounted) return t.cancel();
        if (rem.isNegative || rem == Duration.zero) {
          t.cancel();
          setState(() { _timeUntilVisit = Duration.zero; _checkPostVisit(); });
        } else {
          setState(() => _timeUntilVisit = rem);
        }
      });
    }
  }

  void _checkPostVisit() {
    final past     = DateTime.now().isAfter(_booking.checkIn);
    final accepted = _booking.status == 'visit_accepted';
    if (past && accepted && _booking.visitConfirmed == null) {
      setState(() => _showVisitedQuestion = true);
    }
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadOwnerProfile() async {
    final p = await SupabaseService.getUserProfile(_booking.ownerId);
    if (mounted) setState(() => _ownerProfile = p);
  }

  Future<void> _refreshBooking() async {
    setState(() => _isLoading = true);
    try {
      final up = await SupabaseService.getVisitById(_booking.id);
      if (up != null && mounted) {
        setState(() => _booking = up);
        _checkPostVisit();
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _remindOwner() async {
    setState(() => _isActing = true);
    try {
      await BookingRepository.remindOwner(_booking.id);
      if (mounted) _showSnack('Reminder sent to the host!', _brand);
    } catch (_) {} finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _cancelRequest() async {
    final ok = await _showConfirmDialog(
      title: 'Cancel Visit Request?',
      message: 'This action cannot be undone. Are you sure you want to cancel?',
      confirmLabel: 'Yes, Cancel',
      confirmColor: const Color(0xFFE11D48),
    );
    if (ok != true) return;
    setState(() => _isActing = true);
    try {
      await BookingRepository.cancelBookingRequestByGuest(_booking.id);
      if (mounted) Navigator.pop(context);
    } catch (_) {} finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _handleVisitedAnswer(bool visited) async {
    setState(() => _isActing = true);
    try {
      await BookingRepository.confirmVisitDone(_booking.id, visited: visited);
      await _refreshBooking();
      if (visited) {
        setState(() { _showVisitedQuestion = false; _showLikedQuestion = true; });
      } else {
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _handleLikedAnswer(bool liked) async {
    if (!liked) {
      const reasons = ['Too expensive', 'Not as described', 'Bad location', 'Host behavior'];
      String? selected;
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setS) => _FeedbackSheet(
            reasons: reasons,
            selected: selected,
            onChanged: (v) => setS(() => selected = v),
            onContinue: () => Navigator.pop(ctx),
          ),
        ),
      );
      setState(() => _isActing = true);
      try {
        await BookingRepository.confirmVisitLiked(_booking.id, liked: false, feedbackReason: selected);
        _showReviewSheet();
      } catch (_) {} finally {
        if (mounted) { setState(() => _isActing = false); Navigator.pop(context); }
      }
      return;
    }
    setState(() => _isActing = true);
    try {
      await BookingRepository.confirmVisitLiked(_booking.id, liked: true);
      await _refreshBooking();
      setState(() => _showLikedQuestion = false);
      _showReviewSheet();
    } catch (_) {} finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  void _showReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReviewSheet(
        bookingId: _booking.id,
        propertyId: _booking.propertyId,
        ownerId: _booking.ownerId,
        visitLiked: _booking.visitLiked,
        onDone: () {
          if (mounted && _booking.visitLiked != true) Navigator.pop(context);
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17)),
      content: Text(message, style: GoogleFonts.inter(fontSize: 14, color: _inkSub, height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Keep it', style: GoogleFonts.inter(color: _inkSub, fontWeight: FontWeight.w600)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel, style: GoogleFonts.inter(color: confirmColor, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brand, strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroStatus(),
                  const SizedBox(height: 16),
                  _buildJourneyTracker(),
                  const SizedBox(height: 16),
                  _buildPropertyCard(),
                  const SizedBox(height: 16),
                  _buildVisitDetails(),
                  if (_booking.status == 'visit_accepted' ||
                      _booking.status == 'awaiting_payment') ...[
                    const SizedBox(height: 16),
                    _buildMapPreview(),
                  ],
                  const SizedBox(height: 16),
                  if (_showVisitedQuestion)
                    _buildVisitedQuestion()
                  else if (_showLikedQuestion)
                    _buildLikedQuestion()
                  else
                    _buildActionArea(),
                ],
              ),
            ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _card,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Visit Status',
        style: GoogleFonts.plusJakartaSans(
          color: _ink, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: _brand, size: 22),
          onPressed: _refreshBooking,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  // ── HERO STATUS CARD ──────────────────────────────────────────────────────

  Widget _buildHeroStatus() {
    final cfg = _statusConfig(_booking.status);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: cfg.color.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // Icon badge
          ScaleTransition(
            scale: _booking.status == 'pending_approval' ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cfg.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(cfg.icon, color: cfg.color, size: 34),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            cfg.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20, fontWeight: FontWeight.w900,
              color: cfg.color, letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cfg.subtitle,
            style: GoogleFonts.inter(fontSize: 13.5, color: _inkSub, height: 1.5),
            textAlign: TextAlign.center,
          ),

          // Rejection reason box
          if (_booking.status == 'rejected' && _booking.rejectionReason != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Reason: ${_booking.rejectionReason}',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFB91C1C), fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Security note for accepted
          if (_booking.status == 'visit_accepted') ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: Color(0xFF1D4ED8), size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Payment only after physically visiting the property.',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1D4ED8), fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Countdown
          if ((_booking.status == 'visit_accepted' || _booking.status == 'awaiting_payment') &&
              _timeUntilVisit > Duration.zero) ...[
            const SizedBox(height: 16),
            _buildCountdown(),
          ],
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    final h = _timeUntilVisit.inHours;
    final m = _timeUntilVisit.inMinutes % 60;
    final s = _timeUntilVisit.inSeconds % 60;
    final label = h > 24
        ? 'Visit on ${DateFormat('EEE, MMM d • hh:mm a').format(_booking.checkIn)}'
        : h > 0 ? '$h h $m m remaining' : '$m m $s s remaining';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _brand.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: _brand, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w800, color: _brand,
            ),
          ),
        ],
      ),
    );
  }

  // ── JOURNEY TRACKER ───────────────────────────────────────────────────────

  Widget _buildJourneyTracker() {
    const steps = [
      _Step('Requested', Icons.send_rounded),
      _Step('Approved', Icons.check_circle_outlined),
      _Step('Move In', Icons.home_rounded),
    ];
    int current = 0;
    if (_booking.status == 'pending_approval') current = 0;
    else if (_booking.status == 'visit_accepted' || _booking.status == 'awaiting_payment') current = 1;
    else if (_booking.status == 'confirmed' || _booking.status == 'paid') current = 2;

    // For rejected/cancelled, don't show tracker
    if (_booking.status == 'rejected' || _booking.status == 'cancelled') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final idx = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: current > idx ? _brand : _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }
          final idx = i ~/ 2;
          final done   = current > idx;
          final active = current == idx;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? _brand : (active ? _card : const Color(0xFFF3F4F6)),
                  border: Border.all(
                    color: done || active ? _brand : _border,
                    width: 2,
                  ),
                  boxShadow: active ? [
                    BoxShadow(color: _brand.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3)),
                  ] : null,
                ),
                child: Icon(
                  done ? Icons.check_rounded : steps[idx].icon,
                  size: 16,
                  color: done ? Colors.white : (active ? _brand : _inkSub),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                steps[idx].label,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: active || done ? FontWeight.w700 : FontWeight.w500,
                  color: active || done ? _ink : _inkSub,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── PROPERTY CARD ─────────────────────────────────────────────────────────

  Widget _buildPropertyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: _brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.home_work_rounded, color: _brand, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _booking.propertyTitle ?? 'Property',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: _ink),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Host: ${_ownerProfile?.fullName ?? '...'}',
                  style: GoogleFonts.inter(fontSize: 12, color: _inkSub),
                ),
              ],
            ),
          ),
          if (_ownerProfile != null) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => chat_page.ChatScreen(
                    ownerId: _booking.ownerId,
                    name: _ownerProfile?.fullName ?? 'Host',
                    avatar: _ownerProfile?.avatarUrl ?? '',
                    online: true,
                  ),
                ));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _brand.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Chat',
                  style: GoogleFonts.plusJakartaSans(
                    color: _brand, fontWeight: FontWeight.w700, fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── VISIT DETAILS ─────────────────────────────────────────────────────────

  Widget _buildVisitDetails() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _detailRow(
            Icons.calendar_today_rounded,
            'Visit Date',
            DateFormat('EEE, d MMM yyyy').format(_booking.checkIn),
          ),
          _divider(),
          _detailRow(
            Icons.access_time_rounded,
            'Visit Time',
            DateFormat('hh:mm a').format(_booking.checkIn),
          ),
          _divider(),
          _detailRow(
            Icons.confirmation_number_rounded,
            'Booking ID',
            '#${_booking.id.substring(0, 8).toUpperCase()}',
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Row(
        children: [
          Icon(icon, size: 17, color: _inkSub),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(fontSize: 13.5, color: _inkSub)),
          const Spacer(),
          Text(value, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: _ink)),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(horizontal: 18));

  // ── MAP PREVIEW ───────────────────────────────────────────────────────────

  Widget _buildMapPreview() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 18),
              const SizedBox(width: 8),
              Text(
                'Property Location',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _ink),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Unlocked',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 130,
              width: double.infinity,
              color: const Color(0xFFEFF6FF),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.map_outlined, color: const Color(0xFFBFDBFE), size: 60),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
                      ),
                      child: Text(
                        'Tap for directions →',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _brand),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse(
                'https://www.google.com/maps/search/?api=1&query=${_booking.checkIn.toIso8601String()}',
              )),
              icon: const Icon(Icons.directions_rounded, size: 18),
              label: Text('Get Directions', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ACTION AREAS ──────────────────────────────────────────────────────────

  Widget _buildActionArea() {
    if (_isActing) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: _brand, strokeWidth: 2)),
      );
    }
    switch (_booking.status) {
      case 'pending_approval':  return _buildPendingActions();
      case 'visit_accepted':
      case 'awaiting_payment':  return _buildAwaitingPaymentActions();
      case 'rejected':          return _buildRejectedActions();
      case 'visit_completed':
      case 'confirmed':
      case 'paid':
        return Column(children: [
          _primaryBtn(
            label: 'Leave a Review',
            icon: Icons.star_rounded,
            onTap: _showReviewSheet,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 12),
          _outlineBtn(label: 'Browse More Properties', onTap: () => Navigator.pop(context)),
        ]);
      default:
        if (_booking.visitConfirmed == true) {
          return _primaryBtn(
            label: 'Leave a Review',
            icon: Icons.star_rounded,
            onTap: _showReviewSheet,
            color: const Color(0xFFF59E0B),
          );
        }
        return const SizedBox.shrink();
    }
  }

  // ── Pending ────────────────────────────────────────────────────────────────

  Widget _buildPendingActions() {
    return Column(
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waiting for host approval',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _ink),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Most hosts respond within 24 hours.',
                      style: GoogleFonts.inter(fontSize: 12, color: _inkSub),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _primaryBtn(
          label: 'Remind Host',
          icon: Icons.notifications_rounded,
          onTap: _remindOwner,
          color: _brand,
        ),
        const SizedBox(height: 10),
        _outlineBtn(
          label: 'Cancel Request',
          onTap: _cancelRequest,
          color: const Color(0xFFE11D48),
        ),
      ],
    );
  }

  // ── Awaiting Payment ───────────────────────────────────────────────────────

  Widget _buildAwaitingPaymentActions() {
    final hasProof = _booking.paymentProofUrl?.isNotEmpty == true;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: hasProof ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasProof ? Icons.verified_rounded : Icons.account_balance_wallet_rounded,
                  color: hasProof ? const Color(0xFF16A34A) : _brand,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                hasProof ? 'Payment Submitted!' : 'Ready to Pay?',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: _ink, letterSpacing: -0.3),
              ),
              const SizedBox(height: 6),
              Text(
                hasProof
                    ? 'Your receipt has been received. Our team will verify and confirm your booking shortly.'
                    : 'You liked the room — send your payment receipt via eSewa or Khalti to complete booking.',
                style: GoogleFonts.inter(fontSize: 13, color: _inkSub, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (!hasProof || _booking.status == 'awaiting_payment') ...[
          _primaryBtn(
            label: 'Upload Payment Receipt',
            icon: Icons.upload_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PaymentChoiceScreen(booking: _booking)),
            ).then((_) => _refreshBooking()),
            color: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 10),
        ],
        _outlineBtn(label: 'Browse More Properties', onTap: () => Navigator.pop(context)),
      ],
    );
  }

  // ── Rejected ───────────────────────────────────────────────────────────────

  Widget _buildRejectedActions() {
    return Column(
      children: [
        // Empathetic info card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sentiment_dissatisfied_rounded, color: Color(0xFFDC2626), size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                'Visit Not Available',
                style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w900, color: _ink, letterSpacing: -0.3),
              ),
              const SizedBox(height: 6),
              Text(
                'The host was unable to accommodate your visit at this time. Don\'t worry — there are plenty of great properties available.',
                style: GoogleFonts.inter(fontSize: 13, color: _inkSub, height: 1.55),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Try Again — only if we have a property reference
        if (widget.property != null)
          _primaryBtn(
            label: 'Try Again',
            icon: Icons.restart_alt_rounded,
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => VisitRequestScreen(property: widget.property!),
                ),
              );
            },
            color: _brand,
          ),
        if (widget.property != null) const SizedBox(height: 10),

        _outlineBtn(
          label: 'Browse Other Properties',
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }

  // ── Post-Visit: Visited? ───────────────────────────────────────────────────

  Widget _buildVisitedQuestion() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _brand.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_walk_rounded, color: _brand, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            'Did you visit the property?',
            style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w900, color: _ink, letterSpacing: -0.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Let us know how your visit went.',
            style: GoogleFonts.inter(fontSize: 13, color: _inkSub),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _choiceBtn(label: 'Yes, I visited', icon: Icons.check_circle_rounded, color: _brand, onTap: () => _handleVisitedAnswer(true))),
              const SizedBox(width: 12),
              Expanded(child: _choiceBtn(label: 'Not yet', icon: Icons.cancel_rounded, color: const Color(0xFF9CA3AF), isOutlined: true, onTap: () => _handleVisitedAnswer(false))),
            ],
          ),
        ],
      ),
    );
  }

  // ── Post-Visit: Liked? ────────────────────────────────────────────────────

  Widget _buildLikedQuestion() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded, color: Color(0xFF16A34A), size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            'Did you like the property?',
            style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w900, color: _ink, letterSpacing: -0.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'If you liked it, you can proceed with payment to book it.',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF166534), fontWeight: FontWeight.w600, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _choiceBtn(label: 'Yes, I love it ❤️', icon: Icons.thumb_up_rounded, color: const Color(0xFF16A34A), onTap: () => _handleLikedAnswer(true))),
              const SizedBox(width: 12),
              Expanded(child: _choiceBtn(label: 'Not interested', icon: Icons.thumb_down_rounded, color: const Color(0xFF9CA3AF), isOutlined: true, onTap: () => _handleLikedAnswer(false))),
            ],
          ),
          if (_booking.status == 'awaiting_payment' && _booking.visitLiked == true) ...[
            const SizedBox(height: 20),
            _primaryBtn(
              label: 'Proceed to Payment',
              icon: Icons.credit_card_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PaymentChoiceScreen(booking: _booking, propertyTitle: _booking.propertyTitle ?? '')),
              ),
              color: const Color(0xFF16A34A),
            ),
          ],
        ],
      ),
    );
  }

  // ── Shared Button Widgets ─────────────────────────────────────────────────

  Widget _primaryBtn({
    required String label,
    required VoidCallback onTap,
    required Color color,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: () { HapticFeedback.mediumImpact(); onTap(); },
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _outlineBtn({
    required String label,
    required VoidCallback onTap,
    Color color = _inkSub,
  }) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border, width: 1.5),
        ),
        child: Text(label, style: GoogleFonts.inter(color: _inkSub, fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }

  Widget _choiceBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return GestureDetector(
      onTap: () { HapticFeedback.mediumImpact(); onTap(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.white : color,
          borderRadius: BorderRadius.circular(18),
          border: isOutlined ? Border.all(color: _border, width: 1.5) : null,
          boxShadow: isOutlined ? null : [
            BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: isOutlined ? _inkSub : Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.plusJakartaSans(color: isOutlined ? _inkSub : Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Status Config ─────────────────────────────────────────────────────────

  _StatusConfig _statusConfig(String status) {
    switch (status) {
      case 'pending_approval':
        return const _StatusConfig(
          icon: Icons.hourglass_top_rounded,
          color: Color(0xFFF59E0B),
          title: 'Awaiting Approval',
          subtitle: 'Your visit request has been sent. Waiting for the host to respond.',
        );
      case 'visit_accepted':
        return const _StatusConfig(
          icon: Icons.check_circle_rounded,
          color: Color(0xFF0EA5E9),
          title: 'Visit Approved!',
          subtitle: 'Your visit has been approved. Head over to check out the property.',
        );
      case 'awaiting_payment':
      case 'visit_liked':
        return const _StatusConfig(
          icon: Icons.favorite_rounded,
          color: Color(0xFF16A34A),
          title: 'Room Liked 🎉',
          subtitle: 'You liked the property. Proceed with payment to complete your booking.',
        );
      case 'rejected':
        return const _StatusConfig(
          icon: Icons.cancel_rounded,
          color: Color(0xFFDC2626),
          title: 'Visit Declined',
          subtitle: 'The host couldn\'t accommodate your visit right now.',
        );
      case 'cancelled':
        return const _StatusConfig(
          icon: Icons.cancel_outlined,
          color: Color(0xFF9CA3AF),
          title: 'Request Cancelled',
          subtitle: 'Your visit request was cancelled.',
        );
      case 'paid':
        return const _StatusConfig(
          icon: Icons.payment_rounded,
          color: Color(0xFF16A34A),
          title: 'Payment Submitted',
          subtitle: 'Your payment is under review. You\'ll be notified once confirmed.',
        );
      case 'confirmed':
        return const _StatusConfig(
          icon: Icons.home_rounded,
          color: _brand,
          title: 'Move-In Confirmed 🎉',
          subtitle: 'Congratulations! The room is officially yours.',
        );
      case 'visit_completed':
        return const _StatusConfig(
          icon: Icons.done_all_rounded,
          color: Color(0xFF6B7280),
          title: 'Visit Completed',
          subtitle: 'Your visit has been marked as completed.',
        );
      default:
        return _StatusConfig(icon: Icons.info_rounded, color: _inkSub, title: status, subtitle: '');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper models
// ─────────────────────────────────────────────────────────────────────────────

class _Step {
  final String label;
  final IconData icon;
  const _Step(this.label, this.icon);
}

class _StatusConfig {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _StatusConfig({required this.icon, required this.color, required this.title, required this.subtitle});
}

// ─────────────────────────────────────────────────────────────────────────────
// Feedback Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _FeedbackSheet extends StatelessWidget {
  final List<String> reasons;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final VoidCallback onContinue;
  const _FeedbackSheet({required this.reasons, this.selected, required this.onChanged, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 28, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 20),
          Text(
            'What didn\'t you like?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 19, letterSpacing: -0.4),
          ),
          const SizedBox(height: 4),
          Text('Optional — helps us improve.', style: GoogleFonts.inter(fontSize: 13, color: _inkSub)),
          const SizedBox(height: 18),
          ...reasons.map((r) => RadioListTile<String>(
            title: Text(r, style: GoogleFonts.inter(fontSize: 14)),
            value: r,
            groupValue: selected,
            activeColor: _brand,
            onChanged: onChanged,
            contentPadding: EdgeInsets.zero,
          )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text('Continue', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Review Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewSheet extends StatefulWidget {
  final String bookingId;
  final String propertyId;
  final String ownerId;
  final bool? visitLiked;
  final VoidCallback onDone;
  const _ReviewSheet({
    required this.bookingId,
    required this.propertyId,
    required this.ownerId,
    this.visitLiked,
    required this.onDone,
  });

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 5;
  final _commentCtrl = TextEditingController();
  final Set<String> _tags = {};
  bool _submitting = false;

  static const _negTags = ['Too expensive', 'Not as described', 'Bad location', 'Rude host', 'Mismatch photos'];
  static const _posTags = ['Clean property', 'Polite host', 'Good water supply', 'Quiet area', 'Accurate photos'];

  String get _emoji => ['😞', '😕', '🙂', '😊', '😍'][_rating - 1];
  String get _ratingText => ['Disappointed', 'Fair', 'Good', 'Very Good', 'Excellent!'][_rating - 1];
  List<String> get _activeTags => _rating <= 2 ? _negTags : _posTags;
  Color get _ratingColor => _rating <= 2 ? const Color(0xFFDC2626) : _brand;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 28, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 24),
            Text('Rate Your Visit',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('Help others make better decisions.',
              style: GoogleFonts.inter(color: _inkSub, fontSize: 13)),
            const SizedBox(height: 24),

            // Emoji + label
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Column(
                key: ValueKey(_rating),
                children: [
                  Text(_emoji, style: const TextStyle(fontSize: 44)),
                  const SizedBox(height: 6),
                  Text(_ratingText,
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: _ratingColor)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() { _rating = star; _tags.clear(); });
                  },
                  child: AnimatedScale(
                    scale: star <= _rating ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(Icons.star_rounded,
                      color: star <= _rating ? Colors.amber : const Color(0xFFE5E7EB),
                      size: 44),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Tags
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Quick Tags', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: _inkSub)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _activeTags.map((tag) {
                final sel = _tags.contains(tag);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => sel ? _tags.remove(tag) : _tags.add(tag));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _ratingColor : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(30),
                      border: sel ? null : Border.all(color: _border),
                    ),
                    child: Text(tag,
                      style: GoogleFonts.inter(
                        fontSize: 12.5, fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : _inkSub,
                      )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Comment
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add a comment... (optional)',
                hintStyle: GoogleFonts.inter(color: const Color(0xFFD1D5DB), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _brand, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ratingColor,
                  disabledBackgroundColor: _ratingColor.withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Submit Review', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      String comment = _commentCtrl.text.trim();
      if (_tags.isNotEmpty) {
        final tagStr = _tags.map((t) => '[$t]').join(' ');
        comment = comment.isNotEmpty ? '$tagStr\n$comment' : tagStr;
      }
      await BookingRepository.submitReview(
        bookingId: widget.bookingId,
        propertyId: widget.propertyId,
        ownerId: widget.ownerId,
        rating: _rating,
        comment: comment.isNotEmpty ? comment : null,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onDone();
      }
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
