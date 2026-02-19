import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/post.dart';
import '../../data/datasources/post_local_datasource.dart';
import '../../data/models/post_model.dart';

/// ---------------- EVENTS ----------------

abstract class PostEvent {}

class LoadPosts extends PostEvent {}

class AddPost extends PostEvent {
  final Post post;
  AddPost(this.post);
}

class DeletePost extends PostEvent {
  final String id;
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
  final PostLocalDataSource dataSource = PostLocalDataSource();

  PostBloc() : super(PostInitial()) {
    on<LoadPosts>(_onLoadPosts);
    on<AddPost>(_onAddPost);
    on<DeletePost>(_onDeletePost);
    on<UpdatePost>(_onUpdatePost);
  }

  Future<void> _onLoadPosts(LoadPosts event, Emitter<PostState> emit) async {
    final posts = await dataSource.getPosts();

    // ✅ 첫 실행(저장된 글이 없을 때)만 목데이터 넣고 저장
    if (posts.isEmpty) {
      final seed = [
        PostModel(
          id: '1',
          title: 'Knock 온보딩 미션 질문 있어요',
          content: 'BLoC 구조를 어떻게 잡는 게 제일 깔끔할까요?',
          type: 'question',
          author: 'other',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        PostModel(
          id: '2',
          title: '게시글 예시: 회의 공지',
          content: '내일 2시에 킥오프 있습니다. 참여 부탁드려요!',
          type: 'post',
          author: 'me',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        PostModel(
          id: '3',
          title: '질문: shared_preferences 말고 뭐 써요?',
          content: '로컬 저장소는 보통 Hive/Isar도 많이 쓰나요?',
          type: 'question',
          author: 'other',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

      await dataSource.savePosts(seed);
      emit(PostLoaded(seed));
      return;
    }

    emit(PostLoaded(posts));
  }

  Future<void> _onAddPost(AddPost event, Emitter<PostState> emit) async {
    final currentState = state;

    if (currentState is PostLoaded) {
      final updatedList = List<Post>.from(currentState.posts)..add(event.post);

      await dataSource.savePosts(
        updatedList
            .map(
              (e) => PostModel(
                id: e.id,
                title: e.title,
                content: e.content,
                type: e.type,
                author: e.author,
                createdAt: e.createdAt,
              ),
            )
            .toList(),
      );

      emit(PostLoaded(updatedList));
    }
  }

  Future<void> _onDeletePost(DeletePost event, Emitter<PostState> emit) async {
    final currentState = state;
    if (currentState is! PostLoaded) return;

    final target = currentState.posts.where((p) => p.id == event.id).toList();
    if (target.isEmpty) return;

    // ✅ 작성자만 삭제 가능
    if (target.first.author != event.requester) return;

    final updatedList = currentState.posts
        .where((p) => p.id != event.id)
        .toList();

    await dataSource.savePosts(
      updatedList
          .map(
            (e) => PostModel(
              id: e.id,
              title: e.title,
              content: e.content,
              type: e.type,
              author: e.author,
              createdAt: e.createdAt,
            ),
          )
          .toList(),
    );

    emit(PostLoaded(updatedList));
  }

  Future<void> _onUpdatePost(UpdatePost event, Emitter<PostState> emit) async {
    final currentState = state;
    if (currentState is! PostLoaded) return;

    final idx = currentState.posts.indexWhere((p) => p.id == event.post.id);
    if (idx == -1) return;

    // ✅ 작성자만 수정 가능
    final old = currentState.posts[idx];
    if (old.author != event.requester) return;

    final updatedList = List<Post>.from(currentState.posts);
    updatedList[idx] = event.post;

    await dataSource.savePosts(
      updatedList
          .map(
            (e) => PostModel(
              id: e.id,
              title: e.title,
              content: e.content,
              type: e.type,
              author: e.author,
              createdAt: e.createdAt,
            ),
          )
          .toList(),
    );

    emit(PostLoaded(updatedList));
  }
}
