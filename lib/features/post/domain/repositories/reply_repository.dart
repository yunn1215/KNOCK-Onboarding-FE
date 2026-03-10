import '../entities/reply.dart';

abstract class ReplyRepository {
  Future<List<Reply>> getReplies({required int postId, required int page});
  Future<Reply> createReply(Reply reply);
  Future<void> deleteReply(int id);
  Future<Reply> updateReply(Reply reply);
}

