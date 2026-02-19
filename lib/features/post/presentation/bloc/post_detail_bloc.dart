import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/post.dart';

/// Events
abstract class PostDetailEvent {}

class InitPostDetail extends PostDetailEvent {
  final Post post;
  InitPostDetail(this.post);
}

class ToggleEditMode extends PostDetailEvent {}

class ChangeTitle extends PostDetailEvent {
  final String title;
  ChangeTitle(this.title);
}

class ChangeContent extends PostDetailEvent {
  final String content;
  ChangeContent(this.content);
}

class ChangeType extends PostDetailEvent {
  final String type; // post | question
  ChangeType(this.type);
}

/// State
class PostDetailState {
  final Post post;
  final bool isEditing;
  final String title;
  final String content;
  final String type;

  bool get isMine => post.author == 'me';

  PostDetailState({
    required this.post,
    required this.isEditing,
    required this.title,
    required this.content,
    required this.type,
  });

  PostDetailState copyWith({
    Post? post,
    bool? isEditing,
    String? title,
    String? content,
    String? type,
  }) {
    return PostDetailState(
      post: post ?? this.post,
      isEditing: isEditing ?? this.isEditing,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
    );
  }
}

/// Bloc
class PostDetailBloc extends Bloc<PostDetailEvent, PostDetailState> {
  PostDetailBloc(Post post)
    : super(
        PostDetailState(
          post: post,
          isEditing: false,
          title: post.title,
          content: post.content,
          type: post.type,
        ),
      ) {
    on<InitPostDetail>((event, emit) {
      emit(
        PostDetailState(
          post: event.post,
          isEditing: false,
          title: event.post.title,
          content: event.post.content,
          type: event.post.type,
        ),
      );
    });

    on<ToggleEditMode>((event, emit) {
      // 편집 모드 들어갈 때 최신 post 값 기준으로 편집값 리셋
      if (!state.isEditing) {
        emit(
          state.copyWith(
            isEditing: true,
            title: state.post.title,
            content: state.post.content,
            type: state.post.type,
          ),
        );
      } else {
        emit(state.copyWith(isEditing: false));
      }
    });

    on<ChangeTitle>((event, emit) => emit(state.copyWith(title: event.title)));
    on<ChangeContent>(
      (event, emit) => emit(state.copyWith(content: event.content)),
    );
    on<ChangeType>((event, emit) => emit(state.copyWith(type: event.type)));
  }
}
