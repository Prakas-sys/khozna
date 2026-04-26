import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/models/chat_model.dart';
import 'package:khozna/core/utils/app_notifiers.dart';

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

    // 4. Map to models
    return chatsData.map((e) {
      final u1 = e['user1_id']?.toString();
      final u2 = e['user2_id']?.toString();
      final otherId = (u1 != user.id) ? u1 : u2;
      final profile = profiles[otherId];
      
      return ChatConversation(
        id: e['id'],
        otherUserId: otherId ?? '',
        otherUserName: profile?['full_name'] ?? 'Khozna User',
        otherUserAvatar: profile?['avatar_url'] ?? '',
        lastMessage: e['last_message_text'],
        lastMessageTime: DateTime.parse(e['updated_at'] ?? DateTime.now().toIso8601String()).toLocal(),
        unreadCount: 0, // In a real app, calculate this or fetch from view
      );
    }).toList();
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

    if (response != null) return response['id'];

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
    await _client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': _client.auth.currentUser?.id,
      'text': text,
    });
  }

  static Future<void> sendImageMessage(String chatId, String imageUrl) async {
    await _client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': _client.auth.currentUser?.id,
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
    await _client.from('messages').update({'is_deleted': true}).eq('id', messageId);
  }

  static Future<void> deleteChat(String chatId) async {
    // In a real app, this might just hide it for one user
    await _client.from('messages').delete().eq('chat_id', chatId);
    await _client.from('chats').delete().eq('id', chatId);
  }
}
