import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/post.dart';
import '../../data/datasources/post_local_datasource.dart';
import '../../data/models/post_model.dart';
import '../../domain/repositories/post_repository.dart';

/// ---------------- EVENTS ----------------

abstract class PostEvent {}

class LoadPosts extends PostEvent {}

class AddPost extends PostEvent {
  final Post post;
  AddPost(this.post);
}

class DeletePost extends PostEvent {
  final int id;
  final String requester; // 삭제 시도
  DeletePost(this.id, {required this.requester});
}

class UpdatePost extends PostEvent {
  final Post post;
  final String requester; // 수정 시도
  UpdatePost(this.post, {required this.requester});
}

/// ---------------- STATES ----------------

abstract class PostState {}

class PostInitial extends PostState {}

class PostLoaded extends PostState {
  final List<Post> posts;
  PostLoaded(this.posts);
}

/// ---------------- BLOC ----------------

class PostBloc extends Bloc<PostEvent, PostState> {
  final PostRepository repository;
  final PostLocalDataSource localDataSource;

  PostBloc({required this.repository, PostLocalDataSource? localDataSource})
    : localDataSource = localDataSource ?? PostLocalDataSource(),
      super(PostInitial()) {
    on<LoadPosts>(_onLoadPosts);
    on<AddPost>(_onAddPost);
    on<DeletePost>(_onDeletePost);
    on<UpdatePost>(_onUpdatePost);
  }

  Future<void> _onLoadPosts(LoadPosts event, Emitter<PostState> emit) async {
    final posts = await repository.getPosts();
  

    emit(PostLoaded(posts));
  }

  Future<void> _onAddPost(AddPost event, Emitter<PostState> emit) async {
    final currentState = state;

    if (currentState is PostLoaded) {
      final created = await repository.createPost(event.post);
      final updatedList = List<Post>.from(currentState.posts)..add(created);
      emit(PostLoaded(updatedList));
    }
  }

  Future<void> _onDeletePost(DeletePost event, Emitter<PostState> emit) async {
    final currentState = state;
    if (currentState is! PostLoaded) return;

    final target = currentState.posts.where((p) => p.id == event.id).toList();
    if (target.isEmpty) return;

    // 작성자만 삭제 가능
    if (target.first.author != event.requester) return;

    final updatedList = currentState.posts
        .where((p) => p.id != event.id)
        .toList();

    await repository.deletePost(event.id);

    emit(PostLoaded(updatedList));
  }

  Future<void> _onUpdatePost(UpdatePost event, Emitter<PostState> emit) async {
    final currentState = state;
    if (currentState is! PostLoaded) return;

    final idx = currentState.posts.indexWhere((p) => p.id == event.post.id);
    if (idx == -1) return;

    // 작성자만 수정 가능
    final old = currentState.posts[idx];
    if (old.author != event.requester) return;

    final updatedList = List<Post>.from(currentState.posts);
    final updated = await repository.updatePost(event.post);
    updatedList[idx] = updated;

    emit(PostLoaded(updatedList));
  }
}
