import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    const Color airbnbGrey = Color(0xFF717171);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Search Bar
            Hero(
              tag: 'search_bar',
              child: Material(
                color: Colors.transparent,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade200, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 15,
                        spreadRadius: 0,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Icon(
                        CupertinoIcons.search,
                        color: AppTheme.brandColor,
                        size: 26,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: _searchController.text.isEmpty,
                          style: GoogleFonts.inter(fontSize: 16, color: Colors.black),
                          cursorColor: Colors.black, // No more blue cursor
                          decoration: InputDecoration(
                            hintText: 'Search properties',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                          onChanged: (val) => setState(() {}),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // MAGIC AI SEARCH BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAiSearching ? null : _runAiSearch,
                icon: _isAiSearching 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  _isAiSearching ? 'AI Matching...' : 'Magic AI Match (Nepal Edition)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Price Range ',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: '(भाडाको सीमा)',
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Min: रू ${PriceFormatter.format('2000')}', style: GoogleFonts.inter(color: airbnbGrey)),
                      Text('Max: रू ${PriceFormatter.format('100000')}+', style: GoogleFonts.inter(color: airbnbGrey)),
                    ],
                  ),
                  Slider(
                    value: _priceValue,
                    min: 2000,
                    max: 100000,
                    activeColor: AppTheme.brandColor,
                    onChanged: (val) => setState(() => _priceValue = val),
                  ),
                  Text(
                    'Up to रू ${PriceFormatter.format(_priceValue.toInt().toString())}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.brandColor, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Recently Searched ',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: '(भर्खरै खोजिएका)',
                          style: GoogleFonts.mukta(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _recentSearches.clear();
                    });
                  },
                  child: Text(
                    'Clear',
                    style: GoogleFonts.inter(color: airbnbGrey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 12,
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
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AiChatScreen()));
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.brandColor.withValues(alpha: 0.05), shape: BoxShape.circle), child: const Icon(Icons.location_on_outlined, color: AppTheme.brandColor, size: 20)),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      subtitle: Text(count, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () {},
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
