import '../../domain/entities/reply.dart';

class ReplyModel extends Reply {
  ReplyModel({
    required super.id,
    required super.postId,
    required super.content,
    required super.author,
  });

  factory ReplyModel.fromJson(Map<String, dynamic> json) {
    return ReplyModel(
      id: json['id'],
      postId: json['postId'],
      content: json['content'],
      author: json['author'],
    );
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "postId": postId, "content": content, "author": author};
  }
}
