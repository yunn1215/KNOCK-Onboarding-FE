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
import '../../domain/entities/post_search_filter.dart';
import '../bloc/post_bloc.dart';
import '../widgets/post_filter_sheet.dart';
import 'post_create_page.dart';
import 'post_detail_page.dart';

/// 검색 디바운스 목표: 300ms (±50ms).
const Duration kSearchDebounceDuration = Duration(milliseconds: 300);

class PostListPage extends StatelessWidget {
  const PostListPage({super.key});

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
      child: const _PostListScaffold(),
    );
  }
}

class _PostListScaffold extends StatefulWidget {
  const _PostListScaffold();

  @override
  State<_PostListScaffold> createState() => _PostListScaffoldState();
}

class _PostListScaffoldState extends State<_PostListScaffold> {
  Completer<void>? _refreshCompleter;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _searchExpanded = false;

  String _typeLabel(String type) => type == 'question' ? '질문' : '일반';

  void _onSearchChanged(String value) {
    final trimmed = value.trim();

    // 검색어를 "지우는 만큼" 바로 취소되게: 빈 문자열이 되는 순간 즉시 해제.
    if (trimmed.isEmpty) {
      _debounceTimer?.cancel();
      final state = context.read<PostBloc>().state;
      final filter = state is PostLoaded
          ? state.appliedFilter.copyWith(clearSearch: true)
          : PostSearchFilter.empty;
      context.read<PostBloc>().add(LoadPosts(filter));
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(kSearchDebounceDuration, () {
      final state = context.read<PostBloc>().state;
      final filter = state is PostLoaded
          ? state.appliedFilter.copyWith(search: trimmed)
          : PostSearchFilter(search: trimmed);
      context.read<PostBloc>().add(LoadPosts(filter));
    });
  }

  Future<void> _onRefresh() async {
    _refreshCompleter = Completer<void>();
    final state = context.read<PostBloc>().state;
    final filter = state is PostLoaded ? state.appliedFilter : PostSearchFilter.empty;
    context.read<PostBloc>().add(LoadPosts(filter));
    await _refreshCompleter!.future;
  }

  Future<void> _openFilter() async {
    final state = context.read<PostBloc>().state;
    final initial = state is PostLoaded ? state.appliedFilter : PostSearchFilter.empty;
    final result = await showModalBottomSheet<PostSearchFilter>(
      context: context,
      builder: (ctx) => PostFilterSheet(initial: initial),
    );
    if (result != null && context.mounted) {
      final f = result.copyWith(search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim());
      context.read<PostBloc>().add(LoadPosts(f));
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searchExpanded
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '제목·내용 검색',
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              )
            : const Text('Knock'),
        actions: [
          IconButton(
            tooltip: _searchExpanded ? '검색 닫기' : '검색',
            icon: Icon(_searchExpanded ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _searchExpanded = !_searchExpanded;
                if (!_searchExpanded) {
                  _searchController.clear();
                  _debounceTimer?.cancel();
                  final state = context.read<PostBloc>().state;
                  final filter = state is PostLoaded
                      ? state.appliedFilter.copyWith(clearSearch: true)
                      : PostSearchFilter.empty;
                  context.read<PostBloc>().add(LoadPosts(filter));
                }
              });
            },
          ),
          IconButton(
            tooltip: '필터',
            icon: const Icon(Icons.tune),
            onPressed: _openFilter,
          ),
          const SizedBox(width: 8),
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

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: posts.isEmpty
                  ? const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: 200,
                        child: Center(child: Text('게시글이 없습니다')),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: posts.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        // Avoid allocating a reversed copy on every rebuild.
                        final index = posts.length - 1 - i;
                        final Post p = posts[index];
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
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
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
        borderRadius: const BorderRadius.all(Radius.circular(16)),
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
