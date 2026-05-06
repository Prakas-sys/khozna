import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/models/booking_model.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:intl/intl.dart';

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
  String _selectedType = 'direct'; // 'direct' or 'khozna'
  final TextEditingController _transactionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'भुक्तानी विधि छनौट गर्नुहोस् (Choose how you want to pay)',
          style: GoogleFonts.mukta(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrustWarning(),
            const SizedBox(height: 32),
            
            Text(
              'Select an option after your visit:',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            // Option 1: Direct to Owner
            _buildPaymentOption(
              id: 'direct',
              icon: Icons.person_outline_rounded,
              title: 'Pay directly to owner',
              description: 'Use eSewa or Khalti and pay after agreement',
              badge: 'POPULAR',
              isSelected: _selectedType == 'direct',
              onTap: () => setState(() => _selectedType = 'direct'),
            ),

            const SizedBox(height: 16),

            // Option 2: Khozna Safe Payment
            _buildPaymentOption(
              id: 'khozna',
              icon: Icons.shield_outlined,
              title: 'KHOZNA Safe Payment',
              description: 'We hold your payment safely until you move in',
              badge: 'EXTRA SECURE',
              isSelected: _selectedType == 'khozna',
              onTap: () => setState(() => _selectedType = 'khozna'),
            ),

            const SizedBox(height: 32),

            if (_selectedType == 'direct') _buildDirectPaymentDetails(),
            if (_selectedType == 'khozna') _buildKhoznaPaymentDetails(),

            const SizedBox(height: 40),
            
            _buildActionButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '⚠️ Please visit the room before making any payment.',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required IconData icon,
    required String title,
    required String description,
    required String badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.brandColor : Colors.grey.shade200, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isSelected ? AppTheme.brandColor : Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(icon, color: isSelected ? Colors.white : Colors.grey[600], size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                        child: Text(badge, style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.blue.shade700)),
                      ),
                    ],
                  ),
                  Text(description, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded, color: isSelected ? AppTheme.brandColor : Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectPaymentDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How to pay:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              _instructionItem('1', 'Talk to owner and confirm monthly rent.'),
              _instructionItem('2', 'Pay via eSewa or Khalti to owner directly.'),
              _instructionItem('3', 'Take a screenshot of the payment.'),
              _instructionItem('4', 'Upload the proof below to confirm in Khozna.'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Upload Payment Proof', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_upload_outlined, color: Colors.grey, size: 32),
              const SizedBox(height: 8),
              Text('Upload Screenshot', style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _transactionController,
          decoration: InputDecoration(
            hintText: 'Enter Transaction ID',
            labelText: 'Transaction ID',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.numbers_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildKhoznaPaymentDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: AppTheme.brandColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your payment is held safely by Khozna.',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'We charge a small 10% fee for this security. If the deal fails, we process your refund within 24 hours.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.blue.shade800, height: 1.4),
          ),
          const Divider(height: 32),
          _row('Monthly Rent', 'Rs. ${NumberFormat('#,##,###').format(widget.booking.totalPrice)}'),
          _row('Khozna Service Fee (10%)', 'Rs. ${NumberFormat('#,##,###').format(widget.booking.totalPrice * 0.1)}'),
          const SizedBox(height: 12),
          _row('Total to Pay', 'Rs. ${NumberFormat('#,##,###').format(widget.booking.totalPrice * 1.1)}', isBold: true),
        ],
      ),
    );
  }

  Widget _instructionItem(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$num.', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.brandColor, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: isBold ? Colors.black : Colors.grey[700], fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: GoogleFonts.sora(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: isBold ? AppTheme.brandColor : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _proceed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.brandColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _selectedType == 'direct' ? 'I HAVE PAID' : 'PAY SECURELY',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
              ),
      ),
    );
  }

  Future<void> _proceed() async {
    setState(() => _isSubmitting = true);
    try {
      // In real app, this would handle the upload and status update
      await BookingRepository.submitPayment(
        bookingId: widget.booking.id, 
        paymentType: _selectedType, 
        method: _selectedType == 'direct' ? 'manual' : 'digital', 
        amount: widget.booking.totalPrice
      );
      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
