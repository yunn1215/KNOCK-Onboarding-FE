import '../../domain/entities/reply.dart';

class ReplyModel extends Reply {
  ReplyModel({
    required super.id,
    required super.postId,
    required super.content,
    required super.author,
    super.likeCount,
    super.isLikedByMe = false,
    super.createdAt,
    List<String>? likedBy,
  }) : _likedBy = likedBy ?? (isLikedByMe ? ['me'] : []);

  final List<String> _likedBy;

  List<String> get likedBy => List.unmodifiable(_likedBy);

  factory ReplyModel.fromJson(Map<String, dynamic> json) {
    final likedByList = json['likedBy'] as List<dynamic>? ?? [];
    final likedBy = likedByList.map((e) => e.toString()).toList();
    final likeCount = json['likeCount'] is int ? json['likeCount'] as int : likedBy.length;
    final createdAt = json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : null;
    return ReplyModel(
      id: json['id'] as int,
      postId: json['postId'] as int,
      content: json['content'] as String? ?? '',
      author: json['author'] as String? ?? '',
      likeCount: likeCount,
      isLikedByMe: likedBy.contains('me'),
      createdAt: createdAt,
      likedBy: likedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'content': content,
      'author': author,
      'likeCount': likeCount,
      'likedBy': _likedBy,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
