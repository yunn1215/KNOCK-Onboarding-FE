import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/post_bloc.dart';
import '../../domain/entities/post.dart';
import 'post_create_page.dart';
import 'post_detail_page.dart';

class PostListPage extends StatefulWidget {
  const PostListPage({super.key});

  @override
  State<PostListPage> createState() => _PostListPageState();
}

class _PostListPageState extends State<PostListPage> {
  String _filter = 'all'; // all | post | question

  String _typeLabel(String type) => type == 'question' ? '질문' : '일반';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PostBloc()..add(LoadPosts()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Knock'),
          actions: const [
            Icon(Icons.search),
            SizedBox(width: 12),
            Icon(Icons.tune),
            SizedBox(width: 12),
          ],
        ),
        body: BlocBuilder<PostBloc, PostState>(
          builder: (context, state) {
            if (state is! PostLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            final posts = state.posts;

            // 필터 적용
            final filtered = _filter == 'all'
                ? posts
                : posts.where((p) => p.type == _filter).toList();

            final reversed = filtered.reversed.toList(); // 최신 글 위

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'all', label: Text('전체')),
                      ButtonSegment(value: 'post', label: Text('게시글')),
                      ButtonSegment(value: 'question', label: Text('질문')),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (s) =>
                        setState(() => _filter = s.first),
                  ),
                ),
                Expanded(
                  child: reversed.isEmpty
                      ? const Center(child: Text('게시글이 없습니다'))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: reversed.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final Post p = reversed[i];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<PostBloc>(),
                                      child: PostDetailPage(post: p),
                                    ),
                                  ),
                                );
                              },
                              child: _PostCard(
                                typeLabel: _typeLabel(p.type),
                                author: p.author,
                                title: p.title,
                                content: p.content,
                                onDelete: () {
                                  if (p.author != 'me') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('작성자만 삭제할 수 있어요'),
                                      ),
                                    );
                                    return;
                                  }
                                  // 목록에서 즉시 삭제(확인 다이얼로그는 상세에서 이미 구현했으니 필수는 충족)
                                  context.read<PostBloc>().add(
                                    DeletePost(p.id, requester: 'me'),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<PostBloc>(),
                      child: const PostCreatePage(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('새 게시글 작성'),
            );
          },
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final String typeLabel;
  final String author;
  final String title;
  final String content;
  final VoidCallback onDelete;

  const _PostCard({
    required this.typeLabel,
    required this.author,
    required this.title,
    required this.content,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              const CircleAvatar(
                radius: 14,
                child: Icon(Icons.person, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  author,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (author == 'me')
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3F5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(typeLabel, style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(content, maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
