class InteractionModel {
  final String projectId;
  final String actionType;      // view / tag_view / like / apply 등 모든 타입 수용
  final DateTime createdAt;

  InteractionModel({
    required this.projectId,
    required this.actionType,
    required this.createdAt,
  });

  factory InteractionModel.fromJson(Map<String, dynamic> json) {
    return InteractionModel(
      projectId: json['project_id'],
      actionType: json['action_type'],   // DB 컬럼명 그대로 매핑
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}