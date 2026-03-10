import 'package:dio/dio.dart';
import '../models/reply_model.dart';

class ReplyRemoteDataSource {
  final Dio dio;

  ReplyRemoteDataSource(this.dio);

  /// Returns (replies for page, total count from X-Total-Count header if present).
  Future<(List<ReplyModel>, int?)> getReplies(int postId, int page) async {
    final response = await dio.get(
      '/replies',
      queryParameters: {'postId': postId, '_page': page, '_limit': 10},
    );

    final list =
        (response.data as List).map((e) => ReplyModel.fromJson(e)).toList();
    final totalStr = response.headers.value('x-total-count');
    final total =
        totalStr != null ? int.tryParse(totalStr) : null;
    return (list, total);
  }

  Future<void> createReply(ReplyModel reply) async {
    await dio.post('/replies', data: reply.toJson());
  }

  Future<void> deleteReply(int id) async {
    await dio.delete('/replies/$id');
  }

  Future<void> updateReply(ReplyModel reply) async {
    await dio.patch('/replies/${reply.id}', data: reply.toJson());
  }

  Future<ReplyModel> getReply(int id) async {
    final response = await dio.get('/replies/$id');
    return ReplyModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ReplyModel> likeReply(int id) async {
    final reply = await getReply(id);
    final newLikedBy = List<String>.from(reply.likedBy);
    if (!newLikedBy.contains('me')) {
      newLikedBy.add('me');
    }
    final body = reply.toJson()
      ..['likeCount'] = newLikedBy.length
      ..['likedBy'] = newLikedBy;
    final response = await dio.patch('/replies/$id', data: body);
    return ReplyModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ReplyModel> unlikeReply(int id) async {
    final reply = await getReply(id);
    final newLikedBy = List<String>.from(reply.likedBy)..remove('me');
    final body = reply.toJson()
      ..['likeCount'] = newLikedBy.length
      ..['likedBy'] = newLikedBy;
    final response = await dio.patch('/replies/$id', data: body);
    return ReplyModel.fromJson(response.data as Map<String, dynamic>);
  }
}
