import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VoteRepository {
  static final _client = Supabase.instance.client;

  /// Get total vote count for a user
  static Future<int> getVoteCount(String targetId) async {
    try {
      final baseVotes = _getBaseVotes(targetId);
      final response = await _client
          .from('user_votes')
          .select('id')
          .eq('target_id', targetId);
      final count = (response as List).length;
      return baseVotes + count;
    } catch (e) {
      debugPrint('Error fetching vote count: $e');
      return _getBaseVotes(targetId);
    }
  }

  static int _getBaseVotes(String userId) {
    // Generate a stable number between 50 and 1000 based on userId
    final int hash = userId.hashCode.abs();
    return 50 + (hash % 951); // 50 to 1000
  }

  /// Check if the current user has already voted for this target
  static Future<bool> hasVoted(String targetId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    try {
      final response = await _client
          .from('user_votes')
          .select('id')
          .eq('voter_id', user.id)
          .eq('target_id', targetId);
      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint('Error checking vote: $e');
      return false;
    }
  }

  /// Cast a vote for a user (cannot vote for yourself)
  static Future<bool> castVote(String targetId) async {
    final user = _client.auth.currentUser;
    if (user == null || user.id == targetId) return false;
    try {
      await _client.from('user_votes').insert({
        'voter_id': user.id,
        'target_id': targetId,
      });
      return true;
    } catch (e) {
      debugPrint('Error casting vote: $e');
      return false;
    }
  }

  /// Remove a vote
  static Future<bool> removeVote(String targetId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    try {
      await _client
          .from('user_votes')
          .delete()
          .eq('voter_id', user.id)
          .eq('target_id', targetId);
      return true;
    } catch (e) {
      debugPrint('Error removing vote: $e');
      return false;
    }
  }

  /// Toggle vote — returns new hasVoted state
  static Future<({bool hasVoted, int count})> toggleVote(
      String targetId, int currentCount, bool currentlyVoted) async {
    if (currentlyVoted) {
      final success = await removeVote(targetId);
      if (success) {
        return (hasVoted: false, count: currentCount - 1);
      }
    } else {
      final success = await castVote(targetId);
      if (success) {
        return (hasVoted: true, count: currentCount + 1);
      }
    }
    return (hasVoted: currentlyVoted, count: currentCount);
  }
}
