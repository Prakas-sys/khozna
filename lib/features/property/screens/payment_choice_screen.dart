import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/models/booking_model.dart';
import 'package:khozna/features/property/repositories/booking_repository.dart';
import 'package:khozna/core/utils/formatters.dart';
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
  bool _isLoadingOwner = true;
  UserModel? _ownerProfile;

  @override
  void initState() {
    super.initState();
    _loadOwnerPaymentDetails();
  }

  Future<void> _loadOwnerPaymentDetails() async {
    try {
      final profile = await SupabaseService.getUserProfile(widget.booking.ownerId);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'भुक्तानी विधि (Payment Method)',
          style: GoogleFonts.mukta(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 18),
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
              title: 'Deal directly with owner',
              nepaliTitle: 'घरधनीसँग सिधै कुरा गर्छु',
              description: 'Use eSewa or Khalti and pay after agreement.',
              nepaliDescription: 'ई-सेवा वा खल्ती प्रयोग गर्नुहोस् र सम्झौता पछि भुक्तानी गर्नुहोस्।',
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
              nepaliTitle: 'खोज्ना सुरक्षित भुक्तानी',
              description: 'We hold your payment safely until you move in.',
              nepaliDescription: 'हामी तपाईंको पैसा सुरक्षित राख्छौं। तपाईं सरेपछि मात्र पैसा रिलिज हुन्छ।',
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF00A3E1).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00A3E1).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_rounded, color: Color(0xFF00A3E1), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'KHOZNA Safe Payment ensures your money is secure until you move in.',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
                  '⚠️ पैसा तिर्नु अघि कृपया कोठामा गएर हेर्नुहोस्। (Visit before payment)\nKHOZNA cannot guarantee safety for payments made outside the platform.',
                  style: GoogleFonts.mukta(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.amber.shade900, height: 1.2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required IconData icon,
    required String title,
    required String nepaliTitle,
    required String description,
    required String nepaliDescription,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          nepaliTitle,
                          style: GoogleFonts.mukta(fontWeight: FontWeight.w800, fontSize: 15, height: 1.1),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                        child: Text(badge, style: GoogleFonts.plusJakartaSans(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.blue.shade700)),
                      ),
                    ],
                  ),
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nepaliDescription,
                    style: GoogleFonts.mukta(fontSize: 12, color: Colors.grey[700], height: 1.2),
                  ),
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
              Text('भुक्तानी गर्ने तरिका (How to pay):', style: GoogleFonts.mukta(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              _instructionItem('१', 'घरधनीसँग कुरा गर्नुहोस् र भाडा तय गर्नुहोस्। (Talk to owner)'),
              _instructionItem('२', 'ई-सेवा वा खल्तीबाट सिधै घरधनीलाई पैसा पठाउनुहोस्। (Pay directly)'),
              _instructionItem('३', 'पैसा पठाएको स्क्रिनसट लिनुहोस्। (Take screenshot)'),
              _instructionItem('४', 'पुष्टि गर्नको लागि तल प्रमाण अपलोड गर्नुहोस्। (Upload proof)'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('प्रमाण अपलोड गर्नुहोस् (Upload Proof)', style: GoogleFonts.mukta(fontWeight: FontWeight.bold, fontSize: 16)),
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
              Text('स्क्रिनसट अपलोड गर्नुहोस् (Upload Screenshot)', style: GoogleFonts.mukta(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingOwner)
          const Center(child: CircularProgressIndicator())
        else if (_ownerProfile != null)
          _buildOwnerPaymentInfo()
        else
          Text('Error loading payment details. Please chat with owner.', style: GoogleFonts.inter(color: Colors.red, fontSize: 12)),
        
        const SizedBox(height: 24),
        TextField(
          controller: _transactionController,
          decoration: InputDecoration(
            hintText: 'कारोबार आईडी (Transaction ID) हाल्नुहोस्',
            labelText: 'Transaction ID',
            labelStyle: GoogleFonts.inter(fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.numbers_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerPaymentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_circle_outlined, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text('Account Holder:', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Text(_ownerProfile?.accountHolderName ?? _ownerProfile?.fullName ?? 'Not provided', 
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)),
              
              const Divider(height: 24),
              
              if (_ownerProfile?.esewaNumber != null && _ownerProfile!.esewaNumber!.isNotEmpty) ...[
                _paymentDetailItem('eSewa Number', _ownerProfile!.esewaNumber!, Colors.green),
                const SizedBox(height: 12),
              ],
              
              if (_ownerProfile?.khaltiNumber != null && _ownerProfile!.khaltiNumber!.isNotEmpty) ...[
                _paymentDetailItem('Khalti Number', _ownerProfile!.khaltiNumber!, Colors.purple),
                const SizedBox(height: 12),
              ],

              if (_ownerProfile?.qrCodeUrl != null && _ownerProfile!.qrCodeUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Scan QR Code:', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(_ownerProfile!.qrCodeUrl!, width: 150, height: 150, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('⚠️ Send payment only after agreement with owner.', 
                        style: GoogleFonts.mukta(fontSize: 12, color: Colors.red.shade900, fontWeight: FontWeight.bold)),
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

  Widget _paymentDetailItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
            Text(value, style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 20, color: Colors.grey),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied!')));
          },
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
            'Benefits of Safe Payment:',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 12),
          _safePaymentBenefit(Icons.lock_clock_rounded, 'Money held safely until move-in'),
          _safePaymentBenefit(Icons.receipt_long_rounded, 'Official payment proof stored'),
          _safePaymentBenefit(Icons.support_agent_rounded, '24/7 Dispute support'),
          _safePaymentBenefit(Icons.trending_up_rounded, 'Boost your Tenant Trust Score'),
          const SizedBox(height: 16),
          Text(
            'Small 10% fee applies for these security benefits.',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.blue.shade800, fontStyle: FontStyle.italic),
          ),
          const Divider(height: 32),
          _row('Monthly Rent', 'Rs. ${PriceFormatter.format(widget.booking.totalPrice.toString())}'),
          _row('Khozna Service Fee (10%)', 'Rs. ${PriceFormatter.format((widget.booking.totalPrice * 0.1).toString())}'),
          const SizedBox(height: 12),
          _row('Total to Pay', 'Rs. ${PriceFormatter.format((widget.booking.totalPrice * 1.1).toString())}', isBold: true),
        ],
      ),
    );
  }

  Widget _safePaymentBenefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.brandColor),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E3A8A), fontWeight: FontWeight.w500))),
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
          Text('$num.', style: GoogleFonts.mukta(fontWeight: FontWeight.bold, color: AppTheme.brandColor, fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.mukta(fontSize: 14, color: Colors.black87))),
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
                _selectedType == 'direct' ? 'मैले पैसा तिरिसकें (I HAVE PAID)' : 'सुरक्षित भुक्तानी गर्नुहोस् (PAY SECURELY)',
                style: GoogleFonts.mukta(fontWeight: FontWeight.w800, fontSize: 16),
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
        amount: widget.booking.totalPrice,
        referenceId: _transactionController.text.trim(),
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
