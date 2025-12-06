class Project {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String techStack;
  final int maxMembers;
  final bool isRecruiting;
  final DateTime createdAt;
  final int viewCount;
  final int likeCount;
  final bool isLiked;

  // 💡 FIX: matchScore 필드 추가
  final double matchScore;

  Project({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.techStack,
    required this.maxMembers,
    required this.isRecruiting,
    required this.createdAt,
    this.viewCount = 0,
    this.likeCount = 0,
    this.isLiked = false,
    this.matchScore = 0.0, // 💡 FIX: matchScore 추가
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    bool liked = false;
    if (json['my_likes'] != null) {
      final List likes = json['my_likes'] as List;
      liked = likes.isNotEmpty;
    }

    return Project(
      id: json['id'].toString(),
      ownerId: json['owner_id'],
      title: json['title'],
      description: json['description'],
      techStack: json['tech_stack'] ?? '',
      maxMembers: json['max_members'] ?? 4,
      isRecruiting: json['is_recruiting'] ?? true,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      viewCount: json['view_count'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      isLiked: liked,
      matchScore: 0.0, // 초기 로드 시 0점으로 설정
    );
  }

  // 💡 FIX: copyWith 메서드 추가 (ProjectService에서 매칭 점수 업데이트용)
  Project copyWith({
    double? matchScore,
  }) {
    return Project(
      id: id,
      ownerId: ownerId,
      title: title,
      description: description,
      techStack: techStack,
      maxMembers: maxMembers,
      isRecruiting: isRecruiting,
      createdAt: createdAt,
      viewCount: viewCount,
      likeCount: likeCount,
      isLiked: isLiked,
      matchScore: matchScore ?? this.matchScore,
    );
  }
}