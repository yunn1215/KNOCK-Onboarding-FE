import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/reply.dart';
import '../../domain/repositories/reply_repository.dart';

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

class LoadReplies extends PostDetailEvent {
  final bool reset;
  LoadReplies({this.reset = false});
}

class CreateReply extends PostDetailEvent {
  final String content;
  CreateReply(this.content);
}

class StartEditReply extends PostDetailEvent {
  final Reply reply;
  StartEditReply(this.reply);
}

class ChangeEditingReplyContent extends PostDetailEvent {
  final String content;
  ChangeEditingReplyContent(this.content);
}

class CancelEditReply extends PostDetailEvent {}

class SubmitUpdateReply extends PostDetailEvent {}

class DeleteReply extends PostDetailEvent {
  final int id;
  DeleteReply(this.id);
}

class ClearMessage extends PostDetailEvent {}

class PostDetailState extends Equatable {
  final Post post;
  final bool isEditing;
  final String title;
  final String content;
  final String type;

  final List<Reply> replies;
  final int replyPage;
  final bool hasMoreReplies;
  final bool isRepliesLoading;
  final bool isReplyActionLoading;

  final int? editingReplyId;
  final String editingReplyContent;

  final String? message;

  bool get isMine => post.author == 'me';

  const PostDetailState({
    required this.post,
    required this.isEditing,
    required this.title,
    required this.content,
    required this.type,
    required this.replies,
    required this.replyPage,
    required this.hasMoreReplies,
    required this.isRepliesLoading,
    required this.isReplyActionLoading,
    required this.editingReplyId,
    required this.editingReplyContent,
    required this.message,
  });

  factory PostDetailState.initial(Post post) => PostDetailState(
    post: post,
    isEditing: false,
    title: post.title,
    content: post.content,
    type: post.type,
    replies: const [],
    replyPage: 0,
    hasMoreReplies: true,
    isRepliesLoading: false,
    isReplyActionLoading: false,
    editingReplyId: null,
    editingReplyContent: '',
    message: null,
  );

  PostDetailState copyWith({
    Post? post,
    bool? isEditing,
    String? title,
    String? content,
    String? type,
    List<Reply>? replies,
    int? replyPage,
    bool? hasMoreReplies,
    bool? isRepliesLoading,
    bool? isReplyActionLoading,
    Object? editingReplyId = _unset,
    String? editingReplyContent,
    Object? message = _unset,
  }) {
    return PostDetailState(
      post: post ?? this.post,
      isEditing: isEditing ?? this.isEditing,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      replies: replies ?? this.replies,
      replyPage: replyPage ?? this.replyPage,
      hasMoreReplies: hasMoreReplies ?? this.hasMoreReplies,
      isRepliesLoading: isRepliesLoading ?? this.isRepliesLoading,
      isReplyActionLoading: isReplyActionLoading ?? this.isReplyActionLoading,
      editingReplyId: editingReplyId == _unset ? this.editingReplyId : editingReplyId as int?,
      editingReplyContent: editingReplyContent ?? this.editingReplyContent,
      message: message == _unset ? this.message : message as String?,
    );
  }

  @override
  List<Object?> get props => [
    post,
    isEditing,
    title,
    content,
    type,
    replies,
    replyPage,
    hasMoreReplies,
    isRepliesLoading,
    isReplyActionLoading,
    editingReplyId,
    editingReplyContent,
    message,
  ];
}

const Object _unset = Object();

class PostDetailBloc extends Bloc<PostDetailEvent, PostDetailState> {
  final ReplyRepository replyRepository;

  PostDetailBloc({required this.replyRepository, required Post post})
    : super(PostDetailState.initial(post)) {
    on<InitPostDetail>(_onInit);
    on<ToggleEditMode>(_onToggleEditMode);
    on<ChangeTitle>((e, emit) => emit(state.copyWith(title: e.title)));
    on<ChangeContent>((e, emit) => emit(state.copyWith(content: e.content)));
    on<ChangeType>((e, emit) => emit(state.copyWith(type: e.type)));
    on<LoadReplies>(_onLoadReplies);
    on<CreateReply>(_onCreateReply);
    on<StartEditReply>(_onStartEditReply);
    on<ChangeEditingReplyContent>(
      (e, emit) => emit(state.copyWith(editingReplyContent: e.content)),
    );
    on<CancelEditReply>(
      (e, emit) => emit(state.copyWith(editingReplyId: null, message: null)),
    );
    on<SubmitUpdateReply>(_onSubmitUpdateReply);
    on<DeleteReply>(_onDeleteReply);
    on<ClearMessage>((e, emit) => emit(state.copyWith(message: null)));

    add(LoadReplies(reset: true));
  }

  Future<void> _onInit(InitPostDetail event, Emitter<PostDetailState> emit) async {
    emit(PostDetailState.initial(event.post));
    add(LoadReplies(reset: true));
  }

  void _onToggleEditMode(ToggleEditMode event, Emitter<PostDetailState> emit) {
    if (!state.isEditing) {
      emit(
        state.copyWith(
          isEditing: true,
          title: state.post.title,
          content: state.post.content,
          type: state.post.type,
        ),
      );
      return;
    }
    emit(state.copyWith(isEditing: false));
  }

  Future<void> _onLoadReplies(LoadReplies event, Emitter<PostDetailState> emit) async {
    if (state.isRepliesLoading) return;
    if (!event.reset && !state.hasMoreReplies) return;

    final nextPage = event.reset ? 1 : state.replyPage + 1;

    emit(
      state.copyWith(
        isRepliesLoading: true,
        message: null,
        replies: event.reset ? [] : state.replies,
        replyPage: event.reset ? 0 : state.replyPage,
        hasMoreReplies: event.reset ? true : state.hasMoreReplies,
      ),
    );

    try {
      final fetched = await replyRepository.getReplies(
        postId: state.post.id,
        page: nextPage,
      );

      final existingIds = state.replies.map((e) => e.id).toSet();
      final merged = [
        ...state.replies,
        ...fetched.where((r) => !existingIds.contains(r.id)),
      ];

      emit(
        state.copyWith(
          isRepliesLoading: false,
          replies: merged,
          replyPage: nextPage,
          hasMoreReplies: fetched.length == 10,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isRepliesLoading: false,
          message: '댓글을 불러오지 못했어요(오프라인이면 로컬 데이터를 보여줄게요).',
        ),
      );
    }
  }

  Future<void> _onCreateReply(CreateReply event, Emitter<PostDetailState> emit) async {
    final text = event.content.trim();
    if (text.isEmpty) {
      emit(state.copyWith(message: '댓글을 1자 이상 입력하세요.'));
      return;
    }
    if (state.isReplyActionLoading) return;

    emit(state.copyWith(isReplyActionLoading: true, message: null));
    try {
      final reply = Reply(
        id: DateTime.now().microsecondsSinceEpoch,
        postId: state.post.id,
        content: text,
        author: 'me',
      );
      await replyRepository.createReply(reply);
      emit(state.copyWith(isReplyActionLoading: false, message: '댓글이 등록됐어요.'));
      add(LoadReplies(reset: true));
    } catch (_) {
      emit(state.copyWith(isReplyActionLoading: false, message: '댓글 작성에 실패했어요.'));
    }
  }

  void _onStartEditReply(StartEditReply event, Emitter<PostDetailState> emit) {
    if (event.reply.author != 'me') {
      emit(state.copyWith(message: '본인 댓글만 수정할 수 있어요.'));
      return;
    }
    emit(
      state.copyWith(
        editingReplyId: event.reply.id,
        editingReplyContent: event.reply.content,
        message: null,
      ),
    );
  }

  Future<void> _onSubmitUpdateReply(
    SubmitUpdateReply event,
    Emitter<PostDetailState> emit,
  ) async {
    final id = state.editingReplyId;
    if (id == null) return;

    final text = state.editingReplyContent.trim();
    if (text.isEmpty) {
      emit(state.copyWith(message: '댓글은 1자 이상 입력해주세요.'));
      return;
    }

    final targetIdx = state.replies.indexWhere((r) => r.id == id);
    if (targetIdx == -1) {
      emit(state.copyWith(editingReplyId: null, message: null));
      return;
    }

    final old = state.replies[targetIdx];
    if (old.author != 'me') {
      emit(state.copyWith(message: '본인 댓글만 수정할 수 있어요.'));
      return;
    }

    if (state.isReplyActionLoading) return;
    emit(state.copyWith(isReplyActionLoading: true, message: null));

    try {
      final updated = Reply(
        id: old.id,
        postId: old.postId,
        content: text,
        author: old.author,
      );
      await replyRepository.updateReply(updated);

      final newList = List<Reply>.from(state.replies);
      newList[targetIdx] = updated;

      emit(
        state.copyWith(
          isReplyActionLoading: false,
          replies: newList,
          editingReplyId: null,
          message: '댓글이 수정됐어요.',
        ),
      );
    } catch (_) {
      emit(state.copyWith(isReplyActionLoading: false, message: '댓글 수정에 실패했어요.'));
    }
  }

  Future<void> _onDeleteReply(DeleteReply event, Emitter<PostDetailState> emit) async {
    final target = state.replies.where((r) => r.id == event.id).toList();
    if (target.isEmpty) return;
    if (target.first.author != 'me') {
      emit(state.copyWith(message: '본인 댓글만 삭제할 수 있어요.'));
      return;
    }
    if (state.isReplyActionLoading) return;

    emit(state.copyWith(isReplyActionLoading: true, message: null));
    try {
      await replyRepository.deleteReply(event.id);
      final updatedReplies = state.replies.where((r) => r.id != event.id).toList();
      emit(
        state.copyWith(
          isReplyActionLoading: false,
          replies: updatedReplies,
          message: '댓글이 삭제됐어요.',
        ),
      );
    } catch (_) {
      emit(state.copyWith(isReplyActionLoading: false, message: '댓글 삭제에 실패했어요.'));
    }
  }
}
