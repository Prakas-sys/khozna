import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:khozna/widgets/khozna_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/core/models/user_model.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class VisitRequestScreen extends StatefulWidget {
  final Property property;

  const VisitRequestScreen({super.key, required this.property});

  @override
  State<VisitRequestScreen> createState() => _VisitRequestScreenState();
}

class _VisitRequestScreenState extends State<VisitRequestScreen> {
  DateTime _visitDate = DateTime.now().add(const Duration(days: 1));
  int _visitingCount = 1;
  bool _isSubmitting = false;
  UserModel? _ownerProfile;
  bool _isLoadingOwner = true;

  @override
  void initState() {
    super.initState();
    _fetchOwnerProfile();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Column(
          children: [
            Text(
              'भ्रमण अनुरोध',
              style: GoogleFonts.notoSansDevanagari(
                color: const Color(0xFF1A1A2E),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              'Visit Details',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
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
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'सुरक्षित',
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF00C853),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildPropertyHeader(),
            const SizedBox(height: 16),
            _buildCombinedDetailsCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomCTA(),
    );
  }

  Widget _buildPropertyHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: KhoznaImage(
                imageUrl: widget.property.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.property.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1A1A2E),
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 9,
                      backgroundColor: Colors.grey[100],
                      backgroundImage: _ownerProfile?.avatarUrl != null
                          ? NetworkImage(_ownerProfile!.avatarUrl!)
                          : null,
                      child: _ownerProfile?.avatarUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 10,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Owned by ${_ownerProfile?.fullName ?? widget.property.ownerName}',
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 12,
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
    );
  }

  Widget _buildCombinedDetailsCard() {
    final isNightly = widget.property.priceNight > 0;
    final rentLabel = isNightly ? 'प्रति रात भाडा · Rent/Night' : 'मासिक भाडा · Rent/Month';
    final rentPrice = isNightly 
        ? widget.property.priceNight.toStringAsFixed(0) 
        : (widget.property.priceMonth > 0 
            ? widget.property.priceMonth.toStringAsFixed(0) 
            : widget.property.price);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Visit Date & Time Row
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _selectVisitDate();
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.brandColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppTheme.brandColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'भ्रमणको मिति र समय · Date & Time',
                          style: GoogleFonts.notoSansDevanagari(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getFormattedDate(_visitDate),
                          style: GoogleFonts.notoSansDevanagari(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getDayName(_visitDate),
                          style: GoogleFonts.notoSansDevanagari(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit_calendar_rounded, size: 12, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          'बदल्नुहोस्',
                          style: GoogleFonts.notoSansDevanagari(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Divider(height: 1, color: Colors.grey.shade100, indent: 20, endIndent: 20),

          // 2. Visiting Count Row
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _showVisitingPicker();
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.brandColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.group_outlined,
                      color: AppTheme.brandColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'आउने संख्या · Visiting',
                          style: GoogleFonts.notoSansDevanagari(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'तपाईं / $_visitingCount जना',
                          style: GoogleFonts.notoSansDevanagari(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 12, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          'बदल्नुहोस्',
                          style: GoogleFonts.notoSansDevanagari(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade100, indent: 20, endIndent: 20),

          // 3. Rent Details Row
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppTheme.brandColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rentLabel,
                        style: GoogleFonts.notoSansDevanagari(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹ ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.brandColor,
                            ),
                          ),
                          Text(
                            rentPrice,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.brandColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C853).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              'बजेटमै राम्रो',
                              style: GoogleFonts.notoSansDevanagari(
                                fontSize: 9,
                                color: const Color(0xFF00C853),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'अन्तिम मूल्य भ्रमणपछि छलफल गरिनेछ',
                        style: GoogleFonts.notoSansDevanagari(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
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



  Widget _buildBottomCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(36, 16, 36, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'अब के गर्न चाहनुहुन्छ? (What\'s next?)',
            style: GoogleFonts.notoSansDevanagari(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.grey[800],
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 16),
          _largeButton(
            label: 'भ्रमण गर्नुहोस् (Schedule Visit)',
            icon: Icons.calendar_today_rounded,
            color: AppTheme.brandColor,
            onPressed: _isSubmitting
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    _submit();
                  },
            isLoading: _isSubmitting,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 12,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                'भ्रमण गर्नु अघि सम्पूर्ण विवरण पुष्टि गर्नुहोस्',
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _largeButton({
    required String label,
    IconData? icon,
    String? svgIcon,
    required Color color,
    required VoidCallback? onPressed,
    bool isOutlined = false,
    bool isLoading = false,
  }) {
    final iconColor = isOutlined ? color : Colors.white;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.white : color,
          borderRadius: BorderRadius.circular(50),
          border: isOutlined
              ? Border.all(color: color.withOpacity(0.2), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            if (svgIcon != null)
              SvgPicture.asset(
                svgIcon,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              )
            else if (icon != null)
              Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.notoSansDevanagari(
                  color: isOutlined ? color : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: iconColor,
                  strokeWidth: 2,
                ),
              )
            else
              Icon(Icons.chevron_right, color: iconColor, size: 20),
          ],
        ),
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    final String period = date.hour >= 12 ? 'PM' : 'AM';
    final int hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final String minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${_getMonthName(date.month)}, ${date.year} at $hour:$minute $period';
  }

  String _getMonthName(int month) {
    return [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ][month - 1];
  }

  String _getDayName(DateTime date) {
    const days = [
      'आइतबार (Sun)',
      'सोमबार (Mon)',
      'मंगलबार (Tue)',
      'बुधबार (Wed)',
      'बिहीबार (Thu)',
      'शुक्रबार (Fri)',
      'शनिबार (Sat)',
    ];
    return days[date.weekday % 7];
  }

  Future<void> _selectVisitDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.brandColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_visitDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppTheme.brandColor,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );
      if (pickedTime != null) {
        setState(() {
          _visitDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _showVisitingPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'आउने संख्या चयन गर्नुहोस्',
              style: GoogleFonts.notoSansDevanagari(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [1, 2, 3, 4, 5]
                  .map(
                    (n) => InkWell(
                      onTap: () {
                        setState(() => _visitingCount = n);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _visitingCount == n
                              ? AppTheme.brandColor
                              : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$n',
                          style: TextStyle(
                            color: _visitingCount == n
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
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

      await BookingRepository.createBookingRequest(
        propertyId: widget.property.id,
        ownerId: widget.property.ownerId,
        checkIn: _visitDate,
        checkOut: _visitDate.add(const Duration(days: 30)),
        totalPrice: finalPrice,
        message:
            'भ्रमण मिति: ${_getFormattedDate(_visitDate)} (${_getDayName(_visitDate)}), जम्मा व्यक्ति: $_visitingCount',
      );
      if (mounted) {
        HapticFeedback.heavyImpact();
        await BookingRepository.fetchBookedPropertyIds(); // Update global store
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
