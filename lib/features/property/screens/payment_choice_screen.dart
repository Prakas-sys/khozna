import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/models/booking_model.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:flutter/services.dart';

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
  String? _selectedType;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payment Method',
          style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose how you want to pay for',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
            ),
            Text(
              widget.propertyTitle,
              style: GoogleFonts.sora(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _buildChoiceCard(
              id: 'khozna',
              title: 'Khozna Protection',
              subtitle: 'Secure escrow payment',
              description: 'Money is held by Khozna and released 24h after check-in. Full refund if owner scams.',
              fee: '10% Service Fee',
              icon: Icons.verified_user_rounded,
              color: const Color(0xFF2ECC71),
              isRecommended: true,
            ),
            const SizedBox(height: 20),
            _buildChoiceCard(
              id: 'direct',
              title: 'Direct to Owner',
              subtitle: 'Pay owner directly',
              description: 'You pay the owner via eSewa/Cash. Khozna only tracks the booking. No refund protection.',
              fee: '5% Service Fee',
              icon: Icons.account_balance_wallet_rounded,
              color: Colors.white24,
              isRecommended: false,
            ),
            const SizedBox(height: 40),
            if (_selectedType != null) ...[
              _buildSummary(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String id,
    required String title,
    required String subtitle,
    required String description,
    required String fee,
    required IconData icon,
    required Color color,
    bool isRecommended = false,
  }) {
    final isSelected = _selectedType == id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _selectedType = id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'RECOMMENDED',
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.sora(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, height: 1.4),
            ),
            const Divider(color: Colors.white10, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Service Fee',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  fee,
                  style: GoogleFonts.sora(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final feePercent = _selectedType == 'khozna' ? 0.10 : 0.05;
    final feeAmount = widget.booking.totalPrice * feePercent;
    final total = widget.booking.totalPrice + (_selectedType == 'khozna' ? feeAmount : 0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Property Rent', 'Rs. ${widget.booking.totalPrice}'),
          const SizedBox(height: 12),
          _buildSummaryRow(
            _selectedType == 'khozna' ? 'Khozna Protection Fee' : 'Direct Booking Fee',
            'Rs. ${feeAmount.toStringAsFixed(0)}',
            isFee: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10),
          ),
          _buildSummaryRow(
            'Total Amount',
            'Rs. ${total.toStringAsFixed(0)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isFee = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: isTotal ? Colors.white : Colors.white60,
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.sora(
            color: isFee ? const Color(0xFFE63946) : Colors.white,
            fontSize: isTotal ? 20 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _proceedToPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2ECC71),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.black)
            : Text(
                'PROCEED TO PAYMENT',
                style: GoogleFonts.sora(fontWeight: FontWeight.w900, fontSize: 16),
              ),
      ),
    );
  }

  Future<void> _proceedToPayment() async {
    setState(() => _isSubmitting = true);
    try {
      // In a real app, this would open eSewa SDK or a screen to upload proof
      // For now, we update the booking status to 'paid' and create a payment record
      
      await BookingRepository.submitPayment(
        bookingId: widget.booking.id,
        paymentType: _selectedType!,
        method: 'esewa',
        amount: widget.booking.totalPrice,
      );

      if (mounted) {
        // Show success and pop
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
