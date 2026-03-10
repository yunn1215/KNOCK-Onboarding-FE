import 'package:flutter_test/flutter_test.dart';
import 'package:knock_app/features/post/domain/entities/post_search_filter.dart';

void main() {
  group('PostSearchFilter', () {
    test('empty is empty', () {
      expect(PostSearchFilter.empty.isEmpty, isTrue);
      expect(PostSearchFilter.empty.search, isNull);
      expect(PostSearchFilter.empty.type, isNull);
      expect(PostSearchFilter.empty.author, isNull);
    });

    test('copyWith search', () {
      const f = PostSearchFilter.empty;
      final f2 = f.copyWith(search: 'hello');
      expect(f2.search, 'hello');
      expect(f2.isEmpty, isFalse);
    });

    test('copyWith clearSearch', () {
      final f = PostSearchFilter(search: 'x').copyWith(clearSearch: true);
      expect(f.search, isNull);
    });

    test('copyWith type', () {
      final f = PostSearchFilter.empty.copyWith(type: 'post');
      expect(f.type, 'post');
    });

    test('copyWith clearType', () {
      final f = PostSearchFilter(type: 'post').copyWith(clearType: true);
      expect(f.type, isNull);
    });

    test('copyWith author', () {
      final f = PostSearchFilter.empty.copyWith(author: 'me');
      expect(f.author, 'me');
    });

    test('copyWith dateFrom and dateTo', () {
      final from = DateTime(2026, 1, 1);
      final to = DateTime(2026, 12, 31);
      final f = PostSearchFilter.empty.copyWith(dateFrom: from, dateTo: to);
      expect(f.dateFrom, from);
      expect(f.dateTo, to);
    });

    test('isEmpty when type is all', () {
      final f = PostSearchFilter(type: 'all');
      expect(f.isEmpty, isTrue);
    });
  });
}
