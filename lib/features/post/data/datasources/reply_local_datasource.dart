import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reply_model.dart';

class ReplyLocalDataSource {
  static const String key = 'replies';

  Future<List<ReplyModel>> _getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString == null) return [];

    final List decoded = json.decode(jsonString);
    return decoded.map((e) => ReplyModel.fromJson(e)).toList();
  }

  Future<void> _saveAll(List<ReplyModel> replies) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(replies.map((e) => e.toJson()).toList());
    await prefs.setString(key, jsonString);
  }

  Future<List<ReplyModel>> getReplies({
    required int postId,
    required int page,
    int limit = 10,
  }) async {
    final all = await _getAll();
    final filtered = all.where((r) => r.postId == postId).toList()
      ..sort((a, b) => b.id.compareTo(a.id));

    final start = (page - 1) * limit;
    if (start >= filtered.length) return [];
    final end = (start + limit).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  Future<void> upsertReply(ReplyModel reply) async {
    final all = await _getAll();
    final idx = all.indexWhere((r) => r.id == reply.id);
    if (idx == -1) {
      all.add(reply);
    } else {
      all[idx] = reply;
    }
    await _saveAll(all);
  }

  Future<void> deleteReply(int id) async {
    final all = await _getAll();
    final updated = all.where((r) => r.id != id).toList();
    await _saveAll(updated);
  }

  Future<void> replaceRepliesForPost(int postId, List<ReplyModel> replies) async {
    final all = await _getAll();
    final keepOtherPosts = all.where((r) => r.postId != postId).toList();
    await _saveAll([...keepOtherPosts, ...replies]);
  }
}

