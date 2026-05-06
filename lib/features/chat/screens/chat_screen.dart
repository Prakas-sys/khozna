import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:khozna/core/theme/app_theme.dart';
import 'package:khozna/core/utils/supabase_service.dart';
import 'package:khozna/core/services/cloudinary_service.dart';
import 'package:khozna/core/models/chat_model.dart';
import 'package:khozna/features/chat/repositories/chat_repository.dart';
import 'package:khozna/features/profile/screens/owner_profile_screen.dart';
import '../widgets/chat_widgets.dart';

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final String name;
  final String avatar;
  final bool online;
  final String ownerId;
  final bool isVerified;
  final bool isOwner;

  const ChatScreen({
    super.key,
    this.chatId,
    required this.name,
    required this.avatar,
    required this.online,
    this.ownerId = '',
    this.isVerified = false,
    this.isOwner = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ScrollController _scrollController;
  late TextEditingController _messageController;
  late ScrollController _bannerScrollController;
  bool _isSendingImage = false;
  final List<ChatMessage> _optimisticMessages = [];

  String? _activeChatId;
  final String _currentUserId = supabase.Supabase.instance.client.auth.currentUser?.id ?? '';

  late String _displayName;
  late String _displayAvatar;
  late bool _isOwner;

  final List<String> _quickReplies = [
    'हजुर, कोठा अझै खाली छ!',
    'कति बजे हेर्न आउनुहुन्छ?',
    'पानी र बिजुलीको राम्रो सुविधा छ।',
    'पार्किङको व्यवस्था छ।',
    'भाडा मिलाउन सकिन्छ।',
  ];

  @override
  void initState() {
    super.initState();
    _activeChatId = widget.chatId;
    _scrollController = ScrollController();
    _messageController = TextEditingController();
    _bannerScrollController = ScrollController();
    _displayName = widget.name;
    _displayAvatar = widget.avatar;
    _isOwner = widget.isOwner;

    WidgetsBinding.instance.addPostFrameCallback((_) => _startBannerAnimation());
    if (widget.ownerId.isNotEmpty) {
      _loadOwnerProfile();
      if (_activeChatId == null) _initializeChat();
    } else if (_activeChatId != null) {
      ChatRepository.markChatAsRead(_activeChatId!);
    }
  }

  Future<void> _loadOwnerProfile() async {
    final profile = await SupabaseService.getUserProfile(widget.ownerId);
    if (profile != null && mounted) {
      setState(() {
        _displayName = profile.fullName;
        _displayAvatar = profile.avatarUrl ?? _displayAvatar;
        _displayAvatar = profile.avatarUrl ?? _displayAvatar;
        _isOwner = profile.isOwner;
      });
    }
  }

  Future<void> _initializeChat() async {
    try {
      final id = await ChatRepository.getOrCreateChat(widget.ownerId);
      if (mounted) {
        setState(() => _activeChatId = id);
        ChatRepository.markChatAsRead(id);
      }
    } catch (_) {}
  }

  void _startBannerAnimation() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_bannerScrollController.hasClients) {
        final maxScroll = _bannerScrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          await _bannerScrollController.animateTo(maxScroll, duration: Duration(milliseconds: (maxScroll * 40).toInt()), curve: Curves.linear);
          await Future.delayed(const Duration(seconds: 1));
          if (_bannerScrollController.hasClients) _bannerScrollController.jumpTo(0);
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _bannerScrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? text]) async {
    final msgText = text ?? _messageController.text.trim();
    if (msgText.isEmpty) return;
    if (text == null) _messageController.clear();

    final tempMsg = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      chatId: _activeChatId ?? '',
      senderId: _currentUserId,
      text: msgText,
      createdAt: DateTime.now(),
      isOptimistic: true,
    );

    setState(() => _optimisticMessages.insert(0, tempMsg));
    if (_activeChatId == null && widget.ownerId.isNotEmpty) await _initializeChat();

    if (_activeChatId != null) {
      ChatRepository.sendMessage(_activeChatId!, msgText).catchError((e) {
        if (mounted) setState(() => _optimisticMessages.remove(tempMsg));
      });
    }
  }

  Future<void> _pickAndSendImage() async {
    final XFile? picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    if (_activeChatId == null && widget.ownerId.isNotEmpty) await _initializeChat();
    if (_activeChatId == null) return;

    setState(() => _isSendingImage = true);
    try {
      final url = await CloudinaryService.uploadImage(File(picked.path));
      if (url != null) await ChatRepository.sendImageMessage(_activeChatId!, url);
    } finally {
      if (mounted) setState(() => _isSendingImage = false);
    }
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
        onTap: () {
          if (widget.ownerId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OwnerProfileScreen(
                  ownerId: widget.ownerId,
                  name: _displayName,
                  avatar: _displayAvatar,
                  location: 'Khozna User',
                  totalListings: _isOwner ? 1 : 0,
                ),
              ),
            );
          }
        },
          child: Row(
            children: [
              CircleAvatar(radius: 18, backgroundImage: (_displayAvatar.isNotEmpty && !_displayAvatar.contains('pravatar.cc')) ? CachedNetworkImageProvider(_displayAvatar) : null, child: (_displayAvatar.isEmpty || _displayAvatar.contains('pravatar.cc')) ? const Icon(Icons.person, size: 18) : null),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_displayName, style: GoogleFonts.inter(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
                Text(widget.online ? 'Online' : 'Offline', style: GoogleFonts.inter(color: widget.online ? Colors.green : Colors.grey, fontSize: 11)),
              ]),
            ],
          ),
        ),
        actions: [const SizedBox(width: 8)],
      ),
      body: Column(
        children: [
          ChatBanner(controller: _bannerScrollController),
          Expanded(
            child: _activeChatId == null
                ? const Center(child: Text('Start a conversation'))
                : StreamBuilder<List<ChatMessage>>(
                    stream: ChatRepository.getMessagesStream(_activeChatId!),
                    builder: (context, snapshot) {
                      final streamMessages = snapshot.data ?? [];
                      final streamTexts = streamMessages.map((m) => m.text).toSet();
                      final pending = _optimisticMessages.where((m) => !streamTexts.contains(m.text)).toList();
                      final messages = [...pending, ...streamMessages];

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) => MessageBubble(
                          message: messages[index],
                          isMe: messages[index].senderId == _currentUserId,
                          onLongPress: messages[index].senderId == _currentUserId ? () => _showDeleteDialog(messages[index].id) : null,
                        ),
                      );
                    },
                  ),
          ),
          // if (widget.ownerId.isNotEmpty) QuickReplyBar(replies: _quickReplies, onReplySelected: _sendMessage),
          _buildInputArea(),
        ],
      ),
    );
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Remove this message for everyone?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { Navigator.pop(ctx); ChatRepository.deleteMessage(id, _activeChatId!); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
  }

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 30),
            CircleAvatar(radius: 50, backgroundImage: (_displayAvatar.isNotEmpty && !_displayAvatar.contains('pravatar.cc')) ? CachedNetworkImageProvider(_displayAvatar) : null, child: (_displayAvatar.isEmpty || _displayAvatar.contains('pravatar.cc')) ? Icon(Icons.person, size: 50, color: Colors.grey[400]) : null),
            const SizedBox(height: 16),
            Text(_displayName, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(
              _isOwner ? 'Property Owner' : 'Guest',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _buildActionCircle(Icons.person_rounded, 'Profile', Colors.blue, () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OwnerProfileScreen(
                      ownerId: widget.ownerId,
                      name: _displayName,
                      avatar: _displayAvatar,
                      location: 'Khozna User',
                      totalListings: _isOwner ? 1 : 0,
                    ),
                  ),
                );
              }),
              const SizedBox(width: 32),
              _buildActionCircle(Icons.report_problem_rounded, 'Report', Colors.red, () {}),
            ]),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }



  Widget _buildActionCircle(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(children: [
      InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 26))),
      const SizedBox(height: 8),
      Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700])),
    ]);
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      color: Colors.transparent, 
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                height: 52, // Fixed height to keep it consistent
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 6),
                    // Left side rounded button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add_rounded, color: Color(0xFF6B7280), size: 22),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: double.infinity, // Touch top and bottom
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade200, width: 1),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: GoogleFonts.inter(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Message...',
                            hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 15),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF6B7280), size: 22),
                      onPressed: _pickAndSendImage,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _sendMessage(),
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: AppTheme.brandColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
