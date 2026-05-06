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
  String _selectedType = 'khozna'; // 'direct' or 'khozna'
  String _selectedGateway = 'esewa'; // 'esewa', 'khalti', 'bank', 'card'
  bool _isSubmitting = false;
  bool _isLoadingOwner = true;
  String? _ownerEsewa;

  @override
  void initState() {
    super.initState();
    _loadOwnerInfo();
  }

  Future<void> _loadOwnerInfo() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('esewa_number')
          .eq('id', widget.booking.ownerId)
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          _ownerEsewa = data?['esewa_number'];
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
      backgroundColor: const Color(0xFFFBFBFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Payment Details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 14),
                const SizedBox(width: 4),
                Text(
                  'Secure & Trusted',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoadingOwner 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.brandColor))
        : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How would you like to pay?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.propertyTitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // Card 1: Direct Payment (0% Fee)
              _buildModernPlanCard(
                id: 'direct',
                icon: Icons.account_balance_wallet_outlined,
                iconColor: const Color(0xFF22C55E),
                title: 'Pay owner directly',
                badgeText: 'NO FEE',
                badgeColor: const Color(0xFFF0FDF4),
                badgeTextColor: const Color(0xFF16A34A),
                subtitle: 'Pay the owner directly (Recommended if you know them)',
                priceText: '0% Fee',
                features: [
                  'You pay the owner directly',
                  'No extra charges from Khozna',
                ],
                warningText: 'No protection\nYou won\'t be covered by Khozna Protection.',
                isSelected: _selectedType == 'direct',
                onTap: () => setState(() => _selectedType = 'direct'),
              ),

              const SizedBox(height: 16),

              // Card 2: Khozna Protection (10% Fee)
              _buildModernPlanCard(
                id: 'khozna',
                icon: Icons.shield_outlined,
                iconColor: AppTheme.brandColor,
                title: 'Pay with Khozna Protection',
                badgeText: 'RECOMMENDED',
                badgeColor: const Color(0xFFEFF6FF),
                badgeTextColor: AppTheme.brandColor,
                subtitle: 'We hold your payment securely until you\'re satisfied.',
                priceText: '10% Fee',
                features: [
                  '100% Payment protection',
                  'Refund if something goes wrong',
                  'Khozna support when you need it',
                ],
                isSelected: _selectedType == 'khozna',
                isPremium: true,
                onTap: () => setState(() => _selectedType = 'khozna'),
              ),

              const SizedBox(height: 32),
              
              Text(
                'Choose your payment method',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              // Payment Gateway Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildModernGateway('esewa', 'assets/images/esewa.webp', 'eSewa', badge: 'RECOMMENDED'),
                  _buildModernGateway('khalti', 'assets/images/khalti.png', 'Khalti'),
                  _buildModernGateway('bank', null, 'Bank Transfer', icon: Icons.account_balance_rounded),
                  _buildModernGateway('card', null, 'Cards', icon: Icons.credit_card_rounded, isSoon: true),
                ],
              ),

              const SizedBox(height: 32),
              
              // Security Info Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: Color(0xFF16A34A), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your security is our priority',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                          Text(
                            'We never store your card or bank details. All payments are 100% secure.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF16A34A).withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF16A34A), size: 14),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              // Total Section
              _buildModernTotalSection(),

              const SizedBox(height: 24),

              // Main Action Button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _proceedToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          'भुक्तानी गर्नुहोस् (Pay Now)',
                          style: GoogleFonts.mukta(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernPlanCard({
    required String id,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String subtitle,
    required String priceText,
    required List<String> features,
    String? warningText,
    required bool isSelected,
    bool isPremium = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? (isPremium ? AppTheme.brandColor : const Color(0xFF22C55E)) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: (isPremium ? AppTheme.brandColor : const Color(0xFF22C55E)).withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ] : null,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badgeText,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: badgeTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          priceText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: isPremium ? AppTheme.brandColor : const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, color: isPremium ? AppTheme.brandColor : const Color(0xFF22C55E), size: 24)
                  else
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                    ),
                ],
              ),
            ),
            
            // Features Row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(Icons.check_rounded, color: isPremium ? AppTheme.brandColor : const Color(0xFF16A34A), size: 14),
                            const SizedBox(width: 8),
                            Expanded(child: Text(f, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600))),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                  if (warningText != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_rounded, color: Color(0xFFEA580C), size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(warningText, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFFEA580C), fontWeight: FontWeight.w700))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernGateway(String id, String? asset, String label, {IconData? icon, bool isSoon = false, String? badge}) {
    final isSelected = _selectedGateway == id;
    return GestureDetector(
      onTap: isSoon ? null : () => setState(() => _selectedGateway = id),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.brandColor : Colors.grey.shade100,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: asset != null
                      ? Image.asset(asset, width: 24, height: 24, fit: BoxFit.contain)
                      : Icon(icon, color: Colors.grey[400], size: 22),
                ),
                if (isSoon)
                  Positioned(
                    bottom: 4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('SOON', style: GoogleFonts.plusJakartaSans(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.grey.shade500)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.black : Colors.grey[500],
            ),
          ),
          if (badge != null)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(badge, style: GoogleFonts.plusJakartaSans(fontSize: 7, fontWeight: FontWeight.w900, color: const Color(0xFF16A34A))),
            ),
        ],
      ),
    );
  }

  Widget _buildModernTotalSection() {
    final feePercent = _selectedType == 'khozna' ? 0.10 : 0.0;
    final feeAmount = widget.booking.totalPrice * feePercent;
    final total = widget.booking.totalPrice + feeAmount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _totalRow('Property Price', 'Rs. ${NumberFormat('#,##,###').format(widget.booking.totalPrice)}'),
          const SizedBox(height: 12),
          _totalRow('Service Fee (${_selectedType == 'khozna' ? '10%' : '0%'})', 'Rs. ${NumberFormat('#,##,###').format(feeAmount)}', isDiscount: _selectedType == 'direct'),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              Text(
                'Rs. ${NumberFormat('#,##,###').format(total)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.brandColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDiscount ? const Color(0xFF16A34A) : Colors.black,
          ),
        ),
      ],
    );
  }

  Future<void> _proceedToPayment() async {
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();
    try {
      await BookingRepository.submitPayment(
        bookingId: widget.booking.id,
        paymentType: _selectedType,
        method: _selectedGateway,
        amount: widget.booking.totalPrice,
      );

      if (mounted) {
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
