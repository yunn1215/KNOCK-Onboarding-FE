import '../../domain/entities/post.dart';

class PostModel extends Post {
  PostModel({
    required super.id,
    required super.title,
    required super.content,
    required super.type,
    required super.author,
    required super.createdAt,
    super.likeCount,
    super.isLikedByMe = false,
    super.imageUrl,
    List<String>? likedBy,
  }) : _likedBy = likedBy ?? (isLikedByMe ? ['me'] : []);

  final List<String> _likedBy;

  List<String> get likedBy => List.unmodifiable(_likedBy);

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final likedByList = json['likedBy'] as List<dynamic>? ?? [];
    final likedBy = likedByList.map((e) => e.toString()).toList();
    final likeCount = json['likeCount'] is int ? json['likeCount'] as int : likedBy.length;
    return PostModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? 'post',
      author: json['author'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      likeCount: likeCount,
      isLikedByMe: likedBy.contains('me'),
      imageUrl: json['imageUrl'] as String?,
      likedBy: likedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'author': author,
      'createdAt': createdAt.toIso8601String(),
      'likeCount': likeCount,
      'likedBy': _likedBy,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
    };
  }
}
