/// 검색/필터 조건 (3가지 동시 적용 가능).
class PostSearchFilter {
  final String? search; // 제목/내용 검색 (디바운스 300ms)
  final String? type; // 'all' | 'post' | 'question'
  final String? author; // 작성자
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const PostSearchFilter({
    this.search,
    this.type,
    this.author,
    this.dateFrom,
    this.dateTo,
  });

  static const PostSearchFilter empty = PostSearchFilter();

  PostSearchFilter copyWith({
    String? search,
    String? type,
    String? author,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearSearch = false,
    bool clearType = false,
    bool clearAuthor = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
  }) {
    return PostSearchFilter(
      search: clearSearch ? null : (search ?? this.search),
      type: clearType ? null : (type ?? this.type),
      author: clearAuthor ? null : (author ?? this.author),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
    );
  }

  bool get isEmpty =>
      (search == null || search!.trim().isEmpty) &&
      (type == null || type == 'all') &&
      author == null &&
      dateFrom == null &&
      dateTo == null;
}
