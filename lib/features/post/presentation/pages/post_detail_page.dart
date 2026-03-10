import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/post_image.dart';
import '../../data/datasources/reply_local_datasource.dart';
import '../../data/datasources/reply_remote_datasource.dart';
import '../../data/repositories/reply_repository_impl.dart';
import '../../domain/entities/post.dart';
import '../bloc/post_bloc.dart';
import '../bloc/post_detail_bloc.dart';

class PostDetailPage extends StatelessWidget {
  final Post post;
  const PostDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final dio = ApiClient.create();
        final replyRepository = ReplyRepositoryImpl(
          remote: ReplyRemoteDataSource(dio),
          local: ReplyLocalDataSource(),
        );
        return PostDetailBloc(replyRepository: replyRepository, post: post);
      },
      child: _PostDetailView(post: post),
    );
  }
}

class _PostDetailView extends StatefulWidget {
  final Post post;
  const _PostDetailView({required this.post});

  @override
  State<_PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<_PostDetailView> {
  final _scrollCtrl = ScrollController();
  final _replyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final position = _scrollCtrl.position;
      final max = position.maxScrollExtent;
      final now = position.pixels;
      if (now >= 80 && max - now < 240) {
        context.read<PostDetailBloc>().add(LoadReplies());
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PostBloc, PostState>(
      listenWhen: (prev, next) => next is PostLoaded,
      listener: (context, postState) {
        if (postState is! PostLoaded) return;
        final detailBloc = context.read<PostDetailBloc>();
        final currentPostId = detailBloc.state.post.id;
        final updated = postState.posts.where((p) => p.id == currentPostId).firstOrNull;
        final current = detailBloc.state.post;
        if (updated != null &&
            (updated.likeCount != current.likeCount || updated.isLikedByMe != current.isLikedByMe)) {
          detailBloc.add(InitPostDetail(updated));
        }
      },
      child: BlocListener<PostDetailBloc, PostDetailState>(
        listenWhen: (prev, next) => prev.message != next.message && next.message != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
          context.read<PostDetailBloc>().add(ClearMessage());
        },
        child: BlocBuilder<PostDetailBloc, PostDetailState>(
        builder: (context, state) {
          final detailBloc = context.read<PostDetailBloc>();

          return Scaffold(
            appBar: AppBar(
              title: Text(state.isEditing ? '게시글 수정' : '게시글 상세'),
              actions: [
                if (state.isMine && !state.isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => detailBloc.add(ToggleEditMode()),
                  ),

                if (state.isMine && state.isEditing)
                  TextButton(
                    onPressed: () {
                      final imageUrl = state.editingImageUrl == null
                          ? state.post.imageUrl
                          : (state.editingImageUrl!.isEmpty ? null : state.editingImageUrl);
                      final updated = Post(
                        id: state.post.id,
                        title: state.title.trim(),
                        content: state.content.trim(),
                        type: state.type,
                        author: state.post.author,
                        createdAt: state.post.createdAt,
                        imageUrl: imageUrl,
                      );

                      if (updated.title.isEmpty || updated.content.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('제목/내용을 입력해줘')),
                        );
                        return;
                      }

                      context.read<PostBloc>().add(UpdatePost(updated, requester: 'me'));
                      detailBloc.add(InitPostDetail(updated));
                      detailBloc.add(ToggleEditMode());
                    },
                    child: const Text('저장'),
                  ),

                if (state.isMine && !state.isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('삭제할까요?'),
                          content: const Text('삭제하면 되돌릴 수 없어요.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('취소'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('삭제'),
                            ),
                          ],
                        ),
                      );

                    if (!context.mounted) return;
                      if (ok == true) {
                        context.read<PostBloc>().add(DeletePost(state.post.id, requester: 'me'));
                        Navigator.pop(context);
                      }
                    },
                  ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: state.isEditing
                  ? _EditForm(state: state)
                  : ListView(
                      controller: _scrollCtrl,
                      children: [
                        _DetailView(state: state),
                        const SizedBox(height: 16),
                        _ReplySection(
                          state: state,
                          replyCtrl: _replyCtrl,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
            ),
          );
        },
      ),
    ),
    );
  }
}

class _DetailView extends StatelessWidget {
  final PostDetailState state;
  const _DetailView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 6),
            color: Color(0x11000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3F5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              state.post.type == 'question' ? '질문' : '일반',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            state.post.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            '작성자: ${state.post.author}  ·  ${formatDateTime(state.post.createdAt)}',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const Divider(height: 30),
          if (state.post.imageUrl != null && state.post.imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: PostImage(
                imageUrl: state.post.imageUrl,
                width: double.infinity,
                height: 480,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(state.post.content, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: () => context.read<PostBloc>().add(TogglePostLike(state.post)),
                icon: Icon(
                  state.post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                  color: state.post.isLikedByMe ? Colors.red : null,
                ),
              ),
              if (state.post.likeCount > 0)
                Text('좋아요 ${state.post.likeCount}', style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReplySection extends StatelessWidget {
  final PostDetailState state;
  final TextEditingController replyCtrl;

  const _ReplySection({required this.state, required this.replyCtrl});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PostDetailBloc>();

    final isEditingReply = state.editingReplyId != null;
    if (isEditingReply && replyCtrl.text != state.editingReplyContent) {
      // 편집 모드에서는 입력창을 편집 내용과 동기화
      replyCtrl.value = TextEditingValue(
        text: state.editingReplyContent,
        selection: TextSelection.collapsed(offset: state.editingReplyContent.length),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 6),
            color: Color(0x11000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '댓글 ${state.totalReplyCount ?? state.replies.length}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (state.isRepliesLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              IconButton(
                tooltip: '새로고침',
                onPressed: () => bloc.add(LoadReplies(reset: true)),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (state.replies.isEmpty && !state.isRepliesLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('첫 댓글을 남겨보세요.'),
            ),

          ...state.replies.map((reply) {
            final isMine = reply.author == 'me';
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  Text(reply.author),
                  if (reply.createdAt != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      formatDateTime(reply.createdAt!),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
              subtitle: Text(reply.content),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => bloc.add(ToggleReplyLike(reply)),
                    icon: Icon(
                      reply.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: reply.isLikedByMe ? Colors.red : null,
                    ),
                  ),
                  if (reply.likeCount > 0)
                    Text('${reply.likeCount}', style: const TextStyle(fontSize: 12)),
                  if (isMine)
                    PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') {
                          bloc.add(StartEditReply(reply));
                        } else if (v == 'delete') {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('댓글 삭제'),
                              content: const Text('삭제하면 되돌릴 수 없어요.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('취소'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('삭제'),
                                ),
                              ],
                            ),
                          );
                          if (!context.mounted) return;
                          if (ok == true) bloc.add(DeleteReply(reply.id));
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('수정')),
                        PopupMenuItem(value: 'delete', child: Text('삭제')),
                      ],
                    ),
                ],
              ),
            );
          }),

          if (!state.hasMoreReplies && state.replies.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('마지막 댓글입니다.', style: TextStyle(color: Colors.grey)),
            ),

          const SizedBox(height: 12),
          if (isEditingReply)
            Row(
              children: [
                const Icon(Icons.edit, size: 18, color: Colors.deepPurple),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('댓글 수정 모드', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                TextButton(
                  onPressed: () {
                    replyCtrl.clear();
                    bloc.add(CancelEditReply());
                  },
                  child: const Text('취소'),
                ),
              ],
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: replyCtrl,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: isEditingReply ? '댓글 수정' : '댓글 입력',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    if (isEditingReply) bloc.add(ChangeEditingReplyContent(v));
                  },
                  onSubmitted: (_) {
                    if (isEditingReply) {
                      bloc.add(SubmitUpdateReply());
                    } else {
                      bloc.add(CreateReply(replyCtrl.text));
                    }
                    replyCtrl.clear();
                  },
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: state.isReplyActionLoading
                    ? null
                    : () {
                        if (isEditingReply) {
                          bloc.add(SubmitUpdateReply());
                        } else {
                          bloc.add(CreateReply(replyCtrl.text));
                        }
                        replyCtrl.clear();
                      },
                child: Text(isEditingReply ? '수정' : '등록'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditForm extends StatelessWidget {
  final PostDetailState state;
  const _EditForm({required this.state});

  static const int _maxImageBytes = 3 * 1024 * 1024;

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null || !context.mounted) return;
    final bytes = await x.readAsBytes();
    if (bytes.length > _maxImageBytes) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지는 3MB 이하여야 해요.')),
        );
      }
      return;
    }
    final base64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    if (context.mounted) {
      context.read<PostDetailBloc>().add(ChangeEditImage(base64));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PostDetailBloc>();
    final currentImageUrl = state.editingImageUrl == null
        ? state.post.imageUrl
        : (state.editingImageUrl!.isEmpty ? null : state.editingImageUrl);

    return Column(
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'post', label: Text('게시글')),
            ButtonSegment(value: 'question', label: Text('질문')),
          ],
          selected: {state.type},
          onSelectionChanged: (s) => bloc.add(ChangeType(s.first)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: TextEditingController(text: state.title),
          onChanged: (v) => bloc.add(ChangeTitle(v)),
          decoration: const InputDecoration(
            labelText: '제목',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickImage(context),
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('이미지 변경'),
            ),
          ],
        ),
        if (currentImageUrl != null && currentImageUrl.isNotEmpty) ...[
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: PostImage(imageUrl: currentImageUrl, width: double.infinity, height: 280),
              ),
              IconButton(
                onPressed: () => bloc.add(ChangeEditImage('')),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(backgroundColor: Colors.white70),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: TextField(
            controller: TextEditingController(text: state.content),
            onChanged: (v) => bloc.add(ChangeContent(v)),
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              labelText: '내용',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
