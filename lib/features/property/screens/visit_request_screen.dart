import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/widgets/khozna_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

class _VisitRequestScreenState extends State<VisitRequestScreen> {
  int _currentStep = 0; // 0: Schedule, 1: Guests, 2: Review
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = "11:00 AM";
  int _visitingCount = 1;
  bool _isSubmitting = false;
  UserModel? _ownerProfile;
  bool _isLoadingOwner = true;

  final List<String> _stepTitles = [
    'भ्रमण मिति · Schedule',
    'व्यक्ति संख्या · Guests',
    'पुष्टि गर्नुहोस् · Review',
  ];

  final List<String> _timeSlots = [
    "09:00 AM",
    "11:00 AM",
    "01:00 PM",
    "03:00 PM",
    "05:00 PM",
    "07:00 PM"
  ];

  late List<DateTime> _upcomingDates;

  @override
  void initState() {
    super.initState();
    _fetchOwnerProfile();
    // Generate dates for the next 14 days
    _upcomingDates = List.generate(14, (i) => DateTime.now().add(Duration(days: i + 1)));
  }

  Future<void> _fetchOwnerProfile() async {
    try {
      final profile = await SupabaseService.getUserProfile(
        widget.property.ownerId,
      );
      if (mounted) {
        setState(() {
          _ownerProfile = profile;
          _isLoadingOwner = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingOwner = false);
    }
  }

  DateTime get _visitDateTime {
    final format = DateFormat("hh:mm a");
    final parsedTime = format.parse(_selectedTimeSlot);
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      parsedTime.hour,
      parsedTime.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(
          children: [
            Text(
              'भ्रमण अनुरोध',
              style: GoogleFonts.notoSansDevanagari(
                color: const Color(0xFF1A1A2E),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              'Visit Request Wizard',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withOpacity(0.08),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: const Color(0xFF00C853).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFF00C853),
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  'सुरक्षित',
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF00C853),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: _buildStepContent(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomCTA(),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final isCompleted = _currentStep > index;
              final isCurrent = _currentStep == index;
              return Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? const Color(0xFF00C853)
                          : (isCurrent ? AppTheme.brandColor : Colors.grey[200]),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: AppTheme.brandColor.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : Text(
                            '${index + 1}',
                            style: GoogleFonts.inter(
                              color: isCurrent ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _stepTitles[index].split(' · ').last,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isCurrent || isCompleted
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isCurrent || isCompleted
                          ? Colors.black87
                          : Colors.grey[400],
                    ),
                  ),
                  if (index < 2) ...[
                    const SizedBox(width: 10),
                    Container(
                      width: 20,
                      height: 1.5,
                      color: _currentStep > index ? const Color(0xFF00C853) : Colors.grey[300],
                    ),
                    const SizedBox(width: 10),
                  ],
                ],
              );
            }),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: Colors.grey[100],
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildScheduleStep();
      case 1:
        return _buildGuestsStep();
      case 2:
        return _buildReviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildScheduleStep() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPropertyHeaderMini(),
        const SizedBox(height: 24),
        Text(
          'Select Date',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        // Horizontal custom calendar list
        SizedBox(
          height: 86,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _upcomingDates.length,
            itemBuilder: (context, index) {
              final date = _upcomingDates[index];
              final isSelected = _selectedDate.day == date.day &&
                  _selectedDate.month == date.month &&
                  _selectedDate.year == date.year;
              final dayName = DateFormat('E').format(date).toUpperCase();
              final dayNum = DateFormat('d').format(date);
              final monthName = DateFormat('MMM').format(date);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDate = date);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 62,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.brandColor : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.brandColor : Colors.grey.shade200,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.brandColor.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayNum,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : Colors.black87,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        monthName,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Select Time',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        // Time slot grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.1,
          ),
          itemCount: _timeSlots.length,
          itemBuilder: (context, index) {
            final slot = _timeSlots[index];
            final isSelected = _selectedTimeSlot == slot;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTimeSlot = slot);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.brandColor : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.brandColor.withOpacity(0.1),
                            blurRadius: 10,
                          )
                        ]
                      : null,
                ),
                child: Text(
                  slot,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppTheme.brandColor : Colors.black87,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.brandColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Landlords usually accept requests faster when scheduled during daytime hours.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.blue[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuestsStep() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPropertyHeaderMini(),
        const SizedBox(height: 32),
        Text(
          'How many visitors are coming?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'यस कोठाको अवलोकनका लागि आउने व्यक्तिको संख्या चयन गर्नुहोस्।',
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 10,
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visitors Count',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Limit: Up to 5 people',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Minus Button
                  GestureDetector(
                    onTap: () {
                      if (_visitingCount > 1) {
                        HapticFeedback.lightImpact();
                        setState(() => _visitingCount--);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _visitingCount > 1 ? Colors.grey.shade300 : Colors.grey.shade100,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.remove,
                        color: _visitingCount > 1 ? Colors.black87 : Colors.grey[300],
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$_visitingCount',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Plus Button
                  GestureDetector(
                    onTap: () {
                      if (_visitingCount < 5) {
                        HapticFeedback.lightImpact();
                        setState(() => _visitingCount++);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _visitingCount < 5 ? AppTheme.brandColor : Colors.grey.shade100,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.add,
                        color: _visitingCount < 5 ? AppTheme.brandColor : Colors.grey[300],
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Polite Reminder',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please ensure guests remain respectful of neighborhood house rules during physical viewings.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFB45309),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final isNightly = widget.property.priceNight > 0;
    final rentLabel = isNightly ? 'Rent / Night' : 'Rent / Month';
    final rentPrice = isNightly 
        ? widget.property.priceNight.toStringAsFixed(0) 
        : (widget.property.priceMonth > 0 
            ? widget.property.priceMonth.toStringAsFixed(0) 
            : widget.property.price);

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Trip Details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        // Airbnb-style Trip Summary Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            children: [
              // Mini Property Card info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: KhoznaImage(
                        imageUrl: widget.property.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.property.category,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.brandColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.property.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: Colors.grey, size: 12),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.property.location,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
              const Divider(height: 1),
              // Schedule Details list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    _buildSummaryDetailRow(
                      Icons.calendar_today_rounded,
                      'Visit Date',
                      DateFormat('EEE, MMMM d, yyyy').format(_selectedDate),
                    ),
                    const SizedBox(height: 14),
                    _buildSummaryDetailRow(
                      Icons.access_time_rounded,
                      'Time Slot',
                      _selectedTimeSlot,
                    ),
                    const SizedBox(height: 14),
                    _buildSummaryDetailRow(
                      Icons.group_outlined,
                      'Visitors Count',
                      '$_visitingCount Persons',
                    ),
                    const SizedBox(height: 14),
                    _buildSummaryDetailRow(
                      Icons.account_balance_wallet_outlined,
                      rentLabel,
                      'Rs. ${PriceFormatter.format(rentPrice)}',
                      valueColor: AppTheme.brandColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        // Khozna Trust Safety Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDBEAFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.gpp_good_rounded, color: AppTheme.brandColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khozna Safety Protection',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Our safety policy strictly forbids landlords from demanding advanced booking fees prior to physically visiting properties. Do not pay first.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.blue[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyHeaderMini() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: KhoznaImage(
              imageUrl: widget.property.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.property.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Stay with ${_ownerProfile?.fullName ?? widget.property.ownerName ?? "Khozna Landlord"}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDetailRow(IconData icon, String title, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: valueColor ?? Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCTA() {
    final bool isLastStep = _currentStep == 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _currentStep--);
                },
                child: Container(
                  height: 52,
                  width: 52,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.black87),
                ),
              ),
            ],
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          if (isLastStep) {
                            _submit();
                          } else {
                            setState(() => _currentStep++);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandColor,
                    disabledBackgroundColor: AppTheme.brandColor.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isLastStep ? 'भेजन्नुहोस् · Confirm Request' : 'जारी राख्नुहोस् · Continue',
                          style: GoogleFonts.notoSansDevanagari(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
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
        message: 'भ्रमण मिति: ${DateFormat('yyyy-MM-dd HH:mm').format(fullVisitDate)}, जम्मा व्यक्ति: $_visitingCount',
      );

      if (mounted) {
        HapticFeedback.heavyImpact();
        await BookingRepository.fetchBookedPropertyIds(); // Update global store
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
