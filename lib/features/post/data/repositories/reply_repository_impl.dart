import '../../domain/entities/reply.dart';
import '../../domain/repositories/reply_repository.dart';
import '../datasources/reply_local_datasource.dart';
import '../datasources/reply_remote_datasource.dart';
import '../models/reply_model.dart';

class ReplyRepositoryImpl implements ReplyRepository {
  final ReplyRemoteDataSource remote;
  final ReplyLocalDataSource local;

  ReplyRepositoryImpl({required this.remote, required this.local});

  @override
  Future<(List<Reply>, int?)> getReplies(
      {required int postId, required int page}) async {
    try {
      final (replies, total) = await remote.getReplies(postId, page);
      for (final r in replies) {
        await local.upsertReply(r);
      }
      return (replies, total);
    } catch (_) {
      final list =
          await local.getReplies(postId: postId, page: page);
      final count = await local.getReplyCount(postId);
      return (list, count);
    }
  }

  @override
  Future<Reply> createReply(Reply reply) async {
    final model = ReplyModel(
      id: reply.id,
      postId: reply.postId,
      content: reply.content,
      author: reply.author,
      createdAt: reply.createdAt ?? DateTime.now(),
    );
    try {
      await remote.createReply(model);
      await local.upsertReply(model);
      return model;
    } catch (_) {
      await local.upsertReply(model);
      return model;
    }
  }

  @override
  Future<void> deleteReply(int id) async {
    try {
      await remote.deleteReply(id);
    } catch (_) {
      // ignore
    } finally {
      await local.deleteReply(id);
    }
  }

  @override
  Future<Reply> updateReply(Reply reply) async {
    final model = ReplyModel(
      id: reply.id,
      postId: reply.postId,
      content: reply.content,
      author: reply.author,
      likeCount: reply.likeCount,
      isLikedByMe: reply.isLikedByMe,
      createdAt: reply.createdAt,
    );
    try {
      await remote.updateReply(model);
      await local.upsertReply(model);
      return model;
    } catch (_) {
      await local.upsertReply(model);
      return model;
    }
  }

  @override
  Future<Reply> likeReply(int id) async {
    final updated = await remote.likeReply(id);
    await local.upsertReply(updated);
    return updated;
  }

  @override
  Future<Reply> unlikeReply(int id) async {
    final updated = await remote.unlikeReply(id);
    await local.upsertReply(updated);
    return updated;
  }
}

