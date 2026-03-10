import '../entities/post.dart';
import '../entities/post_search_filter.dart';

abstract class PostRepository {
  Future<List<Post>> getPosts([PostSearchFilter filter = PostSearchFilter.empty]);
  Future<Post?> getPost(int id);
  Future<Post> createPost(Post post);
  Future<Post> updatePost(Post post);
  Future<void> deletePost(int id);
  Future<Post> likePost(int id);
  Future<Post> unlikePost(int id);
}

