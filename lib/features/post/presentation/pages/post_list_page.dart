import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/post_image.dart';
import '../../data/datasources/post_local_datasource.dart';
import '../../data/datasources/post_remote_datasource.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../domain/entities/post.dart';
import '../bloc/post_bloc.dart';
import 'post_create_page.dart';
import 'post_detail_page.dart';

class PostListPage extends StatefulWidget {
  const PostListPage({super.key});

  @override
  State<PostListPage> createState() => _PostListPageState();
}

class _PostListPageState extends State<PostListPage> {
  String _filter = 'all';
  Completer<void>? _refreshCompleter;

  String _typeLabel(String type) => type == 'question' ? '질문' : '일반';

  Future<void> _onRefresh() async {
    _refreshCompleter = Completer<void>();
    context.read<PostBloc>().add(LoadPosts());
    await _refreshCompleter!.future;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final dio = ApiClient.create();
        final repository = PostRepositoryImpl(
          remote: PostRemoteDataSource(dio),
          local: PostLocalDataSource(),
        );
        return PostBloc(repository: repository)..add(LoadPosts());
      },
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
        body: BlocListener<PostBloc, PostState>(
          listenWhen: (prev, next) => next is PostLoaded,
          listener: (context, state) {
            _refreshCompleter?.complete();
            _refreshCompleter = null;
          },
          child: BlocBuilder<PostBloc, PostState>(
            builder: (context, state) {
              if (state is! PostLoaded) {
                return const Center(child: CircularProgressIndicator());
              }

              final posts = state.posts;
              final filtered = _filter == 'all'
                  ? posts
                  : posts.where((p) => p.type == _filter).toList();
              final reversed = filtered.reversed.toList();

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
                    child: RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: reversed.isEmpty
                          ? const SingleChildScrollView(
                              physics: AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: 200,
                                child: Center(child: Text('게시글이 없습니다')),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: reversed.length,
                              separatorBuilder: (context, _) =>
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
                                    post: p,
                                    typeLabel: _typeLabel(p.type),
                                    onLike: () =>
                                        context.read<PostBloc>().add(TogglePostLike(p)),
                                    onDelete: () {
                                      if (p.author != 'me') {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('작성자만 삭제할 수 있어요'),
                                          ),
                                        );
                                        return;
                                      }
                                      context.read<PostBloc>().add(
                                            DeletePost(p.id, requester: 'me'),
                                          );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
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
  final Post post;
  final String typeLabel;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  const _PostCard({
    required this.post,
    required this.typeLabel,
    required this.onLike,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      post.author,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      formatDateTime(post.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onLike,
                icon: Icon(
                  post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                  color: post.isLikedByMe ? Colors.red : null,
                ),
              ),
              if (post.author == 'me')
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: PostImage(
                imageUrl: post.imageUrl,
                height: 280,
                width: double.infinity,
              ),
            ),
          ],
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
            post.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(post.content, maxLines: 3, overflow: TextOverflow.ellipsis),
          if (post.likeCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '좋아요 ${post.likeCount}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
