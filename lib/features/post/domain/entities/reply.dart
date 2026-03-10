class Reply {
  final int id;
  final int postId;
  final String content;
  final String author;
  final int likeCount;
  final bool isLikedByMe;
  final DateTime? createdAt;

  Reply({
    required this.id,
    required this.postId,
    required this.content,
    required this.author,
    this.likeCount = 0,
    this.isLikedByMe = false,
    this.createdAt,
  });

  Reply copyWith({
    int? id,
    int? postId,
    String? content,
    String? author,
    int? likeCount,
    bool? isLikedByMe,
    DateTime? createdAt,
  }) {
    return Reply(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      content: content ?? this.content,
      author: author ?? this.author,
      likeCount: likeCount ?? this.likeCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
