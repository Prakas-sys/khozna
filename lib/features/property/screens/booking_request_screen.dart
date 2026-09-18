import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/models/review_model.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/features/property/screens/booking_status_screen.dart';
import 'package:khozna/widgets/khozna_image.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────
const _ink   = Color(0xFF0F172A);
const _sub   = Color(0xFF64748B);
const _bdr   = Color(0xFFE2E8F0);
const _brand = AppTheme.brandColor;
const _pillBg = Color(0xFFF1F5F9);

class BookingRequestScreen extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;
  final String ownerId;
  final String ownerName;
  final double pricePerNight;
  final String? propertyImageUrl;
  final String? propertyLocation;
  final String category;
  final String cancellationPolicy;
  final bool isVerified;

  const BookingRequestScreen({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
    required this.ownerId,
    required this.ownerName,
    this.pricePerNight = 0,
    this.propertyImageUrl,
    this.propertyLocation,
    this.category = 'Room',
    this.cancellationPolicy = 'standard',
    this.isVerified = false,
  });

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0; // 0: Review & continue, 1: Message the host, 2: Confirm & request

  DateTime _checkIn  = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 3));
  int _guestCount = 1;
  final TextEditingController _messageCtrl = TextEditingController();
  bool _isSubmitting = false;

  // Real review data state
  List<ReviewModel> _reviews = [];
  bool _isLoadingReviews = true;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();

    _loadRealReviews();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRealReviews() async {
    try {
      final reviews = await BookingRepository.fetchReviewsForProperty(widget.propertyId);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  double? get _avgRating => _reviews.isNotEmpty
      ? (_reviews.map((e) => e.rating).reduce((a, b) => a + b) / _reviews.length)
      : null;

  int get _nights => _checkOut.difference(_checkIn).inDays.clamp(1, 999);
  double get _totalPrice => widget.pricePerNight > 0 ? widget.pricePerNight * _nights : 0;

  void _goToStep(int step) {
    if (step == _currentStep) return;
    HapticFeedback.selectionClick();
    _fadeCtrl.reset();
    setState(() => _currentStep = step);
    _fadeCtrl.forward();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _goToStep(_currentStep + 1);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.pop(context);
    }
  }

  // ─── INTERACTIVE MODALS (CHANGE DATES, CHANGE GUESTS, PRICE DETAILS) ──────

  Future<void> _changeDates() async {
    HapticFeedback.lightImpact();
    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _checkIn, end: _checkOut),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _ink,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _checkIn = pickedRange.start;
        _checkOut = pickedRange.end;
      });
    }
  }

  void _changeGuests() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _bdr,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Guests',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select the number of guests staying at this property.',
                    style: GoogleFonts.inter(fontSize: 13, color: _sub),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Adults & Children',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          Text(
                            'Ages 13 or above',
                            style: GoogleFonts.inter(fontSize: 12, color: _sub),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _counterCircleButton(
                            icon: Icons.remove,
                            onTap: _guestCount > 1
                                ? () {
                                    setSheetState(() => _guestCount--);
                                    setState(() {});
                                  }
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '$_guestCount',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                          ),
                          _counterCircleButton(
                            icon: Icons.add,
                            onTap: _guestCount < 20
                                ? () {
                                    setSheetState(() => _guestCount++);
                                    setState(() {});
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Save Guests',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPriceDetails() {
    HapticFeedback.lightImpact();
    final priceStr = NumberFormat('#,##0').format(widget.pricePerNight);
    final totalStr = NumberFormat('#,##0').format(_totalPrice);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _bdr,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Price details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 20),
              if (widget.pricePerNight > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NPR $priceStr × $_nights ${_nights == 1 ? "night" : "nights"}',
                      style: GoogleFonts.inter(fontSize: 14, color: _ink),
                    ),
                    Text(
                      'NPR $totalStr',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Service fee',
                      style: GoogleFonts.inter(fontSize: 14, color: _ink),
                    ),
                    Text(
                      'NPR 0 (FREE)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: _bdr, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total (NPR)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    Text(
                      'NPR $totalStr',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'Price upon request with the host directly.',
                  style: GoogleFonts.inter(fontSize: 14, color: _sub),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Done',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── SUBMIT REQUEST ───────────────────────────────────────────────────────

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

  // ─── BUILD SCREEN ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    String stepTitle = 'Review and continue';
    if (_currentStep == 1) stepTitle = 'Message the host';
    if (_currentStep == 2) stepTitle = 'Confirm and request';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            _currentStep > 0
                ? Icons.arrow_back_ios_new_rounded
                : Icons.arrow_back_rounded,
            color: _ink,
            size: 20,
          ),
          onPressed: _prevStep,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: _ink, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Screen Title
                      Text(
                        stepTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Step View Builder
                      if (_currentStep == 0) _buildStep1ReviewAndContinue(),
                      if (_currentStep == 1) _buildStep2MessageHost(),
                      if (_currentStep == 2) _buildStep3ConfirmAndRequest(),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Sticky Progress & Next Button
            _buildBottomStickyBar(),
          ],
        ),
      ),
    );
  }

  // ─── STEP 1: REVIEW AND CONTINUE (MATCHING SCREENSHOT) ─────────────────────

  Widget _buildStep1ReviewAndContinue() {
    final totalStr = NumberFormat('#,##0').format(_totalPrice);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _bdr, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Property Header (Image + Title + Rating)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: KhoznaImage(
                    imageUrl: widget.propertyImageUrl ?? '',
                    width: 72,
                    height: 72,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 15, color: _ink),
                          const SizedBox(width: 4),
                          Text(
                            _avgRating != null
                                ? '${_avgRating!.toStringAsFixed(2)} (${_reviews.length})'
                                : (_isLoadingReviews ? '...' : 'New'),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          if (_avgRating != null && _avgRating! >= 4.5) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.verified_user_rounded,
                              size: 14,
                              color: _brand,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Guest favorite',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _ink,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: _bdr),

          // Dates Row
          _buildReviewRow(
            title: 'Dates',
            subtitle: '${DateFormat('MMM d').format(_checkIn)} – ${DateFormat('d, yyyy').format(_checkOut)}',
            buttonLabel: 'Change',
            onTap: _changeDates,
          ),

          const Divider(height: 1, color: _bdr),

          // Guests Row
          _buildReviewRow(
            title: 'Guests',
            subtitle: '$_guestCount ${_guestCount == 1 ? "guest" : "guests"}',
            buttonLabel: 'Change',
            onTap: _changeGuests,
          ),

          const Divider(height: 1, color: _bdr),

          // Total Price Row
          _buildReviewRow(
            title: 'Total price',
            subtitle: widget.pricePerNight > 0
                ? 'NPR $totalStr including fees'
                : 'Price upon request',
            buttonLabel: 'Details',
            onTap: _showPriceDetails,
          ),

          const Divider(height: 1, color: _bdr),

          // Free Cancellation Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free cancellation',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(fontSize: 13, color: _sub, height: 1.4),
                    children: [
                      TextSpan(
                        text: 'Cancel before ${DateFormat('MMM d').format(_checkIn.subtract(const Duration(days: 1)))} for a full refund. ',
                      ),
                      TextSpan(
                        text: 'Full policy',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: _ink,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow({
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 13.5, color: _sub),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _pillBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                buttonLabel,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── STEP 2: MESSAGE THE HOST ─────────────────────────────────────────────

  Widget _buildStep2MessageHost() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Host Info Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _bdr),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: _pillBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.ownerName.isNotEmpty ? widget.ownerName[0].toUpperCase() : 'H',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Host: ${widget.ownerName}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Response time: usually within a few hours',
                      style: GoogleFonts.inter(fontSize: 12, color: _sub),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Message Box
        Text(
          'Say hello to your host',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Share why you are visiting and who is coming with you to help the host approve your stay.',
          style: GoogleFonts.inter(fontSize: 13, color: _sub, height: 1.4),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _messageCtrl,
          maxLines: 4,
          maxLength: 500,
          style: GoogleFonts.inter(fontSize: 14, color: _ink),
          decoration: InputDecoration(
            hintText: 'Hi ${widget.ownerName}, I am visiting for...',
            hintStyle: GoogleFonts.inter(fontSize: 13.5, color: _sub),
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _bdr),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _bdr),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _ink, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),

        const SizedBox(height: 14),
        Text(
          'Quick details (tap to add):',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _sub),
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chipOption('Visiting for work'),
            _chipOption('Vacation stay'),
            _chipOption('Family trip'),
            _chipOption('Quiet & respectful guest'),
          ],
        ),
      ],
    );
  }

  Widget _chipOption(String label) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        if (_messageCtrl.text.isEmpty) {
          _messageCtrl.text = label;
        } else {
          _messageCtrl.text += '. $label';
        }
        setState(() {});
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: _pillBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _bdr),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: _ink),
        ),
      ),
    );
  }

  // ─── STEP 3: CONFIRM AND REQUEST ──────────────────────────────────────────

  Widget _buildStep3ConfirmAndRequest() {
    final totalStr = NumberFormat('#,##0').format(_totalPrice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _bdr),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trip Summary',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 12),
              _summaryRow('Property', widget.propertyTitle),
              const SizedBox(height: 8),
              _summaryRow('Dates', '${DateFormat('MMM d').format(_checkIn)} – ${DateFormat('MMM d, yyyy').format(_checkOut)} ($_nights ${_nights == 1 ? "night" : "nights"})'),
              const SizedBox(height: 8),
              _summaryRow('Guests', '$_guestCount ${_guestCount == 1 ? "guest" : "guests"}'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: _bdr),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Due',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  Text(
                    widget.pricePerNight > 0 ? 'NPR $totalStr' : 'Price upon request',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: _brand,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Direct Payment Notice Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFF16A34A),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Direct Payment to Owner',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Once ${widget.ownerName} approves your request, you will pay them directly in person or via digital transfer. Khozna charges NPR 0 fees.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF166534),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Ground Rules
        Text(
          'Ground rules',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'We ask every guest to remember a few simple things about what makes a great guest.',
          style: GoogleFonts.inter(fontSize: 13, color: _sub),
        ),
        const SizedBox(height: 12),
        _groundRuleItem('Follow the house rules and check-in guidelines.'),
        _groundRuleItem('Treat your host’s home like your own.'),
        _groundRuleItem('Keep noise levels respectful during night hours.'),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: _sub)),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _groundRuleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 6, color: _ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 13, color: _ink, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM STICKY BAR (PROGRESS INDICATOR + NEXT BUTTON) ─────────────────

  Widget _buildBottomStickyBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: _bdr, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3 Segmented Progress Bar
          Row(
            children: List.generate(3, (index) {
              final active = index <= _currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: active ? _ink : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),

          // Next / Request to Book Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ink,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: _ink.withOpacity(0.5),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      _currentStep == 2 ? 'Request to book' : 'Next',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _counterCircleButton({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? _ink : _bdr,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? _ink : _sub.withOpacity(0.4),
        ),
      ),
    );
  }
}
