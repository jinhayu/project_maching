import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import '../models/project_model.dart';
import '../models/application_model.dart';
import '../models/comment_model.dart';
import 'recommendation_service.dart'; // TFLite 추천 서비스

class ProjectService {
  final SupabaseClient _client = Supabase.instance.client;
  final RecommendationService _recommendationService = RecommendationService();

  String? get currentUserId => _client.auth.currentUser?.id;

  // EMA 가중치 계산에 사용되는 상수
  static const double emaDecayFactor = 0.0001;

  // 생성자: TFLite 모델 로드 시작 (앱 시작 시 한 번만 실행)
  ProjectService() {
    _recommendationService.loadModel();
  }

  // 🆕 사용자 활동 로그 기록 함수 (EMA Score 기반 마련)
  Future<void> logUserAction(String projectId, String actionType, {int weight = 1}) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _client.from('user_logs').insert({
        'user_id': userId,
        'project_id': projectId,
        'action_type': actionType,
        'score_weight': weight,
      });
    } catch(e) {
      debugPrint('사용자 로그 기록 실패: $e');
    }
  }


  // 1-1. 프로젝트 목록 조회 (매칭 점수 계산 포함)
  Future<List<Project>> fetchProjects({String? query}) async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      // 1. 현재 로그인한 사용자의 기술 스택 로드
      final userProfileResponse = await _client
          .from('profiles')
          .select('tech_stack')
          .eq('id', userId)
          .maybeSingle(); // maybeSingle로 데이터가 없어도 오류 방지

      final String userSkillsStr = userProfileResponse?['tech_stack'] ?? '';
      final List<String> userSkills = userSkillsStr.split(',')
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toList();

      // 🆕 2. EMA 가중치 계산
      final Map<String, double> emaWeights = await _calculateEmaWeights(userId);


      // 3. 프로젝트 목록 로드
      var dbQuery = _client
          .from('projects')
          .select('*, my_likes:project_likes(user_id)')
          .eq('my_likes.user_id', userId);

      if (query != null && query.isNotEmpty) {
        dbQuery = dbQuery.ilike('title', '%$query%');
      }

      final response = await dbQuery
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;

      // 4. 매칭 점수 계산 및 Project 모델 생성
      final List<Project> projects = [];

      for(var json in data) {
        final String requiredSkillsStr = json['tech_stack'] ?? '';
        final List<String> requiredSkills = requiredSkillsStr.split(',')
            .map((s) => s.trim().toLowerCase())
            .where((s) => s.isNotEmpty)
            .toList();

        final project = Project.fromJson(json);

        // 💡 RecommendationService를 통해 하이브리드 점수 계산
        double score = _recommendationService.getMatchScore(
          userSkills,
          requiredSkills,
          // 🆕 EMA 가중치를 전달합니다. (없으면 0.0 전달)
          emaWeight: emaWeights[project.id] ?? 0.0,
        );

        projects.add(project.copyWith(matchScore: score));
      }

      // 5. 매칭 점수 순으로 정렬 (추천 기능 활성화)
      projects.sort((a, b) => b.matchScore.compareTo(a.matchScore));

      return projects;
    } catch (e) {
      debugPrint('프로젝트 목록 로드 실패: $e');
      return [];
    }
  }

  // 🆕 사용자 활동 로그를 기반으로 프로젝트별 EMA 가중치 계산 (NCF.txt 로직 기반)
  Future<Map<String, double>> _calculateEmaWeights(String userId) async {
    try {
      final response = await _client
          .from('user_logs')
          .select('project_id, score_weight, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      final logs = response as List<dynamic>;
      if (logs.isEmpty) return {};

      final emaWeights = <String, double>{};
      final now = DateTime.now().millisecondsSinceEpoch;

      // 로그를 순회하며 지수 감쇠 가중치 계산 및 누적
      for (var log in logs) {
        final projectId = log['project_id'] as String;
        final scoreWeight = (log['score_weight'] as int).toDouble();
        final createdAt = DateTime.parse(log['created_at'] as String);

        final diffInMilliseconds = now - createdAt.millisecondsSinceEpoch;

        // 지수 감쇠 계산: e^(-decay_factor * time_diff)
        final timeDecay = math.exp(-emaDecayFactor * diffInMilliseconds);

        final decayedScore = scoreWeight * timeDecay;

        // 프로젝트별 EMA 점수 누적
        emaWeights[projectId] = (emaWeights[projectId] ?? 0.0) + decayedScore;
      }

      return emaWeights;
    } catch (e) {
      debugPrint('EMA 가중치 계산 실패: $e');
      return {};
    }
  }


  // 1-2. 프로젝트 생성
  Future<void> createProject({
    required String title,
    required String description,
    required String techStack,
    required int maxMembers,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다.');
    try {
      await _client.from('projects').insert({
        'owner_id': userId,
        'title': title,
        'description': description,
        'tech_stack': techStack,
        'max_members': maxMembers,
        'is_recruiting': true,
        'view_count': 0,
        'like_count': 0,
      });
    } catch (e) {
      debugPrint('생성 실패: $e');
      throw Exception('생성 오류');
    }
  }

  // 1-3. 프로젝트 삭제
  Future<void> deleteProject(String projectId) async {
    try {
      await _client.from('projects').delete().eq('id', projectId);
    } catch (e) {
      throw Exception('삭제 실패');
    }
  }

  // 1-4. 조회수 증가 (로그 기록 포함)
  Future<void> incrementViewCount(String projectId) async {
    try {
      await _client.rpc('increment_view_count', params: {'row_id': projectId});
      logUserAction(projectId, 'view', weight: 1);
    } catch (e) {
      debugPrint('조회수 증가 실패: $e');
    }
  }

  // 1-5. 좋아요 토글 (로그 기록 포함)
  Future<bool> toggleLike(String projectId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    try {
      final result = await _client.rpc('toggle_like', params: {'p_id': projectId});
      final bool isLiked = result as bool;
      logUserAction(projectId, 'like', weight: isLiked ? 2 : -2);

      return isLiked;
    } catch (e) {
      debugPrint('좋아요 토글 실패: $e');
      throw Exception('좋아요 실패');
    }
  }

  // 2-1. 프로젝트에 지원하기 (로그 기록 포함)
  Future<void> applyToProject(String projectId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    try {
      await _client.from('project_applications').insert({
        'project_id': projectId,
        'applicant_id': userId,
        'status': 'pending',
      });
      logUserAction(projectId, 'apply', weight: 3);
    } catch (e) {
      debugPrint('지원 실패: $e');
      throw Exception('이미 지원했거나 오류가 발생했습니다.');
    }
  }

  // 2-2. 내가 이 프로젝트에 이미 지원했는지 확인
  Future<bool> hasApplied(String projectId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      final response = await _client
          .from('project_applications')
          .select('id')
          .eq('project_id', projectId)
          .eq('applicant_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // 2-3. (팀장용) 지원자 목록 가져오기
  Future<List<Application>> fetchApplications(String projectId) async {
    try {
      final response = await _client
          .from('project_applications')
          .select('*, profiles(username, email, department)')
          .eq('project_id', projectId)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((json) => Application.fromJson(json)).toList();
    } catch (e) {
      debugPrint('지원자 목록 로드 실패: $e');
      return [];
    }
  }

  // 2-4. (팀장용) 지원자 승인/거절 상태 변경
  Future<void> updateApplicationStatus(int applicationId, String newStatus) async {
    try {
      await _client
          .from('project_applications')
          .update({'status': newStatus})
          .eq('id', applicationId);
    } catch (e) {
      debugPrint('상태 변경 실패: $e');
      throw Exception('상태 변경에 실패했습니다.');
    }
  }

  // 3-1. 댓글 목록 조회
  Future<List<Comment>> fetchComments(String projectId) async {
    try {
      final response = await _client
          .from('project_comments')
          .select('*, profiles(username)')
          .eq('project_id', projectId)
          .order('created_at', ascending: true);

      final data = response as List<dynamic>;
      return data.map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      debugPrint('댓글 로드 실패: $e');
      return [];
    }
  }

  // 3-2. 댓글 작성
  Future<void> addComment(String projectId, String content) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    try {
      await _client.from('project_comments').insert({
        'project_id': projectId,
        'user_id': userId,
        'content': content,
      });
    } catch (e) {
      debugPrint('댓글 작성 실패: $e');
      throw Exception('댓글 작성 실패');
    }
  }

  // 3-3. 댓글 삭제
  Future<void> deleteComment(int commentId) async {
    try {
      await _client.from('project_comments').delete().eq('id', commentId);
    } catch (e) {
      debugPrint('댓글 삭제 실패: $e');
      throw Exception('삭제 실패');
    }
  }
}