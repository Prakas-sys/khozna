import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/models/booking_model.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';

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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Magical Background Orbs
          Positioned(
            top: -150,
            right: -100,
            child: _buildGlowOrb(AppTheme.brandColor.withOpacity(0.15), 300),
          ),
          Positioned(
            bottom: 200,
            left: -150,
            child: _buildGlowOrb(Colors.purple.withOpacity(0.05), 400),
          ),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                centerTitle: true,
                title: Text(
                  'भुक्तानी (Payment)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _isLoadingOwner 
                  ? const Center(child: Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: CircularProgressIndicator(color: AppTheme.brandColor),
                    ))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          
                          // Booking Details Header (Platinum Design)
                          _buildBookingHeader(kTextDark, kTextMid),

                          const SizedBox(height: 40),
                          
                          Text(
                            'भुक्तानीको माध्यम छान्नुहोस्',
                            style: GoogleFonts.mukta(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: kTextDark,
                            ),
                          ),
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
                            iconData: Icons.verified_user_rounded,
                            esewaNumber: '9800000000',
                            feeText: '१०% सेवा शुल्क (10% Fee)',
                            feeColor: AppTheme.brandColor,
                            isSelected: _selectedType == 'khozna',
                            onTap: () => setState(() => _selectedType = 'khozna'),
                          ),

                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
              ),
            ],
          ),
        ],
      ),
      bottomSheet: _buildBottomAction(),
    );
  }

  Widget _buildGlowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildBookingHeader(Color dark, Color mid) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.brandColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'बुकिङ विवरण (Booking Info)',
              style: GoogleFonts.mukta(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.brandColor,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.propertyTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: dark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 16, color: mid),
              const SizedBox(width: 10),
              Text(
                'जेठ १५ - १६ (रू ${NumberFormat('#,##,###').format(widget.booking.totalPrice)} - १ रात)',
                style: GoogleFonts.mukta(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: mid,
                ),
              ),
            ],
          ),
        ],
      ),
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
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? highlightColor : Colors.grey.shade100,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: highlightColor.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10))]
              : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: highlightColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: iconAsset != null
                      ? Image.asset(iconAsset, fit: BoxFit.contain)
                      : Icon(iconData, color: highlightColor, size: 30),
                ),
                const SizedBox(width: 14),
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
                          fontWeight: FontWeight.w700,
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
                      gradient: const LinearGradient(colors: [Color(0xFF00A3E1), Color(0xFF0077B6)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 20),
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
                        fontWeight: FontWeight.w700,
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, -10))
        ],
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
                  Text(
                    'कुल रकम (Total Amount)',
                    style: GoogleFonts.mukta(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    'Rs. ${NumberFormat('#,##,###').format(total)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _isSubmitting ? null : _proceedToPayment,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.brandColor, Color(0xFF0077B6)]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: AppTheme.brandColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          'भुक्तानी गर्नुहोस्',
                          style: GoogleFonts.mukta(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToPayment() async {
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();
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
