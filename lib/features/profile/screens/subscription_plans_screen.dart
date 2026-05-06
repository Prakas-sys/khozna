import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'dart:ui';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  bool isAnnual = false;
  String selectedPlan = 'Premium';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Decorative Gradients
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.brandColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), child: Container()),
            ),
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
                  'Premium Subscription',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // 3D Visual or Logo
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: AppTheme.brandColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Image.asset(
                              'assets/images/tiny house.png',
                              height: 120,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'हाम्रो प्रीमियम योजना छान्नुहोस्',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Choose Your Premium Plan',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Toggle
                      _buildToggle(),

                      const SizedBox(height: 32),

                      // Plans
                      _buildPlanCard(
                        id: 'Basic',
                        title: 'BASIC PLAN',
                        price: isAnnual ? '४,५००' : '५००',
                        period: isAnnual ? 'year' : 'month',
                        features: ['Unlimited Property Search', 'Direct Contact with Owner', 'Standard Support'],
                        isSelected: selectedPlan == 'Basic',
                        onTap: () => setState(() => selectedPlan = 'Basic'),
                      ),
                      const SizedBox(height: 16),
                      _buildPlanCard(
                        id: 'Premium',
                        title: 'PREMIUM PLAN',
                        price: isAnnual ? '९,०००' : '९९९',
                        period: isAnnual ? 'year' : 'month',
                        features: ['Verified Badge on Profile', 'AI Powered AI-Search Access', 'Priority Support', 'Ad-free Experience'],
                        isSelected: selectedPlan == 'Premium',
                        isRecommended: true,
                        onTap: () => setState(() => selectedPlan = 'Premium'),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // CTA
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Upgrade Now',
                            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isAnnual = false),
              child: Container(
                decoration: BoxDecoration(
                  color: !isAnnual ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: !isAnnual ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Monthly',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: !isAnnual ? Colors.black : Colors.grey),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isAnnual = true),
              child: Container(
                decoration: BoxDecoration(
                  color: isAnnual ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: isAnnual ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Annually',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: isAnnual ? Colors.black : Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String id,
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required bool isSelected,
    bool isRecommended = false,
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
            color: isSelected ? AppTheme.brandColor : Colors.grey.shade200,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.brandColor.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10))]
              : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: isSelected ? AppTheme.brandColor : Colors.grey, letterSpacing: 1.2),
                ),
                if (isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.brandColor, borderRadius: BorderRadius.circular(20)),
                    child: Text('RECOMMENDED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'रू $price',
                  style: GoogleFonts.plusJakartaSans(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.black),
                ),
                const SizedBox(width: 4),
                Text(
                  '/$period',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[400]),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: isSelected ? AppTheme.brandColor : Colors.grey[300]),
                  const SizedBox(width: 10),
                  Expanded(child: Text(f, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
