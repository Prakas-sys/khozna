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
  String _selectedGateway = 'esewa'; 
  bool _isSubmitting = false;
  bool _isLoadingOwner = true;

  @override
  void initState() {
    super.initState();
    _loadOwnerInfo();
  }

  Future<void> _loadOwnerInfo() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _isLoadingOwner = false);
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Choose payment method',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose the option that works best for you.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // CARD 1: Pay owner directly
              _buildPlanCard(
                id: 'direct',
                icon: Icons.account_balance_wallet_outlined,
                iconBg: const Color(0xFFF0FDF4),
                iconColor: const Color(0xFF16A34A),
                title: 'Pay owner directly',
                badgeText: 'NO FEE',
                badgeBg: const Color(0xFFF0FDF4),
                badgeColor: const Color(0xFF16A34A),
                subtitle: 'Pay the owner directly (Recommended if you know them)',
                feeText: '0% Fee',
                feeColor: const Color(0xFF16A34A),
                features: ['You pay the owner directly', 'No extra charges from Khozna'],
                warning: 'No protection\nYou won\'t be covered by Khozna Protection.',
                footer: 'Why no fee?  We don\'t charge any fee when you pay directly to the owner.',
                isSelected: _selectedType == 'direct',
                onTap: () => setState(() => _selectedType = 'direct'),
              ),

              const SizedBox(height: 16),

              // CARD 2: Khozna Protection
              _buildPlanCard(
                id: 'khozna',
                icon: Icons.shield_outlined,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: AppTheme.brandColor,
                title: 'Pay with Khozna Protection',
                badgeText: 'RECOMMENDED',
                badgeBg: const Color(0xFFEFF6FF),
                badgeColor: AppTheme.brandColor,
                subtitle: 'We hold your payment securely until you\'re satisfied.',
                feeText: '10% Fee',
                feeColor: AppTheme.brandColor,
                featuresRow: [
                  {'icon': Icons.verified_user_outlined, 'text': '100% Payment\nprotection'},
                  {'icon': Icons.history_rounded, 'text': 'Refund if\nsomething goes wrong'},
                  {'icon': Icons.headset_mic_outlined, 'text': 'Khozna support\nwhen you need it'},
                ],
                footer: 'Learn more about Khozna Protection',
                isSelected: _selectedType == 'khozna',
                isRecommended: true,
                onTap: () => setState(() => _selectedType = 'khozna'),
              ),

              const SizedBox(height: 32),
              
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGateway('esewa', 'assets/images/esewa.webp', 'eSewa'),
                  _buildGateway('khalti', 'assets/images/khalti.png', 'Khalti'),
                  _buildGateway('bank', null, 'Bank Transfer', icon: Icons.account_balance_rounded),
                  _buildGateway('card', null, 'Cards', icon: Icons.credit_card_rounded, isSoon: true),
                ],
              ),

              const SizedBox(height: 24),
              
              // Security Bar
              _buildSecurityBar(),

              const SizedBox(height: 24),
              _buildTotalSection(),

              const SizedBox(height: 24),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _proceedToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          'भुक्तानी गर्नुहोस् (Pay Now)',
                          style: GoogleFonts.mukta(fontSize: 17, fontWeight: FontWeight.w800),
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

  Widget _buildPlanCard({
    required String id,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
    required String subtitle,
    required String feeText,
    required Color feeColor,
    List<String>? features,
    List<Map<String, dynamic>>? featuresRow,
    String? warning,
    required String footer,
    required bool isSelected,
    bool isRecommended = false,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected ? (isRecommended ? AppTheme.brandColor : const Color(0xFF22C55E)) : Colors.grey.shade200;
    
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isSelected && isRecommended ? const Color(0xFFF0F7FF) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: isSelected ? 2.5 : 1),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                        child: Icon(icon, color: iconColor, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                            const SizedBox(height: 12),
                            Text(feeText, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900, color: feeColor)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded, 
                        color: isSelected ? (isRecommended ? AppTheme.brandColor : const Color(0xFF22C55E)) : Colors.grey[300], 
                        size: 22
                      ),
                    ],
                  ),
                ),
                
                // Features Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF9FAFB), border: Border(top: BorderSide(color: Colors.grey.shade100))),
                  child: Column(
                    children: [
                      if (features != null)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: features.map((f) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 14),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          f,
                                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (warning != null)
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.warning_rounded, color: Color(0xFFEA580C), size: 14),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(warning, style: GoogleFonts.plusJakartaSans(fontSize: 9, color: const Color(0xFFEA580C), fontWeight: FontWeight.w700))),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      if (featuresRow != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: featuresRow.map((f) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(f['icon'] as IconData, color: AppTheme.brandColor, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(f['text'] as String, style: GoogleFonts.plusJakartaSans(fontSize: 8, color: Colors.grey[600], fontWeight: FontWeight.w700, height: 1.2))),
                                ],
                              ),
                            ),
                          )).toList(),
                        ),
                    ],
                  ),
                ),
                
                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
                  child: Row(
                    children: [
                      Expanded(child: Text(footer, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500))),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (badgeText.isNotEmpty)
            Positioned(
              top: -10,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isRecommended ? AppTheme.brandColor : const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: (isRecommended ? AppTheme.brandColor : const Color(0xFF16A34A)).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGateway(String id, String? asset, String label, {IconData? icon, bool isSoon = false, String? badge}) {
    final isSelected = _selectedGateway == id;
    return GestureDetector(
      onTap: isSoon ? null : () => setState(() => _selectedGateway = id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isSelected ? AppTheme.brandColor : Colors.grey.shade100, width: isSelected ? 2 : 1),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Center(
              child: asset != null 
                  ? Image.asset(asset, width: 24, height: 24, fit: BoxFit.contain)
                  : Icon(icon, color: isSelected ? AppTheme.brandColor : Colors.grey[300], size: 24),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? Colors.black : Colors.grey[500])),
          if (isSoon)
            Text('SOON', style: GoogleFonts.plusJakartaSans(fontSize: 6, fontWeight: FontWeight.w900, color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildSecurityBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFDCFCE7))),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, color: Color(0xFF16A34A), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your security is our priority', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A))),
                Text('We never store your card or bank details.', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF16A34A).withOpacity(0.8))),
              ],
            ),
          ),
          Text('Learn more', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A))),
          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF16A34A), size: 10),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    final feePercent = _selectedType == 'khozna' ? 0.10 : 0.0;
    final total = widget.booking.totalPrice * (1 + feePercent);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _row('Property Price', 'Rs. ${NumberFormat('#,##,###').format(widget.booking.totalPrice)}'),
          const SizedBox(height: 10),
          _row('Service Fee (${_selectedType == 'khozna' ? '10%' : '0%'})', 'Rs. ${NumberFormat('#,##,###').format(widget.booking.totalPrice * feePercent)}'),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
              Text('Rs. ${NumberFormat('#,##,###').format(total)}', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.brandColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String v) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)), Text(v, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold))]);

  Future<void> _proceedToPayment() async {
    setState(() => _isSubmitting = true);
    try {
      await BookingRepository.submitPayment(bookingId: widget.booking.id, paymentType: _selectedType, method: _selectedGateway, amount: widget.booking.totalPrice);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
