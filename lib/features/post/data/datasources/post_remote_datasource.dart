import 'package:dio/dio.dart';
import '../models/post_model.dart';

class PostRemoteDataSource {
  final Dio dio;
  PostRemoteDataSource(this.dio);

  Future<List<PostModel>> getPosts() async {
    final response = await dio.get(
      '/posts',
      queryParameters: {'_sort': 'createdAt', '_order': 'desc'},
    );
    return (response.data as List).map((e) => PostModel.fromJson(e)).toList();
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
}

