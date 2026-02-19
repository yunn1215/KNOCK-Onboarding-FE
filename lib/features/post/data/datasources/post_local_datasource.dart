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
}

