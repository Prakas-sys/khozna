import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/features/chat/screens/chat_screen.dart' as chat_page;
import 'package:khozna/widgets/khozna_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:khozna/core/models/property_model.dart';
import 'package:khozna/core/models/user_model.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:flutter/services.dart';

class VisitRequestScreen extends StatefulWidget {
  final Property property;

  const VisitRequestScreen({
    super.key,
    required this.property,
  });

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
      final profile = await SupabaseService.getUserProfile(widget.property.ownerId);
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
              'भ्रमण अनुरोध समीक्षा',
              style: GoogleFonts.mukta(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18),
            ),
            Text(
              'Review your visit details',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: AppTheme.brandColor, size: 14),
                const SizedBox(width: 4),
                Text(
                  'सुरक्षित प्लेटफर्म',
                  style: GoogleFonts.mukta(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700]),
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
            const SizedBox(height: 24),
            _buildActionRow(
              icon: Icons.calendar_month_rounded,
              iconColor: AppTheme.brandColor,
              label: 'भ्रमणको मिति · Visit Date',
              value: _getFormattedDate(_visitDate),
              subtitle: _getDayName(_visitDate),
              onTap: () => _selectVisitDate(),
            ),
            const SizedBox(height: 16),
            _buildActionRow(
              icon: Icons.group_outlined,
              iconColor: AppTheme.brandColor,
              label: 'आउने संख्या · Visiting',
              value: 'तपाईं / $_visitingCount जना',
              onTap: () => _showVisitingPicker(),
            ),
            const SizedBox(height: 16),
            _buildRentCard(),
            const SizedBox(height: 16),
            _buildSafetyBanner(),
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
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
                  widget.property.title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.grey[100],
                      backgroundImage: _ownerProfile?.avatarUrl != null ? NetworkImage(_ownerProfile!.avatarUrl!) : null,
                      child: _ownerProfile?.avatarUrl == null ? const Icon(Icons.person, size: 10, color: Colors.grey) : null,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Owned by ${_ownerProfile?.fullName ?? widget.property.ownerName}',
                        style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
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

  Widget _buildActionRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '· $subtitle',
                        style: GoogleFonts.mukta(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, size: 14, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(
                    'बदल्नुहोस्',
                    style: GoogleFonts.mukta(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.brandColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.brandColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'मासिक भाडा (Monthly Rent)',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹ ${widget.property.price}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.brandColor),
                ),
                Text(
                  'अन्तिम मूल्य भ्रमणपछि छलफल गरिनेछ',
                  style: GoogleFonts.mukta(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  '(Price will be discussed after visit)',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.location_city_rounded, color: AppTheme.brandColor, size: 32),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.brandColor,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'बजेटमै उत्तम रोजाई',
                  style: GoogleFonts.mukta(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.brandColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user, color: AppTheme.brandColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'तपाईंको जानकारी सुरक्षित छ',
                  style: GoogleFonts.mukta(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  'हामी तपाईंको व्यक्तिगत जानकारीलाई गोप्य राख्छौं र सुरक्षित गर्छौं',
                  style: GoogleFonts.mukta(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
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
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'अब के गर्न चाहनुहुन्छ? (What\'s next?)',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[800]),
          ),
          const SizedBox(height: 16),
          _largeButton(
            label: 'भ्रमण गर्नुहोस् (Schedule Visit)',
            icon: Icons.calendar_today_outlined,
            color: AppTheme.brandColor,
            onPressed: _isSubmitting ? null : _submit,
            isLoading: _isSubmitting,
          ),
          const SizedBox(height: 12),
          _largeButton(
            label: 'घरधनीसँग कुरा गर्नुहोस् (Chat with Owner)',
            svgIcon: 'assets/icons/message.svg',
            color: AppTheme.brandColor,
            isOutlined: true,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => chat_page.ChatScreen(
                    ownerId: widget.property.ownerId,
                    name: widget.property.ownerName,
                    avatar: widget.property.ownerAvatar,
                    online: true,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'भ्रमण गर्नु अघि सम्पूर्ण विवरण पुष्टि गर्नुहोस्',
                style: GoogleFonts.mukta(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
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
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.white : color,
          borderRadius: BorderRadius.circular(30),
          border: isOutlined ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Row(
          children: [
            if (svgIcon != null)
              SvgPicture.asset(svgIcon, width: 20, height: 20, colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn))
            else if (icon != null)
              Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.mukta(
                  color: isOutlined ? color : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            if (isLoading)
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: iconColor, strokeWidth: 2))
            else
              Icon(Icons.chevron_right, color: iconColor, size: 20),
          ],
        ),
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)}, ${date.year}';
  }

  String _getMonthName(int month) {
    return ['जनवरी', 'फेब्रुअरी', 'मार्च', 'अप्रिल', 'मे (May)', 'जुन', 'जुलाई', 'अगस्ट', 'सेप्टेम्बर', 'अक्टोबर', 'नोभेम्बर', 'डिसेम्बर'][month - 1];
  }

  String _getDayName(DateTime date) {
    const days = ['आइतबार', 'सोमबार', 'मंगलबार', 'बुधबार', 'बिहीबार', 'शुक्रबार', 'शनिबार'];
    return days[date.weekday % 7];
  }

  Future<void> _selectVisitDate() async {
    final DateTime? picked = await showDatePicker(
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
    if (picked != null) setState(() => _visitDate = picked);
  }

  void _showVisitingPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('आउने संख्या चयन गर्नुहोस्', style: GoogleFonts.mukta(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [1, 2, 3, 4, 5].map((n) => InkWell(
                onTap: () {
                  setState(() => _visitingCount = n);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _visitingCount == n ? AppTheme.brandColor : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Text('$n', style: TextStyle(color: _visitingCount == n ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                ),
              )).toList(),
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
      await BookingRepository.createBookingRequest(
        propertyId: widget.property.id,
        ownerId: widget.property.ownerId,
        checkIn: _visitDate,
        checkOut: _visitDate.add(const Duration(days: 30)), 
        totalPrice: double.tryParse(widget.property.price.replaceAll(',', '')) ?? 0, 
        message: 'Visit request for ${widget.property.title} by $_visitingCount person(s)',
      );
      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
