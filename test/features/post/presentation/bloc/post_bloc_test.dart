import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knock_app/features/post/data/datasources/post_local_datasource.dart';
import 'package:knock_app/features/post/domain/entities/post.dart';
import 'package:knock_app/features/post/domain/entities/post_search_filter.dart';
import 'package:knock_app/features/post/domain/repositories/post_repository.dart';
import 'package:knock_app/features/post/presentation/bloc/post_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  late PostRepository repository;

  final post1 = Post(
    id: 1,
    title: 'Title',
    content: 'Content',
    type: 'post',
    author: 'me',
    createdAt: DateTime(2026, 3, 1),
  );

  final post2 = Post(
    id: 2,
    title: 'Q',
    content: 'Question',
    type: 'question',
    author: 'other',
    createdAt: DateTime(2026, 3, 2),
  );

  setUpAll(() {
    registerFallbackValue(PostSearchFilter.empty);
    registerFallbackValue(Post(
      id: 0,
      title: '',
      content: '',
      type: 'post',
      author: '',
      createdAt: DateTime(0),
    ));
  });

  setUp(() {
    repository = MockPostRepository();
  });

  group('PostBloc', () {
    test('initial state is PostInitial', () {
      final bloc = PostBloc(
        repository: repository,
        localDataSource: PostLocalDataSource(),
      );
      expect(bloc.state, isA<PostInitial>());
      bloc.close();
    });

    blocTest<PostBloc, PostState>(
      'LoadPosts emits PostLoaded with posts and empty filter',
      build: () {
        when(() => repository.getPosts(any())).thenAnswer((_) async => [post1, post2]);
        return PostBloc(repository: repository, localDataSource: PostLocalDataSource());
      },
      act: (bloc) => bloc.add(LoadPosts()),
      expect: () => [
        isA<PostLoaded>()
            .having((s) => s.posts.length, 'posts.length', 2)
            .having((s) => s.appliedFilter.isEmpty, 'filter.isEmpty', true),
      ],
      verify: (_) => verify(() => repository.getPosts(PostSearchFilter.empty)).called(1),
    );

    blocTest<PostBloc, PostState>(
      'LoadPosts with filter emits PostLoaded with appliedFilter',
      build: () {
        final filter = PostSearchFilter(type: 'post');
        when(() => repository.getPosts(any())).thenAnswer((_) async => [post1]);
        return PostBloc(repository: repository, localDataSource: PostLocalDataSource());
      },
      act: (bloc) => bloc.add(LoadPosts(PostSearchFilter(type: 'post'))),
      expect: () => [
        isA<PostLoaded>()
            .having((s) => s.posts.length, 'posts.length', 1)
            .having((s) => s.appliedFilter.type, 'filter.type', 'post'),
      ],
    );

    blocTest<PostBloc, PostState>(
      'AddPost adds post and keeps filter',
      build: () {
        when(() => repository.getPosts(any())).thenAnswer((_) async => [post1]);
        when(() => repository.createPost(any())).thenAnswer((_) async => post2);
        return PostBloc(repository: repository, localDataSource: PostLocalDataSource());
      },
      seed: () => PostLoaded([post1], PostSearchFilter(search: 'x')),
      act: (bloc) => bloc.add(AddPost(post2)),
      expect: () => [
        isA<PostLoaded>()
            .having((s) => s.posts.length, 'posts.length', 2)
            .having((s) => s.appliedFilter.search, 'filter.search', 'x'),
      ],
    );

    blocTest<PostBloc, PostState>(
      'DeletePost removes post when requester is author',
      build: () {
        when(() => repository.deletePost(1)).thenAnswer((_) async {});
        return PostBloc(repository: repository, localDataSource: PostLocalDataSource());
      },
      seed: () => PostLoaded([post1, post2]),
      act: (bloc) => bloc.add(DeletePost(1, requester: 'me')),
      expect: () => [
        isA<PostLoaded>().having((s) => s.posts.length, 'posts.length', 1),
      ],
    );

    blocTest<PostBloc, PostState>(
      'DeletePost does nothing when requester is not author',
      build: () => PostBloc(repository: repository, localDataSource: PostLocalDataSource()),
      seed: () => PostLoaded([post1]),
      act: (bloc) => bloc.add(DeletePost(1, requester: 'other')),
      expect: () => [],
    );

    blocTest<PostBloc, PostState>(
      'UpdatePost updates post when requester is author',
      build: () {
        final updated = post1.copyWith(title: 'Updated');
        when(() => repository.updatePost(any())).thenAnswer((_) async => updated);
        return PostBloc(repository: repository, localDataSource: PostLocalDataSource());
      },
      seed: () => PostLoaded([post1]),
      act: (bloc) => bloc.add(UpdatePost(post1.copyWith(title: 'Updated'), requester: 'me')),
      expect: () => [
        isA<PostLoaded>().having((s) => s.posts.first.title, 'title', 'Updated'),
      ],
    );

    blocTest<PostBloc, PostState>(
      'TogglePostLike emits optimistic then server result',
      build: () {
        final liked = post1.copyWith(likeCount: 1, isLikedByMe: true);
        when(() => repository.likePost(1)).thenAnswer((_) async => liked);
        return PostBloc(repository: repository, localDataSource: PostLocalDataSource());
      },
      seed: () => PostLoaded([post1]),
      act: (bloc) => bloc.add(TogglePostLike(post1)),
      expect: () => [
        isA<PostLoaded>().having((s) => s.posts.first.isLikedByMe, 'isLikedByMe', true),
        isA<PostLoaded>().having((s) => s.posts.first.likeCount, 'likeCount', 1),
      ],
    );
  });
}
