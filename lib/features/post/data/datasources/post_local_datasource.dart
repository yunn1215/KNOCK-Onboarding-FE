import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';

class PostLocalDataSource {
  static const String key = 'posts';

  Future<List<PostModel>> getPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);

    if (jsonString == null) return [];

    final List decoded = json.decode(jsonString);
    return decoded.map((e) => PostModel.fromJson(e)).toList();
  }

  Future<void> savePosts(List<PostModel> posts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString =
        json.encode(posts.map((e) => e.toJson()).toList());

    await prefs.setString(key, jsonString);
  }

  Future<PostModel?> getPost(int id) async {
    final posts = await getPosts();
    try {
      return posts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> upsertPost(PostModel post) async {
    final posts = await getPosts();
    final idx = posts.indexWhere((p) => p.id == post.id);
    if (idx == -1) {
      posts.add(post);
    } else {
      posts[idx] = post;
    }
    await savePosts(posts);
  }

  Future<void> deletePost(int id) async {
    final posts = await getPosts();
    final updated = posts.where((p) => p.id != id).toList();
    await savePosts(updated);
  }
}

