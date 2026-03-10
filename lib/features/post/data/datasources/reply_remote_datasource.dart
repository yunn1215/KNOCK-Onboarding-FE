import 'package:dio/dio.dart';
import '../models/reply_model.dart';

class ReplyRemoteDataSource {
  final Dio dio;

  ReplyRemoteDataSource(this.dio);

  Future<List<ReplyModel>> getReplies(int postId, int page) async {
    final response = await dio.get(
      '/replies',
      queryParameters: {'postId': postId, '_page': page, '_limit': 10},
    );

    return (response.data as List).map((e) => ReplyModel.fromJson(e)).toList();
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
}
