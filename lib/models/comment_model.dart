class Comment {
  final int id;
  final String projectId;
  final String userId;
  final String content;
  final DateTime createdAt;

  // 작성자 정보 (조인)
  final String userName;

  Comment({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.userName,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'];
    return Comment(
      id: json['id'],
      projectId: json['project_id'].toString(),
      userId: json['user_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      userName: profile != null ? profile['username'] : '알 수 없음',
    );
  }
}