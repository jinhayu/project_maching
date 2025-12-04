class Profile {
  final String id;
  final String? email;
  final String? username;
  final String? department;
  final String? bio;
  final String? techStack;
  final String? blogUrl;
  final DateTime? updatedAt;

  Profile({
    required this.id,
    this.email,
    this.username,
    this.department,
    this.bio,
    this.techStack,
    this.blogUrl,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      department: json['department'],
      bio: json['bio'],
      techStack: json['tech_stack'],
      blogUrl: json['blog_url'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at']).toLocal()
          : null,
    );
  }
}