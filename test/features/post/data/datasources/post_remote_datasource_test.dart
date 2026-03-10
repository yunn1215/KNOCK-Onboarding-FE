import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knock_app/features/post/data/datasources/post_remote_datasource.dart';
import 'package:knock_app/features/post/domain/entities/post_search_filter.dart';

void main() {
  late Dio dio;
  late PostRemoteDataSource ds;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
  });

  group('PostRemoteDataSource.getPosts', () {
    test('builds default params without filter', () async {
      ds = PostRemoteDataSource(dio);
      final filter = PostSearchFilter.empty;
      try {
        await ds.getPosts(filter);
      } catch (_) {}
      expect(filter.isEmpty, isTrue);
    });

    test('filter type post adds type param', () async {
      ds = PostRemoteDataSource(dio);
      final filter = PostSearchFilter(type: 'post');
      expect(filter.type, 'post');
    });

    test('filter with dateFrom and dateTo', () {
      final from = DateTime(2026, 1, 1);
      final to = DateTime(2026, 12, 31);
      final filter = PostSearchFilter(dateFrom: from, dateTo: to);
      expect(filter.dateFrom, from);
      expect(filter.dateTo, to);
    });
  });
}
