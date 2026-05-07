import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/models/chat_model.dart';
import 'package:khozna/core/utils/app_notifiers.dart';
import 'package:khozna/core/security/app_logger.dart';
import 'package:khozna/core/security/security_utils.dart';

class ChatRepository {
  static final _client = Supabase.instance.client;

  static Future<List<ChatConversation>> getConversations() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    // 1. Fetch chats
    final response = await _client
        .from('chats')
        .select('*')
        .or('user1_id.eq.${user.id},user2_id.eq.${user.id}')
        .order('updated_at', ascending: false);

    final List chatsData = response as List;
    if (chatsData.isEmpty) return [];

    // 1.5 Fetch unread counts
    final unreadResponse = await _client
        .from('messages')
        .select('chat_id')
        .eq('is_read', false)
        .neq('sender_id', user.id);
        
    final Map<String, int> unreadCounts = {};
    for (var row in (unreadResponse as List)) {
      final cId = row['chat_id']?.toString();
      if (cId != null) {
        unreadCounts[cId] = (unreadCounts[cId] ?? 0) + 1;
      }
    }

    // 2. Identify all "other" user IDs to fetch profiles in bulk
    final Set<String> otherUserIds = {};
    for (var chat in chatsData) {
      final u1 = chat['user1_id']?.toString();
      final u2 = chat['user2_id']?.toString();
      if (u1 != null && u1 != user.id) otherUserIds.add(u1);
      else if (u2 != null && u2 != user.id) otherUserIds.add(u2);
    }

    // 3. Fetch profiles
    Map<String, dynamic> profiles = {};
    if (otherUserIds.isNotEmpty) {
      final profilesResponse = await _client
          .from('profiles')
          .select('id, full_name, avatar_url')
          .inFilter('id', otherUserIds.toList());
      
      for (var p in (profilesResponse as List)) {
        profiles[p['id']] = p;
      }
    }

    // 4. Map to models and deduplicate by other user
    final Map<String, ChatConversation> uniqueChats = {};
    for (var e in chatsData) {
      final u1 = e['user1_id']?.toString();
      final u2 = e['user2_id']?.toString();
      final otherId = (u1 != user.id) ? u1 : u2;
      if (otherId == null) continue;
      
      final profile = profiles[otherId];
      final chatTime = DateTime.parse(e['updated_at'] ?? DateTime.now().toIso8601String()).toLocal();
      
      final chat = ChatConversation(
        id: e['id'],
        otherUserId: otherId,
        otherUserName: profile?['full_name'] ?? 'Khozna User',
        otherUserAvatar: profile?['avatar_url'] ?? '',
        lastMessage: e['last_message_text'],
        lastMessageTime: chatTime,
        unreadCount: unreadCounts[e['id']?.toString()] ?? 0,
      );
      
      if (!uniqueChats.containsKey(otherId) || chatTime.isAfter(uniqueChats[otherId]!.lastMessageTime)) {
        uniqueChats[otherId] = chat;
      }
    }
    
    final sortedList = uniqueChats.values.where((chat) => chat.otherUserName != 'Khozna User').toList();
    sortedList.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return sortedList;
  }

  static Future<String> getOrCreateChat(String otherUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'User not authenticated';

    // Sort IDs to ensure consistent chat room identification
    final ids = [user.id, otherUserId]..sort();
    final u1 = ids[0];
    final u2 = ids[1];

    final response = await _client
        .from('chats')
        .select('id')
        .eq('user1_id', u1)
        .eq('user2_id', u2)
        .maybeSingle();

    if (response != null) {
      return response['id'];
    }

    final newChat = await _client.from('chats').insert({
      'user1_id': u1,
      'user2_id': u2,
      'participants': [u1, u2],
    }).select('id').single();

    return newChat['id'];
  }

  static Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => ChatMessage.fromMap(e)).toList());
  }

  static Future<void> sendMessage(String chatId, String text) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    
    // 🔐 Prevent XSS and Injection in messages
    final cleanText = SecurityUtils.sanitizeInput(text, maxLength: 2000);
    if (cleanText.isEmpty) return;

    await _client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': user.id,
      'text': cleanText,
    });
  }

  static Future<void> sendImageMessage(String chatId, String imageUrl) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': user.id,
      'image_url': imageUrl,
    });
  }

  static Future<void> markChatAsRead(String chatId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('chat_id', chatId)
        .neq('sender_id', user.id);
  }

  static Future<void> fetchUnreadMessageCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final response = await _client
        .from('messages')
        .select()
        .eq('is_read', false)
        .neq('sender_id', user.id)
        .count(CountOption.exact);
    messageBadgeCount.value = response.count;
  }

  static Future<void> markAllMessagesAsRead() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('is_read', false)
        .neq('sender_id', user.id);
  }

  static Future<void> deleteMessage(String messageId, String chatId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('messages')
        .delete()
        .eq('id', messageId)
        .eq('sender_id', user.id); // 🔐 IDOR Protection: only sender can delete
  }

  static Future<void> deleteChat(String chatId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // 🔐 IDOR Protection: Ensure user is a participant before allowing delete
    final chat = await _client.from('chats').select('user1_id, user2_id').eq('id', chatId).maybeSingle();
    if (chat == null) return;
    if (chat['user1_id'] != user.id && chat['user2_id'] != user.id) {
       AppLogger.logSuspiciousActivity(event: 'IDOR_BLOCKED', details: 'Unauthorized chat delete attempt on $chatId');
       return; 
    }

    // Perform a real hard delete from Supabase as requested
    await _client.from('chats').delete().eq('id', chatId);
  }
}
