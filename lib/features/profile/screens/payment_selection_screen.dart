import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';

class PaymentSelectionScreen extends StatefulWidget {
  const PaymentSelectionScreen({super.key});

  @override
  State<PaymentSelectionScreen> createState() => _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState extends State<PaymentSelectionScreen> {
  bool isAnnual = false;
  String selectedPlan = 'Premium';
  String selectedPayment = 'esewa';

  @override
  Widget build(BuildContext context) {
    const Color kPrimary = Color(0xFF00A3E1);
    const Color kTextDark = Color(0xFF1A1A2E);
    const Color kTextMid = Color(0xFF6B7280);
    const Color kSuccess = Color(0xFF00C853);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'सदस्यता छान्नुहोस् (Pick Your Plan)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              'Pick Your Right Plan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: kTextDark,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 24),

            // Toggle Monthly/Annually
            Container(
              height: 50,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => isAnnual = false);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: !isAnnual ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: !isAnnual
                              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Monthly',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: !isAnnual ? FontWeight.w700 : FontWeight.w500,
                            color: !isAnnual ? Colors.black : kTextMid,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => isAnnual = true);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isAnnual ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: isAnnual
                              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Annually',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: isAnnual ? FontWeight.w700 : FontWeight.w500,
                            color: isAnnual ? Colors.black : kTextMid,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Plan Cards
            _buildPlanCard(
              title: 'BASIC PLAN',
              price: isAnnual ? '४,५००' : '५००',
              period: isAnnual ? 'yr' : 'mo',
              features: 'सजिलो कोठा खोज्न र बुक गर्न।',
              isSelected: selectedPlan == 'Basic',
              onTap: () => setState(() => selectedPlan = 'Basic'),
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              title: 'PREMIUM PLAN',
              price: isAnnual ? '९,०००' : '९९९',
              period: isAnnual ? 'yr' : 'mo',
              features: 'Verified Listings & AI Search access.',
              isSelected: selectedPlan == 'Premium',
              isBestValue: true,
              onTap: () => setState(() => selectedPlan = 'Premium'),
            ),

            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose Your Payment Method',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kTextDark,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment Methods Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPaymentOption('esewa', 'eSewa', 'assets/images/esewa.webp'),
                _buildPaymentOption('khalti', 'Khalti', 'assets/images/khalti by image.png'),
                _buildPaymentOption('bank', 'Bank', null, icon: Icons.account_balance_rounded),
                _buildPaymentOption('card', 'Card', null, icon: Icons.credit_card_rounded),
              ],
            ),

            const SizedBox(height: 40),
            
            // CTA Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  // Handle subscription
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED), // Purple like in the image, or kPrimary
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Try For Free',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFooterLink('Privacy Policy'),
                const SizedBox(width: 12),
                Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                _buildFooterLink('Terms & Conditions'),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required String features,
    required bool isSelected,
    bool isBestValue = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? const Color(0xFF7C3AED) : Colors.grey.shade200,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF6B7280),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'रू $price',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'NPR/$period',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                      ),
                    ),
                    if (isSelected) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Color(0xFF7C3AED), shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  features,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isSelected ? 'Selected' : (title.contains('BASIC') ? 'Try For Free' : 'Learn More'),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
          ),
          if (isBestValue)
            Positioned(
              top: -12,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Text(
                  'Best Value!',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String id, String label, String? asset, {IconData? icon}) {
    bool isSelected = selectedPayment == id;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => selectedPayment = id);
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xFF7C3AED) : Colors.grey.shade100,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: asset != null
                ? Image.asset(asset, fit: BoxFit.contain)
                : Icon(icon, color: Colors.grey[700], size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.black : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        color: Colors.grey[500],
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
