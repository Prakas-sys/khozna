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
        title: Text(
          'Help Center',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Text(
              'How can we help?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 14),

            // Single Clean Search Input
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                    _expandedFaqIndex = null;
                  });
                },
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Search questions, keywords...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.black45, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Topic Categories Grid (Clean 2x2 Grid, No Double Containers)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemCount: _topicCategories.length,
              itemBuilder: (context, index) {
                final topic = _topicCategories[index];
                final String name = topic['name'] as String;
                final IconData icon = topic['icon'] as IconData;
                final Color color = topic['color'] as Color;
                final bool isSelected = _selectedCategory == name;

                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedCategory = isSelected ? 'All' : name;
                      _expandedFaqIndex = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.black : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: isSelected ? Colors.white : color,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // FAQ Section Title & Reset Filter Action
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
                      'Show All',
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
                padding: const EdgeInsets.symmetric(vertical: 32),
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

            const SizedBox(height: 36),

            // Still Need Help? Clean Human Contact Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    'Get in touch with Khozna team directly.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      // WhatsApp
                      Expanded(
                        child: _buildContactButton(
                          label: 'WhatsApp',
                          icon: FontAwesomeIcons.whatsapp,
                          bgColor: const Color(0xFF25D366),
                          textColor: Colors.white,
                          onTap: () => _launchUrl('https://wa.me/9779705278379'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Call
                      Expanded(
                        child: _buildContactButton(
                          label: 'Call Us',
                          icon: Icons.phone_rounded,
                          bgColor: Colors.black,
                          textColor: Colors.white,
                          onTap: () => _launchUrl('tel:+9779705278379'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Email
                      Expanded(
                        child: _buildContactButton(
                          label: 'Email',
                          icon: Icons.email_rounded,
                          bgColor: Colors.white,
                          textColor: Colors.black,
                          borderColor: const Color(0xFFE2E8F0),
                          onTap: () => _launchUrl('mailto:khoznaapp@gmail.com'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Minimal Social Links Row
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSocialTextLink('Facebook', 'https://www.facebook.com/profile.php?id=61587497082072'),
                  _buildDotDivider(),
                  _buildSocialTextLink('Instagram', 'https://www.instagram.com/khozna.np/'),
                  _buildDotDivider(),
                  _buildSocialTextLink('TikTok', 'https://www.tiktok.com/@khozna.np'),
                  _buildDotDivider(),
                  _buildSocialTextLink('LinkedIn', 'https://www.linkedin.com/company/110343039/'),
                ],
              ),
            ),

            const SizedBox(height: 24),

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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null ? Border.all(color: borderColor) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialTextLink(String label, String url) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildDotDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '•',
        style: TextStyle(color: Colors.grey[300], fontSize: 10),
      ),
    );
  }
}
