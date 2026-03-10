class Post {
  final int id;
  final String title;
  final String content;
  final String type; // post or question
  final String author;
  final DateTime createdAt;
  final int likeCount;
  final bool isLikedByMe;
  final String? imageUrl; // base64 data URL or http URL

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.author,
    required this.createdAt,
    this.likeCount = 0,
    this.isLikedByMe = false,
    this.imageUrl,
  });

  Post copyWith({
    int? id,
    String? title,
    String? content,
    String? type,
    String? author,
    DateTime? createdAt,
    int? likeCount,
    bool? isLikedByMe,
    String? imageUrl,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
