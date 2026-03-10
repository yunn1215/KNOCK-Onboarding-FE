import 'package:dio/dio.dart';

import '../../domain/entities/post_search_filter.dart';
import '../models/post_model.dart';

class PostRemoteDataSource {
  final Dio dio;
  PostRemoteDataSource(this.dio);

  Future<List<PostModel>> getPosts([PostSearchFilter filter = PostSearchFilter.empty]) async {
    final params = <String, dynamic>{
      '_sort': 'createdAt',
      '_order': 'desc',
    };
    final search = filter.search?.trim();
    if (filter.type != null && filter.type != 'all') {
      params['type'] = filter.type;
    }
    if (filter.author != null && filter.author!.isNotEmpty) {
      params['author'] = filter.author;
    }
    if (filter.dateFrom != null) {
      params['createdAt_gte'] = filter.dateFrom!.toIso8601String();
    }
    if (filter.dateTo != null) {
      params['createdAt_lte'] = filter.dateTo!.toIso8601String();
    }
    final response = await dio.get('/posts', queryParameters: params);
    var list = (response.data as List).map((e) => PostModel.fromJson(e)).toList();
    if (search != null && search.isNotEmpty) {
      final lower = search.toLowerCase();
      list = list.where((p) {
        return p.title.toLowerCase().contains(lower) ||
            p.content.toLowerCase().contains(lower);
      }).toList();
    }
    return list;
  }

  Future<PostModel> getPost(int id) async {
    final response = await dio.get('/posts/$id');
    return PostModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PostModel> createPost(PostModel post) async {
    final response = await dio.post('/posts', data: post.toJson());
    return PostModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PostModel> updatePost(PostModel post) async {
    final response = await dio.patch('/posts/${post.id}', data: post.toJson());
    return PostModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePost(int id) async {
    await dio.delete('/posts/$id');
  }

  Future<PostModel> likePost(int id) async {
    final model = await getPost(id);
    final newLikedBy = List<String>.from(model.likedBy);
    if (!newLikedBy.contains('me')) {
      newLikedBy.add('me');
    }
    final body = model.toJson()
      ..['likeCount'] = newLikedBy.length
      ..['likedBy'] = newLikedBy;
    final response = await dio.patch('/posts/$id', data: body);
    return PostModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PostModel> unlikePost(int id) async {
    final model = await getPost(id);
    final newLikedBy = List<String>.from(model.likedBy)..remove('me');
    final body = model.toJson()
      ..['likeCount'] = newLikedBy.length
      ..['likedBy'] = newLikedBy;
    final response = await dio.patch('/posts/$id', data: body);
    return PostModel.fromJson(response.data as Map<String, dynamic>);
  }
}

