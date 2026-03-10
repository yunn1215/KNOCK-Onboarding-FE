import '../entities/post.dart';

abstract class PostRepository {
  Future<List<Post>> getPosts();
  Future<Post?> getPost(int id);
  Future<Post> createPost(Post post);
  Future<Post> updatePost(Post post);
  Future<void> deletePost(int id);
  Future<Post> likePost(int id);
  Future<Post> unlikePost(int id);
}

