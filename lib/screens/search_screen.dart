import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/screens/chat_screen.dart' as chat_page;
import '../theme/app_theme.dart';
import '../utils/khozna_ai_service.dart';
import '../widgets/voice_search_overlay.dart';
import 'filter_results_screen.dart';
import 'ai_chat_screen.dart';
import '../utils/formatters.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  double _priceValue = 5000;
  final List<String> _recentSearches = [
    'Baluwatar',
    '2BHK Sanepa',
    'Flat under 20k',
    'Baneshwor Room',
  ];
  late TextEditingController _searchController;

  // AI Search State
  final KhoznaAiService _aiService = KhoznaAiService();
  bool _isAiSearching = false;
  String? _aiSearchResult;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Auto-fill from voice search or constructor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        setState(() {
          _searchController.text = widget.initialQuery!;
        });
        return;
      }

      final Object? args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty) {
        setState(() {
          _searchController.text = args;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Section with Back Arrow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.black,
                          size: 22,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    Text(
                      'Search Properties',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Full Width Standardized Search Bar
                Hero(
                  tag: 'search_bar_container',
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.only(left: 16, right: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                                const Icon(
                                  CupertinoIcons.search,
                                  color: Colors.black54,
                                  size: 26,
                                ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: widget.initialQuery == null,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              cursorColor: AppTheme.brandColor,
                              decoration: InputDecoration(
                                hintText: 'Search properties',
                                hintStyle: GoogleFonts.inter(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (val) => setState(() {}),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: () => setState(() => _searchController.clear()),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  child: Icon(Icons.cancel, size: 20, color: Colors.grey[400]),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // PREMIUM MAGIC AI SEARCH CARD
                // SIMPLIFIED AI SEARCH SECTION
                GestureDetector(
                  onTap: _isAiSearching ? null : _runAiSearch,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.brandColor.withOpacity(0.05),
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.brandColor.withOpacity(0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandColor.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _isAiSearching
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.brandColor),
                              )
                            : Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.brandColor, size: 20),
                              ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isAiSearching ? 'AI ले खोज्दैछ...' : 'AI को साथ खोज्नुहोस्',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'एक ट्यापमा मनपर्ने कोठा भेट्टाउनुहोस्',
                                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.brandColor, size: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_aiSearchResult != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.black54, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'AI सुझाव',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const Spacer(),
                            GestureDetector(
                                onTap: () => setState(() => _aiSearchResult = null),
                                child: Icon(Icons.close, size: 18, color: Colors.grey[400])
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _aiSearchResult!,
                          style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                Text(
                  'PRICE RANGE (भाडाको सीमा)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.black38,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade100, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '₹',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                TextSpan(
                                  text: ' 2K',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '₹',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                TextSpan(
                                  text: ' 100K+',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.brandColor,
                          inactiveTrackColor: AppTheme.brandColor.withOpacity(
                            0.1,
                          ),
                          thumbColor: Colors.white,
                          overlayColor: AppTheme.brandColor.withOpacity(0.1),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10,
                            elevation: 4,
                          ),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: _priceValue,
                          min: 2000,
                          max: 100000,
                          onChanged: (val) => setState(() => _priceValue = val),
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '₹ ',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.brandColor,
                              ),
                            ),
                            TextSpan(
                              text: '${PriceFormatter.format(_priceValue.toInt().toString())} / month',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.brandColor,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'RECENTLY SEARCHED (भर्खरै खोजिएका)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.black38,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _recentSearches
                      .map((search) => _buildRecentTag(search))
                      .toList(),
                ),
                const SizedBox(height: 40),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Popular Areas ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: '(लोकप्रिय ठाउँहरू)',
                        style: GoogleFonts.mukta(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildAreaItem('Baluwatar, Kathmandu', '450+ Listings'),
                _buildAreaItem('Sanepa, Lalitpur', '320+ Listings'),
                _buildAreaItem('Baneshwor, Kathmandu', '580+ Listings'),
                _buildAreaItem('Jhamsikhel, Lalitpur', '210+ Listings'),
                const SizedBox(height: 80), // Prevent collision with FAB
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FilterResultsScreen(
                    priceRange: 'Up to ₹ ${_priceValue.toInt()}',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Apply Filters & Search',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AiChatScreen()),
          );
        },
        backgroundColor: AppTheme.brandColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        icon: const Icon(Icons.support_agent, color: Colors.white),
        label: Text(
          'AI सहायक',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildRecentTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaItem(String title, String count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.brandColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: AppTheme.brandColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        subtitle: Text(
          count,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Colors.grey.shade400,
        ),
        onTap: () {},
      ),
    );
  }

  Future<void> _runAiSearch() async {
    if (_searchController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please type what you are looking for first!'),
        ),
      );
      return;
    }

    setState(() {
      _isAiSearching = true;
      _aiSearchResult = null;
    });

    try {
      // 1. Fetch properties for context (limiting to 10 for free tier efficiency)
      final supabase = Supabase.instance.client;
      final List<dynamic> propertiesData = await supabase
          .from('properties')
          .select('id, title, price, area_name, category')
          .limit(10);

      final List<Map<String, dynamic>> properties = propertiesData
          .cast<Map<String, dynamic>>();

      // 2. Call AI Service
      final result = await _aiService.matchProperty(
        _searchController.text,
        properties,
      );

      setState(() {
        _aiSearchResult = result;
        _isAiSearching = false;
      });
    } catch (e) {
      setState(() => _isAiSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI Search failed: $e')));
      }
    }
  }
}
