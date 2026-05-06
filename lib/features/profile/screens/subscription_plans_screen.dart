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
          // Background Gradient Orbs for "Magical" feel
          Positioned(
            top: -150,
            left: -100,
            child: _buildGlowOrb(AppTheme.brandColor.withOpacity(0.2), 300),
          ),
          Positioned(
            top: 200,
            right: -150,
            child: _buildGlowOrb(Colors.purple.withOpacity(0.1), 400),
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
                actions: [
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded, color: Colors.black),
                    onPressed: () {},
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        'Khozna Premium',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -1.0,
                        ),
                      ),
                      Text(
                        'Upgrade for verified badges & boost',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Magical Balance Card
                      _buildBalanceCard(),

                      const SizedBox(height: 32),
                      
                      // Toggle
                      _buildToggle(),

                      const SizedBox(height: 24),

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
                        height: 64,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [AppTheme.brandColor, Color(0xFF0077B6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.brandColor.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => HapticFeedback.mediumImpact(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text(
                              'Upgrade to ${selectedPlan.toUpperCase()}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
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

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.9), Colors.black.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR BALANCE',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 1.5,
                ),
              ),
              const Icon(Icons.wallet_rounded, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'रू १,२५०.००',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildBalanceAction(Icons.add_rounded, 'Add Money'),
              const SizedBox(width: 12),
              _buildBalanceAction(Icons.history_rounded, 'History'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceAction(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildToggleItem(false, 'Monthly'),
          _buildToggleItem(true, 'Annually (Save 20%)'),
        ],
      ),
    );
  }

  Widget _buildToggleItem(bool value, String label) {
    final isSelected = isAnnual == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isAnnual = value),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.black : Colors.grey[500],
            ),
          ),
        ),
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
            color: isSelected ? AppTheme.brandColor : Colors.grey.shade100,
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
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? AppTheme.brandColor : Colors.grey[400],
                    letterSpacing: 1.5,
                  ),
                ),
                if (isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFB703), Color(0xFFFB8500)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'RECOMMENDED',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
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
                  style: GoogleFonts.plusJakartaSans(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.black),
                ),
                const SizedBox(width: 4),
                Text(
                  '/$period',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[400]),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.brandColor.withOpacity(0.1) : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded, size: 14, color: isSelected ? AppTheme.brandColor : Colors.grey[400]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      f,
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
