import 'package:flutter_test/flutter_test.dart';
import 'package:knock_app/features/post/data/datasources/post_local_datasource.dart';
import 'package:knock_app/features/post/data/datasources/post_remote_datasource.dart';
import 'package:knock_app/features/post/data/models/post_model.dart';
import 'package:knock_app/features/post/data/repositories/post_repository_impl.dart';
import 'package:knock_app/features/post/domain/entities/post_search_filter.dart';
import 'package:mocktail/mocktail.dart';

class MockPostRemoteDataSource extends Mock implements PostRemoteDataSource {}

class MockPostLocalDataSource extends Mock implements PostLocalDataSource {}

void main() {
  late PostRemoteDataSource remote;
  late PostLocalDataSource local;
  late PostRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(PostSearchFilter.empty);
    registerFallbackValue(<PostModel>[]);
  });

  final postModel = PostModel(
    id: 1,
    title: 'T',
    content: 'C',
    type: 'post',
    author: 'me',
    createdAt: DateTime(2026, 3, 1),
  );

  setUp(() {
    remote = MockPostRemoteDataSource();
    local = MockPostLocalDataSource();
    repo = PostRepositoryImpl(remote: remote, local: local);
  });

  group('PostRepositoryImpl.getPosts', () {
    test('returns remote posts and saves to local', () async {
      when(() => remote.getPosts(any())).thenAnswer((_) async => [postModel]);
      when(() => local.savePosts(any())).thenAnswer((_) async {});

      final result = await repo.getPosts();

      expect(result.length, 1);
      expect(result.first.id, 1);
      verify(() => remote.getPosts(PostSearchFilter.empty)).called(1);
      verify(() => local.savePosts(any())).called(1);
    });

    test('with filter passes filter to remote', () async {
      final filter = PostSearchFilter(type: 'post', author: 'me');
      when(() => remote.getPosts(any())).thenAnswer((_) async => [postModel]);
      when(() => local.savePosts(any())).thenAnswer((_) async {});

      await repo.getPosts(filter);

      verify(() => remote.getPosts(filter)).called(1);
    });

    test('on remote failure returns local and applies filter', () async {
      when(() => remote.getPosts(any())).thenThrow(Exception());
      when(() => local.getPosts()).thenAnswer((_) async => [
            postModel,
            PostModel(
              id: 2,
              title: 'Q',
              content: 'Q',
              type: 'question',
              author: 'other',
              createdAt: DateTime(2026, 3, 2),
            ),
          ]);

      final result = await repo.getPosts(PostSearchFilter(type: 'post'));

      expect(result.length, 1);
      expect(result.first.type, 'post');
      verify(() => local.getPosts()).called(1);
    });

    test('filters by search term in local fallback', () async {
      when(() => remote.getPosts(any())).thenThrow(Exception());
      when(() => local.getPosts()).thenAnswer((_) async => [
            postModel,
            PostModel(
              id: 2,
              title: 'Other',
              content: 'X',
              type: 'post',
              author: 'me',
              createdAt: DateTime(2026, 3, 2),
            ),
          ]);

      final result = await repo.getPosts(PostSearchFilter(search: 'Other'));

      expect(result.length, 1);
      expect(result.first.title, 'Other');
    });
  });
}
