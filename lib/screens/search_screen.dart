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
  final List<String> _recentSearches = ['Baluwatar', '2BHK Sanepa', 'Flat under 20k', 'Baneshwor Room'];
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
                // Premium Search Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Hero(
                        tag: 'search_bar_container',
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.grey.shade200, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search, color: Colors.grey, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
                                    cursorColor: AppTheme.brandColor,
                                    decoration: InputDecoration(
                                      hintText: 'Search properties',
                                      hintStyle: GoogleFonts.inter(
                                        color: Colors.grey[500],
                                        fontSize: 15,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                    ),
                                    onChanged: (val) => setState(() {}),
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () => setState(() => _searchController.clear()),
                                    child: Icon(Icons.cancel, size: 20, color: Colors.grey[400]),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // PREMIUM MAGIC AI SEARCH CARD
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF8E2DE2),
                        const Color(0xFF4A00E0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A00E0).withValues(alpha: 0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          top: -10,
                          child: Icon(Icons.auto_awesome, size: 80, color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isAiSearching ? null : _runAiSearch,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: _isAiSearching 
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isAiSearching ? 'AI Finding Perfect Match...' : 'Magic AI Match',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        Text(
                                          'Find your dream home in seconds',
                                          style: GoogleFonts.inter(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                                ],
                              ),
                            ),
                          ),
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
                      color: Colors.purple.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.stars, color: Colors.purple, size: 18),
                            const SizedBox(width: 8),
                            Text('AI Suggestions', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.purple[800])),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                              onPressed: () => setState(() => _aiSearchResult = null),
                            )
                          ],
                        ),
                        Text(
                          _aiSearchResult!,
                          style: GoogleFonts.inter(fontSize: 13, height: 1.5),
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
                          Text('रू 2K', style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('रू 100K+', style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.brandColor,
                          inactiveTrackColor: AppTheme.brandColor.withOpacity(0.1),
                          thumbColor: Colors.white,
                          overlayColor: AppTheme.brandColor.withOpacity(0.1),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 4),
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
                      Text(
                        'रू ${PriceFormatter.format(_priceValue.toInt().toString())} / month',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.brandColor,
                          fontSize: 18,
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
                  children: _recentSearches.map((search) => _buildRecentTag(search)).toList(),
                ),
                const SizedBox(height: 40),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Popular Areas ',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: '(लोकप्रिय ठाउँहरू)',
                        style: GoogleFonts.mukta(
                          fontSize: 14,
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => FilterResultsScreen(priceRange: 'Up to Rs. ${_priceValue.toInt()}')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('Apply Filters & Search', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AiChatScreen()));
        },
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.support_agent, color: Colors.white),
        label: Text('AI Assistant', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildRecentTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey[300]!)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.history, size: 14, color: Colors.grey), const SizedBox(width: 8), Text(text, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87))]),
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
          child: const Icon(Icons.location_on_rounded, color: AppTheme.brandColor, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        subtitle: Text(
          count,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
        onTap: () {},
      ),
    );
  }

  Future<void> _runAiSearch() async {
    if (_searchController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please type what you are looking for first!')));
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
      
      final List<Map<String, dynamic>> properties = propertiesData.cast<Map<String, dynamic>>();

      // 2. Call AI Service
      final result = await _aiService.matchProperty(_searchController.text, properties);

      setState(() {
        _aiSearchResult = result;
        _isAiSearching = false;
      });
    } catch (e) {
      setState(() => _isAiSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Search failed: $e')));
      }
    }
  }
}
