class Project {
  final String id; // 💡 int -> String (UUID) 변경 (DB 타입에 맞춤)
  final String ownerId;
  final String title;
  final String description;
  final String techStack;
  final int maxMembers;
  final bool isRecruiting;
  final DateTime createdAt;

  // 🆕 추가된 필드 (좋아요/조회수 기능 필수)
  final int viewCount;
  final int likeCount;
  final bool isLiked;

  Project({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.techStack,
    required this.maxMembers,
    required this.isRecruiting,
    required this.createdAt,
    // 🆕 초기값 설정
    this.viewCount = 0,
    this.likeCount = 0,
    this.isLiked = false,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    // 좋아요 여부 확인 로직 (Supabase 조인 데이터 처리)
    bool liked = false;

    // Supabase 쿼리에서 'my_likes'라는 이름으로 조인된 데이터가 있는지 확인
    if (json['my_likes'] != null) {
      final List likes = json['my_likes'] as List;
      liked = likes.isNotEmpty; // 리스트가 비어있지 않으면 내가 좋아요를 누른 것
    }

    return Project(
      id: json['id'].toString(), // UUID 호환을 위해 toString() 사용
      ownerId: json['owner_id'],
      title: json['title'],
      description: json['description'],
      techStack: json['tech_stack'] ?? '',
      maxMembers: json['max_members'] ?? 4,
      isRecruiting: json['is_recruiting'] ?? true,
      createdAt: DateTime.parse(json['created_at']).toLocal(),

      // 🆕 추가된 필드 매핑 (DB 컬럼명과 매칭)
      viewCount: json['view_count'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      isLiked: liked,
    );
  }
}