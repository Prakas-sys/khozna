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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black),
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
      ),
      body: _isLoadingOwner 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.brandColor))
        : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                'Choose Your Payment',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),

              // Card 1: Direct Payment
              _buildFlatPlanCard(
                id: 'direct',
                title: 'DIRECT PAYMENT',
                price: '5% FEE',
                subtitle: 'घरधनीलाई सिधै भुक्तानी',
                description: 'छिटो र सजिलो। यस कारोबारको जिम्मेवारी खोज्नले लिने छैन।',
                isSelected: _selectedType == 'direct',
                onTap: () => setState(() => _selectedType = 'direct'),
              ),

              const SizedBox(height: 16),

              // Card 2: Khozna Protection
              _buildFlatPlanCard(
                id: 'khozna',
                title: 'KHOZNA PROTECTION',
                price: '10% FEE',
                subtitle: 'खोज्न सुरक्षित भुक्तानी',
                description: 'खोज्नमा तपाईंको रकम सुरक्षित रहन्छ। बुकिङ रद्द भएमा तुरुन्त फिर्ता हुनेछ।',
                isSelected: _selectedType == 'khozna',
                isRecommended: true,
                onTap: () => setState(() => _selectedType = 'khozna'),
              ),

              const SizedBox(height: 32),
              
              Text(
                'Choose Your Payment Method',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              // Payment Gateway Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGatewayIcon('esewa', 'assets/images/esewa.webp', 'eSewa'),
                  _buildGatewayIcon('khalti', 'assets/images/khalti.png', 'Khalti'),
                  _buildGatewayIcon('bank', null, 'Bank', icon: Icons.account_balance_rounded),
                  _buildGatewayIcon('card', null, 'Card', icon: Icons.credit_card_outlined, isComingSoon: true),
                ],
              ),

              const SizedBox(height: 40),
              
              // Total Section
              _buildFlatTotalSection(),

              const SizedBox(height: 24),

              // Main Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _proceedToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          'भुक्तानी गर्नुहोस्',
                          style: GoogleFonts.mukta(
                            fontSize: 16,
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

  Widget _buildFlatPlanCard({
    required String id,
    required String title,
    required String price,
    required String subtitle,
    required String description,
    required bool isSelected,
    bool isRecommended = false,
    required VoidCallback onTap,
  }) {
    final Color activeColor = isSelected ? AppTheme.brandColor : Colors.grey.shade200;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activeColor,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppTheme.brandColor : Colors.grey[400],
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.mukta(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppTheme.brandColor : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.mukta(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            // Badges & Tick in the top right corner
            Positioned(
              top: -4,
              right: -4,
              child: Row(
                children: [
                  if (isRecommended)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'SAFE CHOICE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, color: AppTheme.brandColor, size: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGatewayIcon(String id, String? asset, String label, {IconData? icon, bool isComingSoon = false}) {
    final isSelected = _selectedGateway == id;
    return GestureDetector(
      onTap: isComingSoon ? null : () => setState(() => _selectedGateway = id),
      child: Opacity(
        opacity: isComingSoon ? 0.5 : 1.0,
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.brandColor.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppTheme.brandColor : Colors.grey.shade200,
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Center(
                child: asset != null
                    ? Image.asset(
                        asset,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.payment, color: Colors.grey[300]),
                      )
                    : Icon(icon, color: isSelected ? AppTheme.brandColor : Colors.grey[400], size: 28),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isComingSoon ? 'Soon' : label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppTheme.brandColor : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlatTotalSection() {
    final feePercent = _selectedType == 'khozna' ? 0.10 : 0.05;
    final feeAmount = widget.booking.totalPrice * feePercent;
    final total = widget.booking.totalPrice + feeAmount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total to Pay:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          Text(
            'Rs. ${NumberFormat('#,##,###', 'en_US').format(total)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
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
        method: _selectedGateway,
        amount: widget.booking.totalPrice,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Request Sent!')),
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
