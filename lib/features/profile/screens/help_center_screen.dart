import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:khozna/core/theme/app_theme.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  int? _expandedFaqIndex;

  final List<Map<String, dynamic>> _topicCategories = [
    {'name': 'Booking & Rent', 'icon': Icons.home_work_rounded, 'color': Color(0xFF2563EB)},
    {'name': 'KYC & Safety', 'icon': Icons.verified_user_rounded, 'color': Color(0xFF059669)},
    {'name': 'Payment', 'icon': Icons.account_balance_wallet_rounded, 'color': Color(0xFF7C3AED)},
    {'name': 'Tours & Reels', 'icon': Icons.play_circle_fill_rounded, 'color': Color(0xFFE11D48)},
  ];

  final List<Map<String, dynamic>> _faqs = [
    {
      'category': 'Booking & Rent',
      'question': 'How do I schedule a physical or virtual property tour?',
      'answer':
          'Navigate to any property listing and tap "Book a Tour". You can choose your preferred date and time slot. The owner will confirm your visit directly.',
    },
    {
      'category': 'Booking & Rent',
      'question': 'Are there any hidden broker fees on Khozna?',
      'answer':
          'No. Khozna connects tenants directly with verified owners. We do not charge hidden middleman commissions or broker fees.',
    },
    {
      'category': 'KYC & Safety',
      'question': 'Why is location & ID verification (KYC) required?',
      'answer':
          'To keep our community safe and scam-free, both owners and tenants complete identity verification. This ensures authentic listings and verified profiles.',
    },
    {
      'category': 'KYC & Safety',
      'question': 'How do I report a suspicious or misleading listing?',
      'answer':
          'Tap the "Report" option on the property page or message our team directly on WhatsApp. We review reports within 1 hour.',
    },
    {
      'category': 'Payment',
      'question': 'How is rental payment handled on Khozna?',
      'answer':
          'Rent payments are made directly between tenant and owner via eSewa, Khalti, or direct bank transfer. Always request a digital receipt inside the app chat.',
    },
    {
      'category': 'Payment',
      'question': 'What is the standard advance deposit policy?',
      'answer':
          'In Nepal, owners typically ask for 1 month advance rent as security deposit. Ensure you confirm terms via Khozna chat before sending funds.',
    },
    {
      'category': 'Tours & Reels',
      'question': 'How do Video Reels work for properties?',
      'answer':
          'Khozna Reels provide room and flat video tours before you visit. Swipe through the Tours tab to inspect properties authentically.',
    },
  ];

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $url')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqs.where((faq) {
      final matchesCategory =
          _selectedCategory == 'All' || faq['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          faq['question']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                  _expandedFaqIndex = null;
                });
              },
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Search Help & FAQs...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.black45, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.clear_rounded, size: 16, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Topic Wrap Pills (Zero overflow on any device)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCategoryPill('All', Icons.grid_view_rounded, Colors.black),
                ..._topicCategories.map((cat) {
                  final String name = cat['name'] as String;
                  final IconData icon = cat['icon'] as IconData;
                  final Color color = cat['color'] as Color;
                  return _buildCategoryPill(name, icon, color);
                }),
              ],
            ),

            const SizedBox(height: 24),

            // FAQ Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategory == 'All' ? 'Popular Questions' : '$_selectedCategory FAQs',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.3,
                  ),
                ),
                if (_selectedCategory != 'All' || _searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = 'All';
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    child: Text(
                      'Clear Filter',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.brandColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // FAQ Accordion List
            if (filteredFaqs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 36, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      Text(
                        'No questions found',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredFaqs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final faq = filteredFaqs[index];
                  final isExpanded = _expandedFaqIndex == index;

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _expandedFaqIndex = isExpanded ? null : index;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    faq['question']!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: Colors.grey[500],
                                  size: 20,
                                ),
                              ],
                            ),
                            if (isExpanded) ...[
                              const SizedBox(height: 12),
                              Text(
                                faq['answer']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 32),

            // Full-Width Direct Contact Cards (Zero Overflow)
            Text(
              'Still need help?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Reach out to our support team directly.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 14),

            // WhatsApp Support Tile
            _buildContactTile(
              label: 'Chat on WhatsApp',
              subtitle: '+977 9705278379',
              icon: FontAwesomeIcons.whatsapp,
              color: const Color(0xFF25D366),
              onTap: () => _launchUrl('https://wa.me/9779705278379'),
            ),
            const SizedBox(height: 8),

            // Phone Line Tile
            _buildContactTile(
              label: 'Call Direct Line',
              subtitle: '+977 9705278379',
              icon: Icons.phone_in_talk_rounded,
              color: const Color(0xFF2563EB),
              onTap: () => _launchUrl('tel:+9779705278379'),
            ),
            const SizedBox(height: 8),

            // Email Tile
            _buildContactTile(
              label: 'Email Support',
              subtitle: 'khoznaapp@gmail.com',
              icon: Icons.mark_email_read_rounded,
              color: const Color(0xFF7C3AED),
              onTap: () => _launchUrl('mailto:khoznaapp@gmail.com'),
            ),

            const SizedBox(height: 28),

            // Official Social Channels (Real Brand Icons)
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSocialPill(
                    label: 'Facebook',
                    icon: FontAwesomeIcons.facebook,
                    color: const Color(0xFF1877F2),
                    url: 'https://www.facebook.com/profile.php?id=61587497082072',
                  ),
                  _buildSocialPill(
                    label: 'Instagram',
                    icon: FontAwesomeIcons.instagram,
                    color: const Color(0xFFE4405F),
                    url: 'https://www.instagram.com/khozna.np/',
                  ),
                  _buildSocialPill(
                    label: 'TikTok',
                    icon: FontAwesomeIcons.tiktok,
                    color: Colors.black,
                    url: 'https://www.tiktok.com/@khozna.np',
                  ),
                  _buildSocialPill(
                    label: 'LinkedIn',
                    icon: FontAwesomeIcons.linkedin,
                    color: const Color(0xFF0A66C2),
                    url: 'https://www.linkedin.com/company/110343039/',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Minimal Footer
            Center(
              child: Text(
                'Khozna Nepal • v1.0.0',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[400],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String name, IconData icon, Color color) {
    final bool isSelected = _selectedCategory == name;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedCategory = name;
          _expandedFaqIndex = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: color, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialPill({
    required String label,
    required IconData icon,
    required Color color,
    required String url,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _launchUrl(url);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
