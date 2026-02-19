import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/post.dart';
import '../bloc/post_bloc.dart';
import '../bloc/post_detail_bloc.dart';

class PostDetailPage extends StatelessWidget {
  final Post post;
  const PostDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PostDetailBloc(post),
      child: const _PostDetailView(),
    );
  }
}

class _PostDetailView extends StatelessWidget {
  const _PostDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostDetailBloc, PostDetailState>(
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
                    final updated = Post(
                      id: state.post.id,
                      title: state.title.trim(),
                      content: state.content.trim(),
                      type: state.type,
                      author: state.post.author,
                      createdAt: state.post.createdAt,
                    );

                    if (updated.title.isEmpty || updated.content.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('제목/내용을 입력해줘')),
                      );
                      return;
                    }

                    // ✅ 수정 반영
                    context.read<PostBloc>().add(
                      UpdatePost(updated, requester: 'me'),
                    );

                    // ✅ 상세 화면 최신 내용 반영 + 편집 종료
                    detailBloc.add(InitPostDetail(updated));
                    detailBloc.add(ToggleEditMode());
                  },
                  child: const Text('저장'),
                ),

              // 삭제는 요구사항이니 같이 넣자(작성자만 + 확인 다이얼로그)
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

                    if (ok == true) {
                      context.read<PostBloc>().add(
                        DeletePost(state.post.id, requester: 'me'),
                      );
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
                : SingleChildScrollView(child: _DetailView(state: state)),
          ),
        );
      },
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
            '작성자: ${state.post.author}',
            style: const TextStyle(color: Colors.grey),
          ),
          const Divider(height: 30),
          Text(state.post.content, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class _EditForm extends StatelessWidget {
  final PostDetailState state;
  const _EditForm({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PostDetailBloc>();

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
