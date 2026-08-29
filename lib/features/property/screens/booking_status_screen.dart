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
// Executive Senior Design Tokens
// ─────────────────────────────────────────────────────────────────────────────
const _bg = Color(0xFFF8FAFC);
const _card = Colors.white;
const _ink = Color(0xFF0F172A);
const _inkSub = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _brand = AppTheme.brandColor;

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
  bool _showLikedQuestion = false;
  bool _isActing = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

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
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
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
    final now = DateTime.now();
    final visit = _booking.checkIn;
    if (visit.isAfter(now)) {
      _timeUntilVisit = visit.difference(now);
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        final rem = _booking.checkIn.difference(DateTime.now());
        if (!mounted) return t.cancel();
        if (rem.isNegative || rem == Duration.zero) {
          t.cancel();
          setState(() {
            _timeUntilVisit = Duration.zero;
            _checkPostVisit();
          });
        } else {
          setState(() => _timeUntilVisit = rem);
        }
      });
    }
  }

  void _checkPostVisit() {
    final past = DateTime.now().isAfter(_booking.checkIn);
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
      if (mounted) _showSnack('Reminder sent to the owner!', _brand);
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
        setState(() {
          _showVisitedQuestion = false;
          _showLikedQuestion = true;
        });
      } else {
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _handleLikedAnswer(bool liked) async {
    if (!liked) {
      const reasons = [
        'Too expensive',
        'Not as described',
        'Bad location',
        'Host behavior',
      ];
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
        await BookingRepository.confirmVisitLiked(_booking.id,
            liked: false, feedbackReason: selected);
        _showReviewSheet();
      } catch (_) {} finally {
        if (mounted) {
          setState(() => _isActing = false);
          Navigator.pop(context);
        }
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
        content: Text(msg,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, fontSize: 13)),
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
  }) =>
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title,
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800, fontSize: 17)),
          content: Text(message,
              style: GoogleFonts.inter(
                  fontSize: 14, color: _inkSub, height: 1.5)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Keep it',
                  style: GoogleFonts.inter(
                      color: _inkSub, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmLabel,
                  style: GoogleFonts.inter(
                      color: confirmColor, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isPostPayment = _booking.status == 'paid' ||
        _booking.status == 'confirmed' ||
        _booking.status == 'visit_completed';
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _brand, strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroStatus(),
                  const SizedBox(height: 14),
                  if (!isPostPayment) _buildJourneyTracker(),
                  if (!isPostPayment) const SizedBox(height: 14),
                  _buildUnifiedReservationCard(),
                  const SizedBox(height: 18),
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
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _ink, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Visit Status',
        style: GoogleFonts.plusJakartaSans(
          color: _ink,
          fontWeight: FontWeight.w800,
          fontSize: 17,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: _brand, size: 22),
          onPressed: _refreshBooking,
          tooltip: 'Refresh Status',
        ),
      ],
    );
  }

  // ── HERO STATUS CARD (Clean Senior Designer Palette) ─────────────────────

  Widget _buildHeroStatus() {
    final cfg = _statusConfig(_booking.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cfg.bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cfg.borderColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: cfg.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cfg.badgeLabel.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: cfg.color,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cfg.bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: cfg.borderColor, width: 1.5),
            ),
            child: Icon(cfg.icon, color: cfg.color, size: 24),
          ),
          const SizedBox(height: 12),

          Text(
            cfg.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          Text(
            cfg.subtitle,
            style: GoogleFonts.inter(
                fontSize: 13, color: _inkSub, height: 1.45),
            textAlign: TextAlign.center,
          ),

          // Rejection reason box
          if ((_booking.status == 'rejected' ||
                  _booking.status == 'payment_rejected') &&
              _booking.rejectionReason != null &&
              _booking.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFFE11D48), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rejection Reason: ${_booking.rejectionReason}',
                      style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFFBE123C),
                          fontWeight: FontWeight.w600,
                          height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if ((_booking.status == 'visit_accepted' ||
                  _booking.status == 'awaiting_payment') &&
              _timeUntilVisit > Duration.zero) ...[
            const SizedBox(height: 14),
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
        : h > 0
            ? '$h h $m m remaining'
            : '$m m $s s remaining';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: _brand.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _brand.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, color: _brand, size: 15),
          const SizedBox(width: 7),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: _brand,
            ),
          ),
        ],
      ),
    );
  }

  // ── JOURNEY TRACKER ───────────────────────────────────────────────────

  Widget _buildJourneyTracker() {
    const steps = [
      _Step('Requested', Icons.send_rounded),
      _Step('Visit', Icons.door_front_door_outlined),
      _Step('Payment', Icons.receipt_rounded),
    ];

    int current;
    switch (_booking.status) {
      case 'pending_approval':
        current = 0;
        break;
      case 'visit_accepted':
        current = 1;
        break;
      case 'awaiting_payment':
        current = 1;
        break;
      default:
        current = 0;
    }

    if (_booking.status == 'rejected' ||
        _booking.status == 'cancelled' ||
        _booking.status == 'paid' ||
        _booking.status == 'confirmed' ||
        _booking.status == 'visit_completed') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final idx = i ~/ 2;
            final isCompletedLine = current > idx;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isCompletedLine ? _brand : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }
          final idx = i ~/ 2;
          final done = current > idx;
          final active = current == idx;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? _brand
                      : (active ? _card : const Color(0xFFF1F5F9)),
                  border: Border.all(
                    color: done || active ? _brand : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                ),
                child: Icon(
                  done ? Icons.check_rounded : steps[idx].icon,
                  size: 15,
                  color: done ? Colors.white : (active ? _brand : _inkSub),
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  steps[idx].label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: active || done ? FontWeight.w700 : FontWeight.w500,
                    color: active || done ? _ink : _inkSub,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── UNIFIED RESERVATION TICKET CARD ──────────────────────────────────────

  Widget _buildUnifiedReservationCard() {
    final bookingIdShort = _booking.id.length >= 8
        ? _booking.id.substring(0, 8).toUpperCase()
        : _booking.id.toUpperCase();
    final isLocationUnlocked = _booking.status == 'visit_accepted' ||
        _booking.status == 'awaiting_payment' ||
        _booking.status == 'paid' ||
        _booking.status == 'confirmed';

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section 1: Property & Owner Chat
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _brand.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.home_work_rounded, color: _brand, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _booking.propertyTitle ?? 'Property Listing',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Owner: ${_ownerProfile?.fullName ?? 'Owner'}',
                              style: GoogleFonts.inter(fontSize: 12, color: _inkSub),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded,
                              color: Color(0xFF0EA5E9), size: 13),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_ownerProfile != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => chat_page.ChatScreen(
                            ownerId: _booking.ownerId,
                            name: _ownerProfile?.fullName ?? 'Owner',
                            avatar: _ownerProfile?.avatarUrl ?? '',
                            online: true,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _brand,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_rounded, color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            'Chat',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          _divider(),

          // Section 2: Visit Date, Time & Ref Code
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _detailItemRow(
                  Icons.calendar_today_rounded,
                  'Schedule',
                  '${DateFormat('EEE, d MMM yyyy').format(_booking.checkIn)} at ${DateFormat('h:mm a').format(_booking.checkIn)}',
                ),
                const SizedBox(height: 10),
                _detailItemRow(
                  Icons.tag_rounded,
                  'Reference',
                  '#$bookingIdShort',
                  canCopy: true,
                  copyValue: '#$bookingIdShort',
                ),
              ],
            ),
          ),

          // Section 3: Property Directions (if unlocked)
          if (isLocationUnlocked) ...[
            _divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: Color(0xFFEF4444), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Property Location',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        Text(
                          'Unlocked for your visit',
                          style: GoogleFonts.inter(fontSize: 11, color: _inkSub),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=${_booking.checkIn.toIso8601String()}',
                    )),
                    icon: const Icon(Icons.directions_rounded, size: 14),
                    label: Text('Maps',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailItemRow(IconData icon, String label, String value,
      {bool canCopy = false, String? copyValue}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _inkSub),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 12.5, color: _inkSub)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
        if (canCopy && copyValue != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: copyValue));
              _showSnack('Copied to clipboard', _brand);
            },
            child: const Icon(Icons.copy_rounded,
                size: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ],
    );
  }

  Widget _divider() => Container(height: 1, color: _border);

  // ── ACTION AREAS ──────────────────────────────────────────────────────────

  Widget _buildActionArea() {
    if (_isActing) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
            child: CircularProgressIndicator(color: _brand, strokeWidth: 2)),
      );
    }
    switch (_booking.status) {
      case 'pending_approval':
        return _buildPendingActions();
      case 'visit_accepted':
      case 'awaiting_payment':
        return _buildAwaitingPaymentActions();
      case 'rejected':
        return _buildRejectedActions();
      case 'paid':
        return _buildPaymentUnderReviewCard();
      case 'visit_completed':
      case 'confirmed':
        return Column(children: [
          _primaryBtn(
            label: 'Leave a Review',
            icon: Icons.star_rounded,
            onTap: _showReviewSheet,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 12),
          _outlineBtn(
              label: 'Browse More Properties',
              onTap: () => Navigator.pop(context)),
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

  // ── Payment Under Review Card ─────────────────────────────────────────────

  Widget _buildPaymentUnderReviewCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Submitted',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                  ),
                ),
                Text(
                  'Under admin review • Verified soon',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Submitted',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFD97706),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _inkSub),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.inter(fontSize: 12.5, color: _inkSub)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ── Pending Actions ───────────────────────────────────────────────────────

  Widget _buildPendingActions() {
    return Column(
      children: [
        _primaryBtn(
          label: 'Remind Owner',
          icon: Icons.notifications_active_rounded,
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

  // ── Awaiting Payment Actions ──────────────────────────────────────────────

  Widget _buildAwaitingPaymentActions() {
    final hasProof = _booking.paymentProofUrl?.isNotEmpty == true;
    return Column(
      children: [
        if (!hasProof || _booking.status == 'awaiting_payment') ...[
          _primaryBtn(
            label: 'Upload Payment Receipt',
            icon: Icons.upload_file_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PaymentChoiceScreen(booking: _booking)),
            ).then((_) => _refreshBooking()),
            color: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 10),
        ],
        _outlineBtn(
            label: 'Browse More Properties',
            onTap: () => Navigator.pop(context)),
      ],
    );
  }

  // ── Rejected Actions ──────────────────────────────────────────────────────

  Widget _buildRejectedActions() {
    return Column(
      children: [
        _primaryBtn(
          label: 'Re-upload Payment Receipt',
          icon: Icons.upload_file_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentChoiceScreen(
                booking: _booking,
                propertyTitle: _booking.propertyTitle ?? '',
              ),
            ),
          ).then((_) => _refreshBooking()),
          color: const Color(0xFF16A34A),
        ),
        const SizedBox(height: 10),
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _brand.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.directions_walk_rounded, color: _brand, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'Did you visit the property?',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Let us know if you were able to inspect the room.',
            style: GoogleFonts.inter(fontSize: 13, color: _inkSub),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: _choiceBtn(
                      label: 'Yes, I visited',
                      icon: Icons.check_circle_rounded,
                      color: _brand,
                      onTap: () => _handleVisitedAnswer(true))),
              const SizedBox(width: 12),
              Expanded(
                  child: _choiceBtn(
                      label: 'Not yet',
                      icon: Icons.cancel_rounded,
                      color: const Color(0xFF94A3B8),
                      isOutlined: true,
                      onTap: () => _handleVisitedAnswer(false))),
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
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.thumb_up_alt_rounded, color: Color(0xFF16A34A), size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'Did you like the property?',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'If you liked it, you can proceed with payment to lock in your booking.',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF15803D),
                  fontWeight: FontWeight.w600,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: _choiceBtn(
                      label: 'Yes, I want to book',
                      icon: Icons.thumb_up_rounded,
                      color: const Color(0xFF16A34A),
                      onTap: () => _handleLikedAnswer(true))),
              const SizedBox(width: 12),
              Expanded(
                  child: _choiceBtn(
                      label: 'Not interested',
                      icon: Icons.thumb_down_rounded,
                      color: const Color(0xFF94A3B8),
                      isOutlined: true,
                      onTap: () => _handleLikedAnswer(false))),
            ],
          ),
          if (_booking.status == 'awaiting_payment' &&
              _booking.visitLiked == true) ...[
            const SizedBox(height: 20),
            _primaryBtn(
              label: 'Proceed to Payment',
              icon: Icons.credit_card_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PaymentChoiceScreen(
                        booking: _booking,
                        propertyTitle: _booking.propertyTitle ?? '')),
              ),
              color: const Color(0xFF16A34A),
            ),
          ],
        ],
      ),
    );
  }

  // ── Shared Executive Button Widgets ──────────────────────────────────────

  Widget _primaryBtn({
    required String label,
    required VoidCallback onTap,
    required Color color,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5)),
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
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border, width: 1.5),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                color: color, fontWeight: FontWeight.w700, fontSize: 13.5)),
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
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.white : color,
          borderRadius: BorderRadius.circular(16),
          border: isOutlined ? Border.all(color: _border, width: 1.5) : null,
          boxShadow: isOutlined
              ? null
              : [
                  BoxShadow(
                      color: color.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 4)),
                ],
        ),
        child: Column(
          children: [
            Icon(icon, color: isOutlined ? _inkSub : Colors.white, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isOutlined ? _inkSub : Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Status Config (Curated Senior UI Palette) ───────────────────────────────

  _StatusConfig _statusConfig(String status) {
    switch (status) {
      case 'pending_approval':
        return const _StatusConfig(
          icon: Icons.hourglass_top_rounded,
          color: Color(0xFFD97706),
          bgColor: Color(0xFFFEF3C7),
          borderColor: Color(0xFFF59E0B),
          badgeLabel: 'Pending Approval',
          title: 'Visit Requested',
          subtitle:
              'Your visit request has been sent to the owner. You\'ll be notified once accepted.',
        );
      case 'visit_accepted':
        return const _StatusConfig(
          icon: Icons.check_circle_rounded,
          color: Color(0xFF16A34A),
          bgColor: Color(0xFFDCFCE7),
          borderColor: Color(0xFF22C55E),
          badgeLabel: 'Visit Approved',
          title: 'Visit Approved!',
          subtitle:
              'The owner accepted your visit. Head over to inspect the property on schedule.',
        );
      case 'awaiting_payment':
      case 'visit_liked':
        return const _StatusConfig(
          icon: Icons.thumb_up_alt_rounded,
          color: Color(0xFF16A34A),
          bgColor: Color(0xFFDCFCE7),
          borderColor: Color(0xFF22C55E),
          badgeLabel: 'Property Liked',
          title: 'Property Reserved 🎉',
          subtitle:
              'You liked the room! Complete your payment receipt upload to finalize.',
        );
      case 'rejected':
        return const _StatusConfig(
          icon: Icons.cancel_rounded,
          color: Color(0xFFE11D48),
          bgColor: Color(0xFFFFE4E6),
          borderColor: Color(0xFFF43F5E),
          badgeLabel: 'Declined',
          title: 'Visit Declined',
          subtitle:
              'The owner was unable to accommodate your visit request at this time.',
        );
      case 'cancelled':
        return const _StatusConfig(
          icon: Icons.cancel_outlined,
          color: Color(0xFF475569),
          bgColor: Color(0xFFF1F5F9),
          borderColor: Color(0xFF94A3B8),
          badgeLabel: 'Cancelled',
          title: 'Request Cancelled',
          subtitle: 'This visit request was cancelled.',
        );
      case 'paid':
        return const _StatusConfig(
          icon: Icons.receipt_long_rounded,
          color: Color(0xFF16A34A),
          bgColor: Color(0xFFF0FDF4),
          borderColor: Color(0xFFBBF7D0),
          badgeLabel: 'Under Review',
          title: 'Payment Submitted',
          subtitle:
              'Your receipt has been received. Admin is verifying your payment.',
        );
      case 'confirmed':
        return const _StatusConfig(
          icon: Icons.home_rounded,
          color: _brand,
          bgColor: Color(0xFFDBEAFE),
          borderColor: Color(0xFF3B82F6),
          badgeLabel: 'Confirmed',
          title: 'Move-In Confirmed 🎉',
          subtitle: 'Congratulations! Your room reservation is official.',
        );
      case 'visit_completed':
        return const _StatusConfig(
          icon: Icons.done_all_rounded,
          color: Color(0xFF64748B),
          bgColor: Color(0xFFF8FAFC),
          borderColor: Color(0xFFE2E8F0),
          badgeLabel: 'Completed',
          title: 'Visit Completed',
          subtitle: 'Your visit has been marked as completed.',
        );
      default:
        return _StatusConfig(
          icon: Icons.info_outline_rounded,
          color: _inkSub,
          bgColor: const Color(0xFFF8FAFC),
          borderColor: const Color(0xFFE2E8F0),
          badgeLabel: status.toUpperCase(),
          title: status,
          subtitle: '',
        );
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
  final Color bgColor;
  final Color borderColor;
  final String badgeLabel;
  final String title;
  final String subtitle;
  const _StatusConfig({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.badgeLabel,
    required this.title,
    required this.subtitle,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Feedback Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _FeedbackSheet extends StatelessWidget {
  final List<String> reasons;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final VoidCallback onContinue;
  const _FeedbackSheet(
      {required this.reasons,
      this.selected,
      required this.onChanged,
      required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
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
            child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 20),
          Text(
            'What didn\'t you like?',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.4),
          ),
          const SizedBox(height: 4),
          Text('Optional — helps us improve the quality.',
              style: GoogleFonts.inter(fontSize: 13, color: _inkSub)),
          const SizedBox(height: 16),
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
            height: 50,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text('Continue',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800, fontSize: 14.5)),
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

  static const _negTags = [
    'Too expensive',
    'Not as described',
    'Bad location',
    'Rude host',
    'Mismatch photos'
  ];
  static const _posTags = [
    'Clean property',
    'Polite host',
    'Good water supply',
    'Quiet area',
    'Accurate photos'
  ];

  String get _emoji => ['😞', '😕', '🙂', '😊', '😍'][_rating - 1];
  String get _ratingText =>
      ['Disappointed', 'Fair', 'Good', 'Very Good', 'Excellent!'][_rating - 1];
  List<String> get _activeTags => _rating <= 2 ? _negTags : _posTags;
  Color get _ratingColor => _rating <= 2 ? const Color(0xFFE11D48) : _brand;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
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
              child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 20),
            Text('Rate Your Visit',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: -0.4)),
            const SizedBox(height: 4),
            Text('Help others make informed decisions.',
                style: GoogleFonts.inter(color: _inkSub, fontSize: 13)),
            const SizedBox(height: 20),

            // Emoji + label
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Column(
                key: ValueKey(_rating),
                children: [
                  Text(_emoji, style: const TextStyle(fontSize: 42)),
                  const SizedBox(height: 4),
                  Text(_ratingText,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: _ratingColor)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _rating = star;
                      _tags.clear();
                    });
                  },
                  child: AnimatedScale(
                    scale: star <= _rating ? 1.12 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(Icons.star_rounded,
                        color: star <= _rating
                            ? Colors.amber
                            : const Color(0xFFE2E8F0),
                        size: 42),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Tags
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Quick Feedback',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _inkSub)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _activeTags.map((tag) {
                final sel = _tags.contains(tag);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => sel ? _tags.remove(tag) : _tags.add(tag));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? _ratingColor : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(30),
                      border: sel ? null : Border.all(color: _border),
                    ),
                    child: Text(tag,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : _inkSub,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Comment
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Add a comment... (optional)',
                hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _brand, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 20),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ratingColor,
                  disabledBackgroundColor: _ratingColor.withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Submit Review',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800, fontSize: 14.5)),
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
