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
  Future<List<Reply>> getReplies({required int postId, required int page}) async {
    try {
      final replies = await remote.getReplies(postId, page);
      for (final r in replies) {
        await local.upsertReply(r);
      }
      return replies;
    } catch (_) {
      return await local.getReplies(postId: postId, page: page);
    }
  }

  @override
  Future<Reply> createReply(Reply reply) async {
    final model = ReplyModel(
      id: reply.id,
      postId: reply.postId,
      content: reply.content,
      author: reply.author,
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
}

