class Post {
  final String id;
  final String title;
  final String content;
  final String type; // post or question
  final String author;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.author,
    required this.createdAt,
  });
}
