import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/models/booking_model.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentChoiceScreen extends StatefulWidget {
  final BookingModel booking;
  final String propertyTitle;

  const PaymentChoiceScreen({
    super.key,
    required this.booking,
    required this.propertyTitle,
  });

  @override
  State<PaymentChoiceScreen> createState() => _PaymentChoiceScreenState();
}

class _PaymentChoiceScreenState extends State<PaymentChoiceScreen> {
  String _selectedType = 'khozna';
  bool _isSubmitting = false;
  bool _isLoadingOwner = true;
  String? _ownerEsewa;
  String? _ownerQr;

  @override
  void initState() {
    super.initState();
    _loadOwnerInfo();
  }

  Future<void> _loadOwnerInfo() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('esewa_number, qr_code_url')
          .eq('id', widget.booking.ownerId)
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          _ownerEsewa = data?['esewa_number'];
          _ownerQr = data?['qr_code_url'];
          _isLoadingOwner = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingOwner = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color kTextDark = Color(0xFF1A1A2E);
    const Color kTextMid = Color(0xFF6B7280);
    const Color kSuccess = Color(0xFF22C55E);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'भुक्तानीको माध्यम (Payment)',
          style: GoogleFonts.mukta(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ),
      body: _isLoadingOwner 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.brandColor))
        : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Details Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.brandColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'बुकिङ विवरण',
                      style: GoogleFonts.mukta(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.brandColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.propertyTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: kTextDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: kTextMid),
                      const SizedBox(width: 8),
                      Text(
                        'जेठ १५ - १६ (रू ${NumberFormat('#,##,###').format(widget.booking.totalPrice)} - १ रात)',
                        style: GoogleFonts.mukta(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: kTextMid,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'भुक्तानीको माध्यम छान्नुहोस्',
                    style: GoogleFonts.mukta(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select how you want to pay',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kTextMid,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Option 1: Direct to Owner
                  _buildPaymentCard(
                    id: 'direct',
                    title: 'घरधनीलाई सिधै भुक्तानी',
                    subtitle: 'Pay Owner Direct',
                    highlightText: 'छिटो र सजिलो (Fast & Simple)',
                    highlightColor: kSuccess,
                    description: 'तपाईंले घरधनीलाई सिधै eSewa मार्फत रकम पठाउन सक्नुहुन्छ। यसको कुनै पनि जिम्मेवारी खोज्नुले लिने छैन।',
                    iconAsset: 'assets/images/esewa.webp',
                    esewaNumber: _ownerEsewa ?? 'उपलब्ध छैन',
                    feeText: '५% सेवा शुल्क (5% Fee)',
                    feeColor: kSuccess,
                    warningText: '⚠️ No protection',
                    isSelected: _selectedType == 'direct',
                    onTap: () => setState(() => _selectedType = 'direct'),
                  ),

                  const SizedBox(height: 16),

                  // Option 2: Pay via Khozna
                  _buildPaymentCard(
                    id: 'khozna',
                    title: 'खोज्न मार्फत भुक्तानी',
                    subtitle: 'Pay via Khozna',
                    badgeText: 'RECOMMENDED',
                    highlightText: 'सुरक्षित र भरपर्दो (Recommended)',
                    highlightColor: AppTheme.brandColor,
                    description: 'तपाईंको रकम खोज्नुसँग सुरक्षित रहनेछ। कुनै समस्या आएमा रकम फिर्ता (Refund) हुने सुनिश्चितता छ।',
                    iconData: Icons.check_circle_rounded,
                    esewaNumber: '9800000000',
                    feeText: '१०% सेवा शुल्क (10% Fee)',
                    feeColor: AppTheme.brandColor,
                    isSelected: _selectedType == 'khozna',
                    onTap: () => setState(() => _selectedType = 'khozna'),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(),
    );
  }

  Widget _buildPaymentCard({
    required String id,
    required String title,
    required String subtitle,
    String? badgeText,
    required String highlightText,
    required Color highlightColor,
    required String description,
    String? iconAsset,
    IconData? iconData,
    required String esewaNumber,
    required String feeText,
    required Color feeColor,
    String? warningText,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected ? highlightColor : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: highlightColor.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]
              : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: highlightColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: iconAsset != null
                      ? Image.asset(iconAsset, fit: BoxFit.contain)
                      : Icon(iconData, color: highlightColor, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.mukta(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              highlightText,
              style: GoogleFonts.mukta(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: highlightColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: GoogleFonts.mukta(
                fontSize: 13,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'eSewa Number:',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      esewaNumber,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      feeText,
                      style: GoogleFonts.mukta(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: feeColor,
                      ),
                    ),
                    if (warningText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        warningText,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    final feePercent = _selectedType == 'khozna' ? 0.10 : 0.05;
    final feeAmount = widget.booking.totalPrice * feePercent;
    final total = widget.booking.totalPrice + feeAmount;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('कुल रकम (Total Amount)', style: GoogleFonts.mukta(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(
                    'Rs. ${NumberFormat('#,##,###').format(total)}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _proceedToPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('भुक्तानी गर्नुहोस्', style: GoogleFonts.mukta(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToPayment() async {
    setState(() => _isSubmitting = true);
    try {
      await BookingRepository.submitPayment(
        bookingId: widget.booking.id,
        paymentType: _selectedType,
        method: 'esewa',
        amount: widget.booking.totalPrice,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Submitted! Waiting for verification.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
