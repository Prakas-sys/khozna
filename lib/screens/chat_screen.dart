import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/supabase_service.dart';
import '../utils/cloudinary_service.dart';
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
    this.isVerified = false,
  });

  final bool isVerified;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late TextEditingController _messageController;
  late ScrollController _bannerScrollController;
  bool _isSendingImage = false;
  bool _showEmojiPicker = false;
  final List<Map<String, dynamic>> _optimisticMessages = [];

  String? _activeChatId;
  final String _currentUserId =
      supabase.Supabase.instance.client.auth.currentUser?.id ?? '';

  late String _displayName;
  late String _displayAvatar;
  late String _displayPhone;

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

    _displayName = widget.name;
    _displayAvatar = widget.avatar;
    _displayPhone = widget.phone;

    if (_activeChatId == null && widget.ownerId.isNotEmpty) {
      _initializeChat();
    }

    if (_displayName == 'Khozna User' && widget.ownerId.isNotEmpty) {
      _loadOwnerProfile();
    }
  }

  Future<void> _loadOwnerProfile() async {
    try {
      final profile = await SupabaseService.getUserProfile(widget.ownerId);
      if (profile != null && mounted) {
        setState(() {
          _displayName = profile['full_name'] ?? _displayName;
          _displayAvatar = profile['avatar_url'] ?? _displayAvatar;
          _displayPhone = profile['phone_number'] ?? _displayPhone;
        });
      }
    } catch (e) {
      debugPrint('Failed to load owner profile: $e');
    }
  }

  Future<void> _initializeChat() async {
    try {
      final id = await SupabaseService.getOrCreateChat(widget.ownerId);
      if (mounted) {
        setState(() => _activeChatId = id);
        // Mark as read once initialized
        SupabaseService.markChatAsRead(id);
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
                backgroundColor: Colors.grey[200],
                backgroundImage: (_displayAvatar.isNotEmpty && !_displayAvatar.contains('pravatar.cc'))
                    ? CachedNetworkImageProvider(_displayAvatar)
                    : null,
                child: (_displayAvatar.isEmpty || _displayAvatar.contains('pravatar.cc'))
                    ? Icon(Icons.person, size: 50, color: Colors.grey[400])
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                _displayName,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                'Property Owner',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActionCircle(
                    Icons.call_rounded,
                    'Call',
                    Colors.green,
                    _startCall,
                  ),
                  const SizedBox(width: 32),
                  _buildActionCircle(
                    Icons.person_rounded,
                    'Profile',
                    Colors.blue,
                    () {},
                  ),
                  const SizedBox(width: 32),
                  _buildActionCircle(
                    Icons.report_problem_rounded,
                    'Report &\nBlock',
                    Colors.red,
                    () {},
                  ),
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
                      const Icon(
                        Icons.phone_iphone_rounded,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _displayPhone,
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
    final Uri launchUri = Uri(scheme: 'tel', path: _displayPhone);

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

  Widget _buildActionCircle(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
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
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
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
      setState(() => _showEmojiPicker = false);

      final tempMsg = {
        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'sender_id': _currentUserId,
        'text': text,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'is_optimistic': true,
      };

      setState(() {
        _optimisticMessages.insert(0, tempMsg);
      });

      if (_activeChatId == null && widget.ownerId.isNotEmpty) {
        await _initializeChat();
      }

      if (_activeChatId != null) {
        // Fire and forget so the UI doesn't hitch
        SupabaseService.sendMessage(_activeChatId!, text).catchError((e) {
          if (mounted) {
            setState(() {
              _optimisticMessages.remove(tempMsg);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to send message')),
            );
          }
        });
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    if (_activeChatId == null && widget.ownerId.isNotEmpty) {
      await _initializeChat();
    }
    if (_activeChatId == null) return;

    setState(() => _isSendingImage = true);
    try {
      final url = await CloudinaryService.uploadImage(File(picked.path));
      if (url != null) {
        await SupabaseService.sendImageMessage(_activeChatId!, url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSendingImage = false);
    }
  }

  void _showDeleteMessageDialog(String messageId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Message',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Remove this message for everyone?',
            style: GoogleFonts.inter(color: Colors.grey[600])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.deleteMessage(messageId);
            },
            child: Text('Delete', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  void _showDeleteChatDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Conversation',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
            'This will permanently delete this chat for you. The other person will still see it.',
            style: GoogleFonts.inter(color: Colors.grey[600])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              if (_activeChatId != null) {
                await SupabaseService.deleteChat(_activeChatId!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Chat deleted', style: GoogleFonts.inter()),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
              if (mounted) Navigator.pop(context);
            },
            child: Text('Delete', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  String _formatMsgTime(String? isoTime) {
    if (isoTime == null) return '';
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  Widget _buildEmojiTip(String emoji) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        final text = _messageController.text;
        _messageController.text = text + emoji;
        // Keep cursor at the end
        _messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: _messageController.text.length),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 18)),
      ),
    );
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
                backgroundColor: Colors.grey[100],
                backgroundImage: (_displayAvatar.isNotEmpty && !_displayAvatar.contains('pravatar.cc'))
                    ? CachedNetworkImageProvider(_displayAvatar)
                    : null,
                child: (_displayAvatar.isEmpty || _displayAvatar.contains('pravatar.cc'))
                    ? Icon(Icons.person, size: 18, color: Colors.grey[400])
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _displayName == 'Khozna User'
                      ? const SizedBox(
                          height: 16,
                          width: 80,
                          child: LinearProgressIndicator(minHeight: 2),
                        )
                      : Row(
                          children: [
                            Text(
                              _displayName,
                              style: GoogleFonts.inter(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, size: 16, color: Colors.blue),
                            ],
                          ],
                        ),
                  Text(
                    widget.ownerId.isNotEmpty 
                        ? 'Owner • ${widget.online ? 'Online' : 'Offline'}'
                        : '${widget.online ? 'Online' : 'Offline'}',
                    style: GoogleFonts.inter(
                      color: widget.online ? Colors.green : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.call_outlined,
              color: Colors.black,
              size: 22,
            ),
            onPressed: _startCall,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black, size: 22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'delete_chat') _showDeleteChatDialog();
              if (value == 'profile') _showProfileSheet();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(children: [
                  const Icon(Icons.person_outline, size: 18),
                  const SizedBox(width: 10),
                  Text('View Profile', style: GoogleFonts.inter()),
                ]),
              ),
              PopupMenuItem(
                value: 'delete_chat',
                child: Row(children: [
                  const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  const SizedBox(width: 10),
                  Text('Delete Chat',
                      style: GoogleFonts.inter(color: Colors.red)),
                ]),
              ),
            ],
          ),
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
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'अग्रिम पैसा कहिल्यै नपठाउनुहोस्! • Never send advance payment before visiting! • कोठा हेरेर मात्र पैसा दिनुहोला!',
                        style: GoogleFonts.inter(
                          color: Colors.red[800],
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
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
                      final streamMessages = snapshot.data ?? [];
                      
                      final streamMessageTexts = streamMessages.where((m) => m['text'] != null).map((m) => m['text']).toSet();
                      final pendingMessages = _optimisticMessages.where((m) => !streamMessageTexts.contains(m['text'])).toList();
                      final messages = [...pendingMessages, ...streamMessages];

                      if (messages.isEmpty) return _buildEmptyState();

                      // Mark as read when new messages arrive and we are viewing
                      if (_activeChatId != null) {
                        SupabaseService.markChatAsRead(_activeChatId!);
                      }

                      // No manual scroll needed with reverse: true

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                      itemBuilder: (context, index) {
                          final msg = messages[index];
                          final bool isMe = msg['sender_id'] == _currentUserId;
                          final bool isDeleted = msg['is_deleted'] == true;
                          final String? imageUrl = msg['image_url'];
                          final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

                          return GestureDetector(
                            onLongPress: isMe && !isDeleted
                                ? () => _showDeleteMessageDialog(msg['id'])
                                : null,
                            child: Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 0.5),
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                                    ),
                                    padding: hasImage
                                        ? EdgeInsets.zero
                                        : const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDeleted
                                          ? Colors.grey[100]
                                          : isMe
                                              ? AppTheme.brandColor
                                              : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                                        bottomRight: Radius.circular(isMe ? 4 : 16),
                                      ),
                                      boxShadow: isMe
                                          ? []
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.05),
                                                blurRadius: 2,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                      border: Border.all(
                                        color: isDeleted
                                            ? Colors.grey.shade200
                                            : isMe
                                                ? Colors.black.withValues(alpha: 0.08)
                                                : Colors.grey.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: isDeleted
                                        ? Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            child: Text(
                                              '🗑️ Message deleted',
                                              style: GoogleFonts.inter(
                                                color: Colors.grey[400],
                                                fontSize: 13,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          )
                                        : hasImage
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.only(
                                                  topLeft: const Radius.circular(15),
                                                  topRight: const Radius.circular(15),
                                                  bottomLeft: Radius.circular(isMe ? 15 : 3),
                                                  bottomRight: Radius.circular(isMe ? 3 : 15),
                                                ),
                                                child: CachedNetworkImage(
                                                  imageUrl: imageUrl,
                                                  width: 220,
                                                  fit: BoxFit.cover,
                                                  placeholder: (_, __) => Container(
                                                    width: 220,
                                                    height: 180,
                                                    color: Colors.grey[200],
                                                    child: const Center(
                                                        child: CircularProgressIndicator()),
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                msg['text'] ?? '',
                                                style: GoogleFonts.inter(
                                                  color: isMe
                                                      ? Colors.white
                                                      : const Color(0xFF1A1A1A),
                                                  fontSize: 16,
                                                  height: 1.25,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 2, right: 4, left: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isMe) ...[
                                          Icon(
                                            msg['is_optimistic'] == true ? Icons.access_time_rounded : (msg['is_read'] == true ? Icons.done_all_rounded : Icons.done_rounded),
                                            size: 13, 
                                            color: msg['is_optimistic'] == true ? Colors.grey[400] : (msg['is_read'] == true ? Colors.blue : Colors.grey[400]),
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          _formatMsgTime(msg['created_at']),
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
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),

          // FLOATING MESSAGE INPUT - Simplified Single Layer
          // PERFECT CLEAN FLOATING INPUT
          // EMOJI QUICK BAR
          Column(
            children: [
              if (_isSendingImage)
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: AppTheme.brandColor,
                ),
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
                child: Row(
                  children: [
                    _buildEmojiTip('🏠'),
                    _buildEmojiTip('🔑'),
                    _buildEmojiTip('💰'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 54),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(28),
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
                      // Gallery button
                      IconButton(
                        icon: const Icon(
                          Icons.image_outlined,
                          color: Color(0xFF64748B),
                        ),
                        onPressed: _isSendingImage ? null : _pickAndSendImage,
                      ),
                      // Text field
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: 5,
                          minLines: 1,
                          onTap: () => setState(() => _showEmojiPicker = false),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: const Color(0xFF1E293B),
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type message...',
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8),
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      // Send button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
                        child: GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.brandColor,
                                  AppTheme.brandColor.withValues(alpha: 0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.brandColor
                                      .withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.send_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.brandColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
              child: SvgPicture.asset(
                'assets/icons/message.svg',
                colorFilter: const ColorFilter.mode(
                  AppTheme.brandColor,
                  BlendMode.srcIn,
                ),
                width: 56,
                height: 56,
              ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start the Conversation',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Say hello or ask about the property! 👋',
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
