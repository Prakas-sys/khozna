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

  final List<Map<String, String>> _categories = [
    {'name': 'All', 'icon': 'apps'},
    {'name': 'Booking & Rent', 'icon': 'home'},
    {'name': 'KYC & Safety', 'icon': 'verified_user'},
    {'name': 'Payment', 'icon': 'account_balance_wallet'},
    {'name': 'Tours & Reels', 'icon': 'videocam'},
  ];

  final List<Map<String, dynamic>> _faqs = [
    {
      'category': 'Booking & Rent',
      'question': 'How do I schedule a physical or virtual property tour?',
      'answer':
          'Navigate to any property listing and tap "Book a Tour" or "Request Visit". You can choose your preferred date and time slot. The property owner will confirm the appointment directly.',
    },
    {
      'category': 'Booking & Rent',
      'question': 'Are there any hidden broker fees on Khozna?',
      'answer':
          'No! Khozna connects tenants directly with verified room/flat owners. We do not charge hidden middleman commissions or broker fees.',
    },
    {
      'category': 'KYC & Safety',
      'question': 'Why is location & ID verification (KYC) required?',
      'answer':
          'To keep our community safe and scam-free, both owners and tenants undergo identity verification. Verified profiles build mutual trust and ensure accurate rental agreements.',
    },
    {
      'category': 'KYC & Safety',
      'question': 'How can I report a suspicious or misleading listing?',
      'answer':
          'Tap the "Report" button on the property details screen or contact our support team on WhatsApp immediately. We review and remove fraudulent posts within 1 hour.',
    },
    {
      'category': 'Payment',
      'question': 'How is rental payment handled on Khozna?',
      'answer':
          'Rent payments are made directly between tenant and owner via preferred digital wallets (eSewa, Khalti, Bank Transfer). Always request a digital receipt inside the app chat.',
    },
    {
      'category': 'Payment',
      'question': 'What is the standard advance deposit policy?',
      'answer':
          'In Nepal, most owners request 1 month advance rent as security deposit. Ensure you get written confirmation or receipt via Khozna chat before transferring funds.',
    },
    {
      'category': 'Tours & Reels',
      'question': 'How do Video Reels work for properties?',
      'answer':
          'Khozna Reels allow you to take a 360-degree video tour of rooms and apartments before visiting in person. Swipe up in the Tours tab to explore authentic room videos.',
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & Support',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFF1F5F9),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Search Section
            _buildHeroHeader(),

            const SizedBox(height: 20),

            // Main Content Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Contact Card (WhatsApp / Support)
                  _buildLiveSupportBanner(context),

                  const SizedBox(height: 28),

                  // FAQ Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Frequently Asked Questions',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        '${filteredFaqs.length} items',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Category Chips
                  _buildCategoryChips(),

                  const SizedBox(height: 16),

                  // Accordion FAQs List
                  if (filteredFaqs.isEmpty)
                    _buildEmptyFaqState()
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredFaqs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final faq = filteredFaqs[index];
                        final isExpanded = _expandedFaqIndex == index;

                        return _buildFaqCard(
                          index: index,
                          faq: faq,
                          isExpanded: isExpanded,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _expandedFaqIndex = isExpanded ? null : index;
                            });
                          },
                        );
                      },
                    ),

                  const SizedBox(height: 32),

                  // Direct Contact Channel Options
                  _buildSectionHeader('Direct Channels', 'Reach us anytime via email or call'),
                  const SizedBox(height: 14),
                  _buildContactChannels(),

                  const SizedBox(height: 32),

                  // Community Social Grid
                  _buildSectionHeader('Official Community', 'Join our verified social updates'),
                  const SizedBox(height: 14),
                  _buildSocialCommunityGrid(),

                  const SizedBox(height: 44),

                  // Footer Info
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Systems Operational • v1.0.0',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '© KHOZNA Nepal • All Rights Reserved',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.brandColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.headset_mic_rounded, size: 14, color: AppTheme.brandColor),
                    const SizedBox(width: 6),
                    Text(
                      'Khozna Concierge',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.brandColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'How can we help you?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -0.6,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Search questions, safety rules, booking guidelines or contact support.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 18),

          // Search Field
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
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
                hintText: 'Search topic, e.g. "rent", "deposit", "broker"...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[400],
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.black54, size: 20),
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
        ],
      ),
    );
  }

  Widget _buildLiveSupportBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '⚡ Usually replies in 15 mins',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF34D399),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366), size: 22),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Need Instant Assistance?',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 19,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Chat directly with our Nepal operations team on WhatsApp for fast conflict resolution and booking inquiries.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.grey[400],
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _launchUrl('https://wa.me/9779705278379');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Chat on WhatsApp (कुरा गर्नुहोस्)',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final String name = cat['name']!;
          final bool isSelected = _selectedCategory == name;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(name),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedCategory = name;
                    _expandedFaqIndex = null;
                  });
                }
              },
              selectedColor: Colors.black,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              labelStyle: GoogleFonts.plusJakartaSans(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? Colors.black : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFaqCard({
    required int index,
    required Map<String, dynamic> faq,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded ? AppTheme.brandColor : const Color(0xFFE2E8F0),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isExpanded ? 0.05 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      faq['category']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: isExpanded ? AppTheme.brandColor : Colors.grey[400],
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                faq['question']!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  height: 1.3,
                ),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
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
  }

  Widget _buildEmptyFaqState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 44, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No matching questions found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try searching different terms or contact team directly.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildContactChannels() {
    return Column(
      children: [
        _buildContactTile(
          icon: Icons.phone_in_talk_rounded,
          iconBgColor: const Color(0xFFECFDF5),
          iconColor: const Color(0xFF059669),
          title: 'Direct Phone Line',
          subtitle: '+977 9705278379',
          badgeText: 'Call Support',
          onTap: () => _launchUrl('tel:+9779705278379'),
        ),
        const SizedBox(height: 10),
        _buildContactTile(
          icon: Icons.mark_email_read_rounded,
          iconBgColor: const Color(0xFFEFF6FF),
          iconColor: const Color(0xFF2563EB),
          title: 'Official Support Email',
          subtitle: 'khoznaapp@gmail.com',
          badgeText: 'Email Support',
          onTap: () => _launchUrl('mailto:khoznaapp@gmail.com'),
        ),
      ],
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialCommunityGrid() {
    final socials = [
      {
        'name': 'Facebook',
        'icon': FontAwesomeIcons.facebook,
        'color': const Color(0xFF1877F2),
        'bgColor': const Color(0xFFEFF6FF),
        'url': 'https://www.facebook.com/profile.php?id=61587497082072',
      },
      {
        'name': 'Instagram',
        'icon': FontAwesomeIcons.instagram,
        'color': const Color(0xFFE4405F),
        'bgColor': const Color(0xFFFDF2F8),
        'url': 'https://www.instagram.com/khozna.np/',
      },
      {
        'name': 'TikTok',
        'icon': FontAwesomeIcons.tiktok,
        'color': Colors.black,
        'bgColor': const Color(0xFFF1F5F9),
        'url': 'https://www.tiktok.com/@khozna.np',
      },
      {
        'name': 'LinkedIn',
        'icon': FontAwesomeIcons.linkedin,
        'color': const Color(0xFF0A66C2),
        'bgColor': const Color(0xFFEFF6FF),
        'url': 'https://www.linkedin.com/company/110343039/',
      },
    ];

    return Row(
      children: socials.map((social) {
        final String name = social['name'] as String;
        final IconData icon = social['icon'] as IconData;
        final Color color = social['color'] as Color;
        final Color bgColor = social['bgColor'] as Color;
        final String url = social['url'] as String;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _launchUrl(url);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(icon, color: color, size: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
