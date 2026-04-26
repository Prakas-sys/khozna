import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khozna/core/models/chat_model.dart';
import 'package:khozna/core/utils/app_notifiers.dart';

class ChatRepository {
  static final _client = Supabase.instance.client;

  static Future<List<ChatConversation>> getConversations() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('chats')
        .select('*, user1:user1_id(full_name, avatar_url), user2:user2_id(full_name, avatar_url)')
        .or('user1_id.eq.${user.id},user2_id.eq.${user.id}')
        .order('updated_at', ascending: false);

    return (response as List).map((e) => ChatConversation.fromMap(e, user.id)).toList();
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
        .select('id', count: CountOption.exact)
        .eq('is_read', false)
        .neq('sender_id', user.id);
    unreadMessageCount.value = response.count;
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
