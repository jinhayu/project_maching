import 'profile_model.dart';
import 'project_model.dart'; // 💡 Project 모델 import 필수

class Application {
  final int id;
  final String projectId;
  final String applicantId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  // 1. 지원자 관리 페이지용 (지원자 프로필)
  final Profile? applicantProfile;

  // 2. 마이페이지용 (지원한 프로젝트 정보)
  final Project? project;

  Application({
    required this.id,
    required this.projectId,
    required this.applicantId,
    required this.status,
    required this.createdAt,
    this.applicantProfile,
    this.project,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'],
      projectId: json['project_id'].toString(),
      applicantId: json['applicant_id'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']).toLocal(),

      // profiles 테이블 조인 데이터
      applicantProfile: json['profiles'] != null
          ? Profile.fromJson(json['profiles'])
          : null,

      // projects 테이블 조인 데이터 (마이페이지용)
      project: json['projects'] != null
          ? Project.fromJson(json['projects'])
          : null,
    );
  }

  // UI 편의용 Getter
  String get applicantName => applicantProfile?.username ?? '알 수 없음';
  String get applicantEmail => applicantProfile?.email ?? '-';
  String get applicantPosition => applicantProfile?.position ?? '직군 미설정';
}