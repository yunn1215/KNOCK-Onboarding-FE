import '../entities/reply.dart';

abstract class ReplyRepository {
  /// Returns (replies for page, total count for post if known).
  Future<(List<Reply>, int?)> getReplies({required int postId, required int page});
  Future<Reply> createReply(Reply reply);
  Future<void> deleteReply(int id);
  Future<Reply> updateReply(Reply reply);
  Future<Reply> likeReply(int id);
  Future<Reply> unlikeReply(int id);
}

