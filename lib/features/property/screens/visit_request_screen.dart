import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/widgets/khozna_image.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/core/models/user_model.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:flutter/services.dart';
import 'package:khozna/core/utils/formatters.dart';

class VisitRequestScreen extends StatefulWidget {
  final Property property;
  const VisitRequestScreen({super.key, required this.property});

  @override
  State<VisitRequestScreen> createState() => _VisitRequestScreenState();
}

class _VisitRequestScreenState extends State<VisitRequestScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '11:00 AM';
  int _visitingCount = 1;
  bool _isSubmitting = false;
  UserModel? _ownerProfile;
  bool _isLoadingOwner = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<String> _timeSlots = [
    '09:00 AM', '11:00 AM', '01:00 PM',
    '03:00 PM', '05:00 PM', '07:00 PM',
  ];

  late List<DateTime> _upcomingDates;

  static const Color _brand = AppTheme.brandColor;
  static const Color _bg = Color(0xFFF9FAFB);
  static const Color _cardBg = Colors.white;
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _upcomingDates = List.generate(14, (i) => DateTime.now().add(Duration(days: i + 1)));
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _fetchOwnerProfile();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchOwnerProfile() async {
    try {
      final profile = await SupabaseService.getUserProfile(widget.property.ownerId);
      if (mounted) setState(() { _ownerProfile = profile; _isLoadingOwner = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingOwner = false);
    }
  }

  DateTime get _visitDateTime {
    final format = DateFormat('hh:mm a');
    final parsedTime = format.parse(_selectedTimeSlot);
    return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, parsedTime.hour, parsedTime.minute);
  }

  void _nextStep() {
    HapticFeedback.mediumImpact();
    _animController.reset();
    setState(() => _currentStep++);
    _animController.forward();
  }

  void _prevStep() {
    HapticFeedback.lightImpact();
    _animController.reset();
    setState(() => _currentStep--);
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: _buildStepContent(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomCTA(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textPrimary, size: 18),
        onPressed: () {
          if (_currentStep > 0) _prevStep();
          else Navigator.pop(context);
        },
      ),
      title: Text(
        'Schedule a Visit',
        style: GoogleFonts.plusJakartaSans(
          color: _textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 17,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildStepper() {
    const steps = ['Date & Time', 'Guests', 'Confirm'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final idx = i ~/ 2;
            return Expanded(
              child: Container(
                height: 1.5,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: _currentStep > idx ? _brand : _border,
              ),
            );
          }
          final idx = i ~/ 2;
          final done = _currentStep > idx;
          final active = _currentStep == idx;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? _brand : (active ? _brand.withValues(alpha: 0.1) : Colors.transparent),
                  border: Border.all(
                    color: done || active ? _brand : _border,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: done
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : Text(
                        '${idx + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: active ? _brand : _textSecondary,
                        ),
                      ),
              ),
              const SizedBox(width: 6),
              Text(
                steps[idx],
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: active || done ? FontWeight.w700 : FontWeight.w500,
                  color: active || done ? _textPrimary : _textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _buildScheduleStep();
      case 1: return _buildGuestsStep();
      case 2: return _buildReviewStep();
      default: return const SizedBox.shrink();
    }
  }

  // ── STEP 1: DATE & TIME ─────────────────────────────────────────────────────

  Widget _buildScheduleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPropertyCard(),
        const SizedBox(height: 28),
        _sectionLabel('Pick a Date'),
        const SizedBox(height: 14),
        SizedBox(
          height: 88,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _upcomingDates.length,
            itemBuilder: (context, index) {
              final date = _upcomingDates[index];
              final isSelected = _selectedDate.day == date.day &&
                  _selectedDate.month == date.month &&
                  _selectedDate.year == date.year;
              return GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedDate = date); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 62,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? _brand : _cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? _brand : _border, width: 1.5),
                    boxShadow: isSelected ? [BoxShadow(color: _brand.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(date).toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white.withValues(alpha: 0.75) : _textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d').format(date),
                        style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : _textPrimary, height: 1),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM').format(date),
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white.withValues(alpha: 0.75) : _textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
        _sectionLabel('Pick a Time'),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2,
          ),
          itemCount: _timeSlots.length,
          itemBuilder: (context, index) {
            final slot = _timeSlots[index];
            final isSelected = _selectedTimeSlot == slot;
            return GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedTimeSlot = slot); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? _brand : _cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? _brand : _border, width: 1.5),
                ),
                child: Text(
                  slot,
                  style: GoogleFonts.inter(
                    fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : _textPrimary,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        _buildInfoNote('Landlords typically respond faster to daytime scheduling requests.'),
      ],
    );
  }

  // ── STEP 2: GUESTS ───────────────────────────────────────────────────────────

  Widget _buildGuestsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPropertyCard(),
        const SizedBox(height: 28),
        _sectionLabel('How many visitors?'),
        const SizedBox(height: 6),
        Text('Maximum 5 people per visit.', style: GoogleFonts.inter(fontSize: 13, color: _textSecondary)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Visitors', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: _textPrimary)),
                  Text('Up to 5 people', style: GoogleFonts.inter(fontSize: 12, color: _textSecondary)),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  _counterButton(Icons.remove, _visitingCount > 1, () { if (_visitingCount > 1) setState(() => _visitingCount--); }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('$_visitingCount',
                        style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: _textPrimary)),
                  ),
                  _counterButton(Icons.add, _visitingCount < 5, () { if (_visitingCount < 5) setState(() => _visitingCount++); }),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildInfoNote('Please be respectful of the property and neighborhood during physical viewings.', icon: Icons.shield_outlined, color: const Color(0xFFFEF3C7), textColor: const Color(0xFF92400E), iconColor: const Color(0xFFD97706)),
      ],
    );
  }

  Widget _counterButton(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { if (enabled) { HapticFeedback.lightImpact(); onTap(); } },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38, height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? _brand.withValues(alpha: 0.08) : Colors.transparent,
          border: Border.all(color: enabled ? _brand : _border, width: 1.5),
        ),
        child: Icon(icon, size: 18, color: enabled ? _brand : _textSecondary.withValues(alpha: 0.4)),
      ),
    );
  }

  // ── STEP 3: REVIEW ───────────────────────────────────────────────────────────

  Widget _buildReviewStep() {
    final isNightly = widget.property.priceNight > 0;
    final rentLabel = isNightly ? 'per night' : 'per month';
    final rentPrice = isNightly
        ? widget.property.priceNight.toStringAsFixed(0)
        : (widget.property.priceMonth > 0 ? widget.property.priceMonth.toStringAsFixed(0) : widget.property.price);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Review your visit'),
        const SizedBox(height: 6),
        Text('Double-check before confirming.', style: GoogleFonts.inter(fontSize: 13, color: _textSecondary)),
        const SizedBox(height: 20),

        // Property snapshot
        _buildPropertyCard(),
        const SizedBox(height: 16),

        // Visit details card
        Container(
          decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
          child: Column(
            children: [
              _reviewRow(Icons.calendar_today_rounded, 'Date', DateFormat('EEE, d MMM yyyy').format(_selectedDate)),
              _divider(),
              _reviewRow(Icons.access_time_rounded, 'Time', _selectedTimeSlot),
              _divider(),
              _reviewRow(Icons.group_outlined, 'Visitors', '$_visitingCount ${_visitingCount == 1 ? "person" : "people"}'),
              _divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.local_offer_rounded, size: 18, color: _textSecondary),
                    const SizedBox(width: 14),
                    Text('Rent', style: GoogleFonts.inter(fontSize: 13.5, color: _textSecondary)),
                    const Spacer(),
                    Row(
                      children: [
                        SvgPicture.asset('assets/icons/vector of ruppes.svg', width: 13, height: 13,
                            colorFilter: const ColorFilter.mode(_brand, BlendMode.srcIn)),
                        const SizedBox(width: 4),
                        Text(PriceFormatter.format(rentPrice),
                            style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: _brand)),
                        const SizedBox(width: 4),
                        Text(rentLabel, style: GoogleFonts.inter(fontSize: 11, color: _textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // No advance payment note
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDBEAFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.gpp_good_rounded, color: _brand, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Do not pay any advance before physically visiting the property.',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E40AF), height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _textSecondary),
          const SizedBox(width: 14),
          Text(label, style: GoogleFonts.inter(fontSize: 13.5, color: _textSecondary)),
          const Spacer(),
          Text(value, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: _textPrimary)),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(horizontal: 20));

  // ── SHARED WIDGETS ───────────────────────────────────────────────────────────

  Widget _buildPropertyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: KhoznaImage(imageUrl: widget.property.imageUrl, width: 56, height: 56, fit: BoxFit.cover),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.property.title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: _textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 12, color: _brand),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        widget.property.location,
                        style: GoogleFonts.inter(fontSize: 12, color: _textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: _textPrimary, letterSpacing: -0.3));
  }

  Widget _buildInfoNote(String text, {IconData icon = Icons.info_outline_rounded, Color color = const Color(0xFFF0F9FF), Color textColor = const Color(0xFF0369A1), Color iconColor = AppTheme.brandColor}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14), border: Border.all(color: iconColor.withValues(alpha: 0.15))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: textColor, height: 1.5))),
        ],
      ),
    );
  }

  // ── BOTTOM CTA ───────────────────────────────────────────────────────────────

  Widget _buildBottomCTA() {
    final bool isLastStep = _currentStep == 2;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            GestureDetector(
              onTap: _prevStep,
              child: Container(
                width: 50, height: 52,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border, width: 1.5),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _textPrimary),
              ),
            ),
          ],
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () {
                  if (isLastStep) _submit();
                  else _nextStep();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  disabledBackgroundColor: _brand.withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastStep ? 'Confirm Visit' : 'Continue',
                            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                          ),
                          if (!isLastStep) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final isNightly = widget.property.priceNight > 0;
      final finalPrice = isNightly
          ? widget.property.priceNight
          : (widget.property.priceMonth > 0
              ? widget.property.priceMonth
              : double.tryParse(widget.property.price.replaceAll(',', '')) ?? 0);

      final fullVisitDate = _visitDateTime;

      await BookingRepository.createBookingRequest(
        propertyId: widget.property.id,
        ownerId: widget.property.ownerId,
        checkIn: fullVisitDate,
        checkOut: fullVisitDate.add(const Duration(days: 30)),
        totalPrice: finalPrice,
        message: 'अवलोकन मिति: ${DateFormat('yyyy-MM-dd HH:mm').format(fullVisitDate)}, जम्मा व्यक्ति: $_visitingCount',
      );

      if (mounted) {
        HapticFeedback.heavyImpact();
        await BookingRepository.fetchBookedPropertyIds();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
