import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../theme/app_theme.dart';
import '../utils/supabase_service.dart';
import 'boost_promotion_screen.dart';

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final String name;
  final String avatar;
  final bool online;
  final String phone;
  final String ownerId;

  const ChatScreen({
    super.key,
    this.chatId,
    required this.name,
    required this.avatar,
    required this.online,
    this.phone = "+977 9801234567",
    this.ownerId = '',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late TextEditingController _messageController;
  late ScrollController _bannerScrollController;

  String? _activeChatId;
  final String _currentUserId = supabase.Supabase.instance.client.auth.currentUser?.id ?? '';

  // Owner auto-reply messages pool
  final List<String> _ownerReplies = [
    'हजुर, कोठा अझै खाली छ! कहिले हेर्न आउनुहुन्छ?',
    'ठिकै छ। तपाईंसँग कुरा गर्न पाउँदा खुसी लाग्यो! 😊',
    'हजुर, पानी र बिजुली दुवै सुविधा छ। २४ सै घण्टा।',
    'पार्किङको राम्रो व्यवस्था छ। बाइक र कार दुवैको लागि।',
    'भाडा मिलाउन सकिन्छ। सिधै भेटेर कुरा गरौं!',
    'ठिकै छ! भोलि बिहान १० बजे हेर्न आउनुस् न।',
    'WiFi को राम्रो सुविधा छ। ५० Mbps को कनेक्शन छ।',
    'धन्यवाद! कुनै अन्य प्रश्न भए सोध्नुस्। 🙏',
  ];
  int _replyIndex = 0;

  @override
  void initState() {
    super.initState();
    _activeChatId = widget.chatId;
    _scrollController = ScrollController();
    _messageController = TextEditingController();
    _bannerScrollController = ScrollController();

    // Auto-scroll banner animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBannerAnimation();
    });

    if (_activeChatId == null && widget.ownerId.isNotEmpty) {
       _initializeChat();
    }
  }

  Future<void> _initializeChat() async {
    try {
      final id = await SupabaseService.getOrCreateChat(widget.ownerId);
      if (mounted) {
        setState(() => _activeChatId = id);
      }
    } catch (e) {
      debugPrint('Chat init error: $e');
    }
  }

  void _filterOldMessages() {
    // Note: Database handles this now via the 30-day retention policy SQL
  }

  void _startBannerAnimation() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_bannerScrollController.hasClients) {
        final maxScroll = _bannerScrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          await _bannerScrollController.animateTo(
            maxScroll,
            duration: Duration(milliseconds: (maxScroll * 40).toInt()),
            curve: Curves.linear,
          );
          await Future.delayed(const Duration(seconds: 1));
          if (_bannerScrollController.hasClients) {
            _bannerScrollController.jumpTo(0);
          }
        }
      }
    }
  }

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 30),
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(widget.avatar),
              ),
              const SizedBox(height: 16),
              Text(
                widget.name,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                'Property Owner',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActionCircle(Icons.call_rounded, 'Call', Colors.green, _startCall),
                  const SizedBox(width: 32),
                  _buildActionCircle(Icons.person_rounded, 'Profile', Colors.blue, () {}),
                  const SizedBox(width: 32),
                  _buildActionCircle(Icons.report_problem_rounded, 'Report &\nBlock', Colors.red, () {}),
                ],
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50] ?? const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_iphone_rounded, color: Colors.blueGrey),
                      const SizedBox(width: 16),
                      Text(
                        widget.phone,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startCall() async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: widget.phone,
    );
    
    if (await canLaunchUrl(launchUri)) {
      if (mounted) {
        Navigator.pop(context); // Close sheet if open
      }
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  Widget _buildActionCircle(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _bannerScrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      final text = _messageController.text.trim();
      _messageController.clear();

      if (_activeChatId == null && widget.ownerId.isNotEmpty) {
        await _initializeChat();
      }

      if (_activeChatId != null) {
        await SupabaseService.sendMessage(_activeChatId!, text);
      }
      
      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Widget _buildQuickReply(String text) {
    return InkWell(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        titleSpacing: 0,
        title: InkWell(
          onTap: _showProfileSheet,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(widget.avatar),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Owner • ${widget.online ? 'Online' : 'Offline'}',
                    style: GoogleFonts.inter(
                      color: widget.online ? Colors.green : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                ],
              )
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Colors.black, size: 22), 
            onPressed: _startCall,
          ),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.black, size: 22), onPressed: _showProfileSheet),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // SAFETY BANNER
          Container(
            height: 36,
            width: double.infinity,
            color: const Color(0xFFFFEBEE),
            child: ListView(
              controller: _bannerScrollController,
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'अग्रिम पैसा कहिल्यै नपठाउनुहोस्! • Never send advance payment before visiting! • कोठा हेरेर मात्र पैसा दिनुहोला!',
                        style: GoogleFonts.inter(
                          color: Colors.red[800], 
                          fontWeight: FontWeight.w600, 
                          fontSize: 12
                        ),
                      ),
                      const SizedBox(width: 200), // Extra space for smooth loop
                    ],
                  ),
                ),
              ],
            ),
          ),
          // CHAT MESSAGES
          Expanded(
            child: _activeChatId == null
              ? _buildEmptyState()
              : StreamBuilder<List<Map<String, dynamic>>>(
                  stream: SupabaseService.getMessagesStream(_activeChatId!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final messages = snapshot.data ?? [];
                    
                    if (messages.isEmpty) return _buildEmptyState();

                    // Scroll to bottom when new messages arrive
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final bool isMe = msg['sender_id'] == _currentUserId;
                        
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 0.5),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isMe ? AppTheme.brandColor : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 16),
                                  ),
                                  boxShadow: isMe ? [] : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                  border: isMe ? null : Border.all(color: Colors.grey.shade200, width: 0.5),
                                ),
                                child: Text(
                                  msg['text'] ?? '',
                                  style: GoogleFonts.inter(
                                    color: isMe ? Colors.white : const Color(0xFF1A1A1A),
                                    fontSize: 17, 
                                    height: 1.25,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 2, right: 4, left: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isMe) ...[
                                      const Icon(Icons.done_all_rounded, size: 14, color: Colors.blue),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      "Just now",
                                      style: GoogleFonts.inter(
                                        color: Colors.grey[500],
                                        fontSize: 10,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
          ),

          // FLOATING MESSAGE INPUT - Simplified Single Layer
          // PERFECT CLEAN FLOATING INPUT
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 54),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9), // Deeper slate for contrast
                    borderRadius: BorderRadius.circular(28), // The "big one" full radius
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: 5,
                          minLines: 1,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: const Color(0xFF1E293B),
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type message...',
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8), 
                              fontSize: 15
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), // Increased horizontal padding
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
                        child: GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.brandColor, AppTheme.brandColor.withValues(alpha: 0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.brandColor.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, color: Colors.grey[300], size: 64),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Say hello to start the conversation! 👋',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
