import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/features/property/screens/booking_status_screen.dart';
import 'package:khozna/widgets/khozna_image.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────
const _bg    = Color(0xFFF8FAFC);
const _card  = Colors.white;
const _ink   = Color(0xFF0F172A);
const _sub   = Color(0xFF64748B);
const _bdr   = Color(0xFFE2E8F0);
const _brand = AppTheme.brandColor;

class BookingRequestScreen extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;
  final String ownerId;
  final String ownerName;
  final double pricePerNight;
  final String? propertyImageUrl;
  final String? propertyLocation;

  const BookingRequestScreen({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
    required this.ownerId,
    required this.ownerName,
    this.pricePerNight = 0,
    this.propertyImageUrl,
    this.propertyLocation,
  });

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0; // 0: Dates & Guests, 1: Bill Summary & Request
  DateTime _checkIn  = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 3));
  int _guestCount = 1;
  final TextEditingController _messageCtrl = TextEditingController();
  bool _isSubmitting = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  int get _nights => _checkOut.difference(_checkIn).inDays.clamp(1, 999);
  double get _totalPrice => widget.pricePerNight > 0 ? widget.pricePerNight * _nights : 0;

  void _nextStep() {
    HapticFeedback.mediumImpact();
    _fadeCtrl.reset();
    setState(() => _currentStep = 1);
    _fadeCtrl.forward();
  }

  void _prevStep() {
    HapticFeedback.lightImpact();
    _fadeCtrl.reset();
    setState(() => _currentStep = 0);
    _fadeCtrl.forward();
  }

  // ─── DATE PICKERS ────────────────────────────────────────────────────────

  Future<void> _pickCheckIn() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkIn,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: _datePickerTheme,
    );
    if (picked != null) {
      setState(() {
        _checkIn = picked;
        if (_checkOut.isBefore(_checkIn.add(const Duration(days: 1)))) {
          _checkOut = _checkIn.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _pickCheckOut() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkOut,
      firstDate: _checkIn.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: _datePickerTheme,
    );
    if (picked != null) setState(() => _checkOut = picked);
  }

  Widget _datePickerTheme(BuildContext ctx, Widget? child) {
    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(primary: _brand),
        dialogBackgroundColor: _card,
      ),
      child: child!,
    );
  }

  // ─── SUBMIT ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    try {
      final bookingId = await BookingRepository.createBookingRequest(
        propertyId: widget.propertyId,
        ownerId: widget.ownerId,
        checkIn: _checkIn,
        checkOut: _checkOut,
        totalPrice: _totalPrice,
        message: _messageCtrl.text.trim().isEmpty ? null : _messageCtrl.text.trim(),
      );

      if (!mounted) return;

      final booking = await BookingRepository.getBookingById(bookingId);
      if (!mounted) return;

      if (booking != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BookingStatusScreen(booking: booking),
          ),
        );
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('पठाइसक्नुभएको') || e.toString().contains('active request')
          ? e.toString().replaceAll('Exception: ', '')
          : e.toString().toLowerCase().contains('network') ||
                  e.toString().toLowerCase().contains('socket')
              ? 'Network error. Check your connection and try again.'
              : e.toString().replaceAll('Exception: ', '');
      _showSnack(msg, const Color(0xFFE11D48));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 18),
          onPressed: () {
            if (_currentStep > 0) {
              _prevStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _currentStep == 0 ? 'Select Dates & Guests' : 'Booking Summary',
          style: GoogleFonts.plusJakartaSans(
            color: _ink, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStepperHeader(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                child: _currentStep == 0 ? _buildStepOneContent() : _buildStepTwoContent(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomCTA(),
    );
  }

  // ─── STEPPER HEADER ────────────────────────────────────────────────────────

  Widget _buildStepperHeader() {
    return Container(
      color: _card,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          _stepperBadge(0, '1', 'Dates & Guests'),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: _currentStep > 0 ? _brand : _bdr,
            ),
          ),
          _stepperBadge(1, '2', 'Bill & Request'),
        ],
      ),
    );
  }

  Widget _stepperBadge(int stepIndex, String number, String label) {
    final bool active = _currentStep == stepIndex;
    final bool done = _currentStep > stepIndex;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? _brand : (active ? _brand : Colors.transparent),
            border: Border.all(color: active || done ? _brand : _sub.withOpacity(0.4), width: 1.5),
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : Text(
                  number,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: active ? Colors.white : _sub,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: active || done ? FontWeight.w700 : FontWeight.w500,
            color: active || done ? _ink : _sub,
          ),
        ),
      ],
    );
  }

  // ─── STEP 1 CONTENT: DATES & GUESTS ────────────────────────────────────────

  Widget _buildStepOneContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPropertyCard(),
        const SizedBox(height: 16),
        _buildDatesCard(),
        const SizedBox(height: 16),
        _buildGuestCounter(),
        const SizedBox(height: 16),
        _buildStepOnePreviewBanner(),
      ],
    );
  }

  Widget _buildStepOnePreviewBanner() {
    final priceStr = NumberFormat('#,##0').format(widget.pricePerNight);
    final totalStr = NumberFormat('#,##0').format(_totalPrice);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _brand.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _brand.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _brand.withOpacity(0.12), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded, color: _brand, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Total',
                  style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: _sub),
                ),
                Text(
                  widget.pricePerNight > 0 ? 'NPR $totalStr' : 'Price upon request',
                  style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: _ink),
                ),
              ],
            ),
          ),
          Text(
            '$_nights ${_nights == 1 ? "night" : "nights"}',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _brand),
          ),
        ],
      ),
    );
  }

  // ─── STEP 2 CONTENT: BILL CARD SUMMARY & REQUEST ───────────────────────────

  Widget _buildStepTwoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDigitalReceiptCard(),
        const SizedBox(height: 16),
        _buildDirectPaymentNotice(),
        const SizedBox(height: 16),
        _buildMessageField(),
      ],
    );
  }

  // ─── BEAUTIFUL DIGITAL RECEIPT / BILL CARD ─────────────────────────────────

  Widget _buildDigitalReceiptCard() {
    final priceStr = NumberFormat('#,##0').format(widget.pricePerNight);
    final totalStr = NumberFormat('#,##0').format(_totalPrice);

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _bdr),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Bill Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BOOKING RECEIPT SUMMARY',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.propertyTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'KHOZNA',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bill Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Check-in & Check-out Summary
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CHECK-IN', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _sub, letterSpacing: 0.8)),
                          const SizedBox(height: 4),
                          Text(DateFormat('MMM d, yyyy').format(_checkIn),
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
                          Text(DateFormat('EEEE').format(_checkIn), style: GoogleFonts.inter(fontSize: 11, color: _sub)),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 36, color: _bdr),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CHECK-OUT', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _sub, letterSpacing: 0.8)),
                            const SizedBox(height: 4),
                            Text(DateFormat('MMM d, yyyy').format(_checkOut),
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
                            Text(DateFormat('EEEE').format(_checkOut), style: GoogleFonts.inter(fontSize: 11, color: _sub)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                _dashedDivider(),
                const SizedBox(height: 16),

                // Details Rows
                _billDetailRow('Host Name', widget.ownerName, icon: Icons.person_outline_rounded),
                const SizedBox(height: 10),
                _billDetailRow('Total Stay Duration', '$_nights ${_nights == 1 ? "Night" : "Nights"}', icon: Icons.nights_stay_outlined),
                const SizedBox(height: 10),
                _billDetailRow('Guests Count', '$_guestCount ${_guestCount == 1 ? "Guest" : "Guests"}', icon: Icons.people_outline_rounded),

                if (widget.pricePerNight > 0) ...[
                  const SizedBox(height: 16),
                  _dashedDivider(),
                  const SizedBox(height: 16),

                  _billDetailRow('Rate per night', 'NPR $priceStr'),
                  const SizedBox(height: 8),
                  _billDetailRow('Subtotal (NPR $priceStr × $_nights)', 'NPR $totalStr'),
                  const SizedBox(height: 8),
                  _billDetailRow('Platform Service Fee', 'NPR 0 (FREE)', isHighlight: true),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: _bdr),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TOTAL DUE',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: _ink, letterSpacing: 0.8)),
                          Text('Pay directly to owner',
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Text(
                        'NPR $totalStr',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _brand,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _billDetailRow(String label, String value, {IconData? icon, bool isHighlight = false}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: _sub),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: isHighlight ? const Color(0xFF16A34A) : _sub,
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: isHighlight ? const Color(0xFF16A34A) : _ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _dashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFCBD5E1)),
              ),
            );
          }),
        );
      },
    );
  }

  // ─── PROPERTY CARD ────────────────────────────────────────────────────────

  Widget _buildPropertyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _bdr),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: KhoznaImage(
              imageUrl: widget.propertyImageUrl ?? '',
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.propertyTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.propertyLocation != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: _sub),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          widget.propertyLocation!,
                          style: GoogleFonts.inter(fontSize: 12, color: _sub),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  'Host: ${widget.ownerName}',
                  style: GoogleFonts.inter(fontSize: 12, color: _sub, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── DIRECT PAYMENT NOTICE ────────────────────────────────────────────────

  Widget _buildDirectPaymentNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Direct Payment to Owner',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF15803D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'After the owner accepts, you\'ll pay them directly. KHOZNA does not collect any payment.',
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF166534), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── DATES CARD ────────────────────────────────────────────────────────────

  Widget _buildDatesCard() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _bdr),
      ),
      child: Column(
        children: [
          _buildDateRow(
            label: 'CHECK-IN',
            date: _checkIn,
            icon: Icons.login_rounded,
            onTap: _pickCheckIn,
            isTop: true,
          ),
          Container(height: 1, color: _bdr, margin: const EdgeInsets.symmetric(horizontal: 16)),
          _buildDateRow(
            label: 'CHECK-OUT',
            date: _checkOut,
            icon: Icons.logout_rounded,
            onTap: _pickCheckOut,
            isTop: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow({
    required String label,
    required DateTime date,
    required IconData icon,
    required VoidCallback onTap,
    required bool isTop,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isTop ? const Radius.circular(18) : Radius.zero,
        bottom: isTop ? Radius.zero : const Radius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: _brand.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _brand, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 10.5, fontWeight: FontWeight.w700, color: _sub, letterSpacing: 0.8)),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('EEE, MMM d, yyyy').format(date),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w800, color: _ink),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _brand.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isTop
                    ? DateFormat('MMM d').format(date)
                    : '$_nights ${_nights == 1 ? "night" : "nights"}',
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700, color: _brand),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: _sub, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── GUEST COUNTER ────────────────────────────────────────────────────────

  Widget _buildGuestCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _bdr),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: _brand.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.people_rounded, color: _brand, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GUESTS',
                    style: GoogleFonts.inter(
                        fontSize: 10.5, fontWeight: FontWeight.w700, color: _sub, letterSpacing: 0.8)),
                const SizedBox(height: 2),
                Text(
                  '$_guestCount ${_guestCount == 1 ? "Guest" : "Guests"}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w800, color: _ink),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _CounterBtn(
                icon: Icons.remove_rounded,
                onTap: _guestCount > 1 ? () => setState(() => _guestCount--) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  '$_guestCount',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.w900, color: _ink),
                ),
              ),
              _CounterBtn(
                icon: Icons.add_rounded,
                onTap: _guestCount < 20 ? () => setState(() => _guestCount++) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── MESSAGE FIELD ────────────────────────────────────────────────────────

  Widget _buildMessageField() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _bdr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Message to Owner',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _sub.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Optional',
                    style: GoogleFonts.inter(fontSize: 10, color: _sub, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _messageCtrl,
            maxLines: 3,
            maxLength: 500,
            style: GoogleFonts.inter(fontSize: 14, color: _ink),
            decoration: InputDecoration(
              hintText: 'Introduce yourself and mention your purpose of stay...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: _sub),
              fillColor: _bg,
              filled: true,
              counterStyle: GoogleFonts.inter(fontSize: 11, color: _sub),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _bdr),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _bdr),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _brand, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM CTA ───────────────────────────────────────────────────────────

  Widget _buildBottomCTA() {
    final total = _totalPrice > 0
        ? 'NPR ${NumberFormat('#,##0').format(_totalPrice)}'
        : 'Price TBD';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      decoration: BoxDecoration(
        color: _card,
        border: Border(top: BorderSide(color: _bdr)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_nights ${_nights == 1 ? "night" : "nights"} · $_guestCount ${_guestCount == 1 ? "guest" : "guests"}',
                        style: GoogleFonts.inter(fontSize: 11.5, color: _sub, fontWeight: FontWeight.w600)),
                    Text(total,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16, fontWeight: FontWeight.w900, color: _ink)),
                  ],
                ),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : (_currentStep == 0 ? _nextStep : _submit),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      disabledBackgroundColor: _brand.withOpacity(0.5),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Row(
                            children: [
                              Text(
                                _currentStep == 0 ? 'Review Summary' : 'Confirm & Request',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, size: 17),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Counter Button
// ─────────────────────────────────────────────────────────────────────────────

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CounterBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: enabled ? _brand.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? _brand.withOpacity(0.25) : Colors.grey.shade200,
          ),
        ),
        child: Icon(icon, size: 17, color: enabled ? _brand : Colors.grey.shade400),
      ),
    );
  }
}
