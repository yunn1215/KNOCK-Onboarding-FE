import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/post.dart';
import '../../domain/entities/post_search_filter.dart';
import '../../data/datasources/post_local_datasource.dart';
import '../../domain/repositories/post_repository.dart';

/// ---------------- EVENTS ----------------

abstract class PostEvent {}

class LoadPosts extends PostEvent {
  final PostSearchFilter filter;
  LoadPosts([this.filter = PostSearchFilter.empty]);
}

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

class TogglePostLike extends PostEvent {
  final Post post;
  TogglePostLike(this.post);
}

/// ---------------- STATES ----------------

abstract class PostState {}

class PostInitial extends PostState {}

class PostLoaded extends PostState {
  final List<Post> posts;
  final PostSearchFilter appliedFilter;
  PostLoaded(this.posts, [this.appliedFilter = PostSearchFilter.empty]);
}

/// ---------------- BLOC ----------------

class PostBloc extends Bloc<PostEvent, PostState> {
  final PostRepository repository;
  final PostLocalDataSource localDataSource;

  // 검색 UX 개선용 캐시:
  // 검색 시작 직전(검색어 없음) 목록을 저장해두고,
  // 검색창이 비면 네트워크 응답을 기다리지 않고 즉시 복구한다.
  List<Post>? _lastNonSearchPosts;
  PostSearchFilter? _lastNonSearchFilter;

  PostBloc({required this.repository, PostLocalDataSource? localDataSource})
    : localDataSource = localDataSource ?? PostLocalDataSource(),
      super(PostInitial()) {
    on<LoadPosts>(_onLoadPosts);
    on<AddPost>(_onAddPost);
    on<DeletePost>(_onDeletePost);
    on<UpdatePost>(_onUpdatePost);
    on<TogglePostLike>(_onTogglePostLike);
  }

  Future<void> _onLoadPosts(LoadPosts event, Emitter<PostState> emit) async {
    final requested = _normalizeFilter(event.filter);

    final current = state;
    if (current is PostLoaded) {
      // 검색을 "시작"하는 순간(검색어 없음 → 있음) 직전 목록을 캐시.
      final currentFilter = _normalizeFilter(current.appliedFilter);
      final currentHasSearch = (currentFilter.search?.trim().isNotEmpty ?? false);
      final requestedHasSearch = (requested.search?.trim().isNotEmpty ?? false);
      if (!currentHasSearch && requestedHasSearch) {
        _lastNonSearchPosts = current.posts;
        _lastNonSearchFilter = currentFilter.copyWith(clearSearch: true);
      }

      // 검색어가 비면 즉시 캐시로 복구(UX: 지우는 만큼 바로 취소).
      final requestedIsClearedSearch = requested.search == null;
      if (requestedIsClearedSearch &&
          _lastNonSearchPosts != null &&
          _lastNonSearchFilter != null &&
          _sameBaseFilter(_lastNonSearchFilter!, requested)) {
        emit(PostLoaded(_lastNonSearchPosts!, requested));
      }
    }

    final posts = await repository.getPosts(requested);
    emit(PostLoaded(posts, requested));

    // 검색어가 없는 결과는 캐시 갱신
    if (requested.search == null) {
      _lastNonSearchPosts = posts;
      _lastNonSearchFilter = requested;
    }
  }

  PostSearchFilter _normalizeFilter(PostSearchFilter f) {
    final search = f.search?.trim();
    if (search == null || search.isEmpty) {
      return f.copyWith(clearSearch: true);
    }
    return f.copyWith(search: search);
  }

  bool _sameBaseFilter(PostSearchFilter a, PostSearchFilter b) {
    // search는 비교에서 제외(= base 조건만).
    return (a.type ?? 'all') == (b.type ?? 'all') &&
        (a.author ?? '') == (b.author ?? '') &&
        a.dateFrom == b.dateFrom &&
        a.dateTo == b.dateTo;
  }

  Future<void> _onAddPost(AddPost event, Emitter<PostState> emit) async {
    final currentState = state;

    if (currentState is PostLoaded) {
      final created = await repository.createPost(event.post);
      final updatedList = List<Post>.from(currentState.posts)..add(created);
      emit(PostLoaded(updatedList, currentState.appliedFilter));
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
    emit(PostLoaded(updatedList, currentState.appliedFilter));
  }

  Future<void> _onUpdatePost(UpdatePost event, Emitter<PostState> emit) async {
    final currentState = state;
    if (currentState is! PostLoaded) return;

    final idx = currentState.posts.indexWhere((p) => p.id == event.post.id);
    if (idx == -1) return;

    final old = currentState.posts[idx];
    if (old.author != event.requester) return;

    final updatedList = List<Post>.from(currentState.posts);
    final updated = await repository.updatePost(event.post);
    updatedList[idx] = updated;
    emit(PostLoaded(updatedList, currentState.appliedFilter));
  }

  Future<void> _onTogglePostLike(TogglePostLike event, Emitter<PostState> emit) async {
    final currentState = state;
    if (currentState is! PostLoaded) return;

    final idx = currentState.posts.indexWhere((p) => p.id == event.post.id);
    if (idx == -1) return;

    final old = currentState.posts[idx];
    final optimisticPost = old.copyWith(
      likeCount: old.isLikedByMe ? old.likeCount - 1 : old.likeCount + 1,
      isLikedByMe: !old.isLikedByMe,
    );
    final previousList = List<Post>.from(currentState.posts);
    final optimisticList = List<Post>.from(currentState.posts);
    optimisticList[idx] = optimisticPost;
    emit(PostLoaded(optimisticList, currentState.appliedFilter));

    try {
      final updated = old.isLikedByMe
          ? await repository.unlikePost(event.post.id)
          : await repository.likePost(event.post.id);
      final now = state;
      if (now is PostLoaded && now.posts.length > idx && now.posts[idx].id == event.post.id) {
        final resultList = List<Post>.from(now.posts);
        resultList[idx] = updated;
        emit(PostLoaded(resultList, now.appliedFilter));
      }
    } catch (_) {
      emit(PostLoaded(previousList, currentState.appliedFilter));
    }
  }
}
