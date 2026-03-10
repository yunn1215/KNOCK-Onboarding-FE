import '../../domain/entities/post.dart';
import '../../domain/entities/post_search_filter.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_local_datasource.dart';
import '../datasources/post_remote_datasource.dart';
import '../models/post_model.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remote;
  final PostLocalDataSource local;

  PostRepositoryImpl({required this.remote, required this.local});

  @override
  Future<List<Post>> getPosts([PostSearchFilter filter = PostSearchFilter.empty]) async {
    try {
      final posts = await remote.getPosts(filter);
      await local.savePosts(posts);
      return posts;
    } catch (_) {
      final all = await local.getPosts();
      return _applyFilter(all, filter);
    }
  }

  static List<Post> _applyFilter(List<Post> list, PostSearchFilter filter) {
    var result = list;
    final search = filter.search?.trim();
    if (search != null && search.isNotEmpty) {
      final lower = search.toLowerCase();
      result = result.where((p) {
        return p.title.toLowerCase().contains(lower) ||
            p.content.toLowerCase().contains(lower);
      }).toList();
    }
    if (filter.type != null && filter.type != 'all') {
      result = result.where((p) => p.type == filter.type).toList();
    }
    if (filter.author != null && filter.author!.isNotEmpty) {
      result = result.where((p) => p.author == filter.author).toList();
    }
    if (filter.dateFrom != null) {
      result = result.where((p) => p.createdAt.isAfter(filter.dateFrom!) || p.createdAt.isAtSameMomentAs(filter.dateFrom!)).toList();
    }
    if (filter.dateTo != null) {
      result = result.where((p) => p.createdAt.isBefore(filter.dateTo!) || p.createdAt.isAtSameMomentAs(filter.dateTo!)).toList();
    }
    return result;
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
      imageUrl: post.imageUrl,
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
    try {
      final current = await remote.getPost(post.id);
      final model = PostModel(
        id: post.id,
        title: post.title,
        content: post.content,
        type: post.type,
        author: post.author,
        createdAt: post.createdAt,
        likeCount: current.likeCount,
        isLikedByMe: current.isLikedByMe,
        imageUrl: post.imageUrl,
        likedBy: current.likedBy,
      );
      final updated = await remote.updatePost(model);
      await local.upsertPost(updated);
      return updated;
    } catch (_) {
      final model = PostModel(
        id: post.id,
        title: post.title,
        content: post.content,
        type: post.type,
        author: post.author,
        createdAt: post.createdAt,
        imageUrl: post.imageUrl,
      );
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

  @override
  Future<Post> likePost(int id) async {
    final updated = await remote.likePost(id);
    await local.upsertPost(updated);
    return updated;
  }

  @override
  Future<Post> unlikePost(int id) async {
    final updated = await remote.unlikePost(id);
    await local.upsertPost(updated);
    return updated;
  }
}

