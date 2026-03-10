import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_local_datasource.dart';
import '../datasources/post_remote_datasource.dart';
import '../models/post_model.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remote;
  final PostLocalDataSource local;

  PostRepositoryImpl({required this.remote, required this.local});

  @override
  Future<List<Post>> getPosts() async {
    try {
      final posts = await remote.getPosts();
      await local.savePosts(posts);
      return posts;
    } catch (_) {
      return await local.getPosts();
    }
  }

  @override
  Future<Post?> getPost(int id) async {
    try {
      final post = await remote.getPost(id);
      await local.upsertPost(post);
      return post;
    } catch (_) {
      return await local.getPost(id);
    }
  }

  @override
  Future<Post> createPost(Post post) async {
    final model = PostModel(
      id: post.id,
      title: post.title,
      content: post.content,
      type: post.type,
      author: post.author,
      createdAt: post.createdAt,
    );

    try {
      final created = await remote.createPost(model);
      await local.upsertPost(created);
      return created;
    } catch (_) {
      await local.upsertPost(model);
      return model;
    }
  }

  @override
  Future<Post> updatePost(Post post) async {
    final model = PostModel(
      id: post.id,
      title: post.title,
      content: post.content,
      type: post.type,
      author: post.author,
      createdAt: post.createdAt,
    );

    try {
      final updated = await remote.updatePost(model);
      await local.upsertPost(updated);
      return updated;
    } catch (_) {
      await local.upsertPost(model);
      return model;
    }
  }

  @override
  Future<void> deletePost(int id) async {
    try {
      await remote.deletePost(id);
    } catch (_) {
      // ignore - fallback to local only
    } finally {
      await local.deletePost(id);
    }
  }
}

