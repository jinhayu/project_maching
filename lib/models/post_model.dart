class Post {
  final int id;
  final String projectId;
  final String authorId;
  final String title;
  final String content;
  final DateTime createdAt;

  // 작성자 닉네임 (조인 데이터)
  final String? authorName;

  Post({
    required this.id,
    required this.projectId,
    required this.authorId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.authorName,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles']; // profiles 테이블 조인 결과

    return Post(
      id: json['id'],
      projectId: json['project_id'].toString(),
      authorId: json['author_id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      authorName: profile != null ? profile['username'] : '알 수 없음',
    );
  }
}