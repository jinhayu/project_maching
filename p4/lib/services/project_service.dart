// lib/services/project_service.dart


import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter_example/models/ncf_model.dart';
import 'package:supabase_flutter_example/models/project_model.dart';
import 'package:supabase_flutter_example/models/application_model.dart';
import 'package:supabase_flutter_example/models/comment_model.dart';

class ProjectService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  // =========================================================
  // 💡 [개별 가중치 파라미터 영역]
  // 이 값들을 수정하여 추천 시스템의 민감도를 조절할 수 있습니다.
  // =========================================================

  // 1. 활동 로그 개별 가중치 파라미터 (EMA Probability 계산에 사용)
  // user_logs 테이블의 score_weight 컬럼에 기록됨
  static const int _VIEW_WEIGHT = 5;      // 프로젝트 클릭(조회) 가중치
  static const int _LIKE_WEIGHT = 10;      // 좋아요 가중치
  static const int _UNLIKE_WEIGHT = -10;   // 좋아요 취소 가중치
  static const int _APPLY_WEIGHT = 15;     // 신청 가중치 (가장 높은 관심도)

  // 2. 태그 매칭 개별 가중치 파라미터 (Tag Score 계산에 사용)
  static const double _SKILL_MATCH_SCORE = 20.0; // 일반 기술 스택 매치당 점수
  static const double _DEPT_MATCH_SCORE = 30.0;  // 학과/핵심 기술(개발, 기획 등) 매치당 보너스 점수
  static const double _MAX_TAG_SCORE = 70.0;     // Tag Score의 최대값 (70점으로 제한)

  // 3. 최종 하이브리드 점수 가중치 (총합 1.0을 유지해야 합니다)
  static const double _TAG_FINAL_WEIGHT = 0.4;
  static const double _EMA_FINAL_WEIGHT = 0.3;
  static const double _NCF_FINAL_WEIGHT = 0.3;

  // =========================================================

  ProjectService() {
    _initializeNcfModel();
  }

  void _initializeNcfModel() async {
    // 앱 시작 시 NCF 가중치 로드 시도
    await NCFModel.ensureLoaded();
  }

  // --- [Helper] 스킬 및 학과 추출 함수 ---
  List<String> _extractSkills(Map<String, dynamic> profile) {
    List<String> skills = [];

    // 1. 기술 스택
    if (profile['tech_stack'] != null) {
      final stackStr = profile['tech_stack'] as String;
      if (stackStr.isNotEmpty) {
        skills.addAll(stackStr.split(',').map((e) => e.trim().toLowerCase()));
      }
    }

    // 2. '학과(Department)'를 강력한 매칭 태그로 추가
    if (profile['department'] != null) {
      final dept = (profile['department'] as String).trim();
      if (dept.isNotEmpty) {
        skills.add(dept.toLowerCase());

        // 학과 기반 핵심 키워드 추가 (Tag Score에서 보너스 점수 부여용)
        if (dept.contains('IT') || dept.contains('컴퓨터')) {
          skills.add('개발');
        } else if (dept.contains('디자인')) {
          skills.add('디자인');
        } else if (dept.contains('경영') || dept.contains('경제')) {
          skills.add('기획');
          skills.add('마케팅');
        }
      }
    }
    return skills.toSet().toList(); // 중복 제거 후 반환
  }

  // --- [Helper] 태그 매칭 점수 계산 (고정 가중치 파라미터 적용) ---
  double _calculateTagScore(List<String> userSkills, String projectTechStack) {
    if (userSkills.isEmpty || projectTechStack.isEmpty) return 0.0;

    final projectTags = projectTechStack.split(',').map((e) => e.trim().toLowerCase()).toList();
    double totalScore = 0.0;

    // 학과/핵심 기술로 분류하여 보너스 점수를 부여할 키워드 목록
    const List<String> deptKeywords = ['개발', '디자인', '기획', '마케팅'];

    for (final s in userSkills) {
      bool isMatched = projectTags.any((tag) => tag.contains(s) || s.contains(tag));

      if (isMatched) {
        // 학과 이름 또는 파생된 핵심 키워드인 경우 (_DEPT_MATCH_SCORE 적용)
        if (deptKeywords.contains(s) || s.endsWith('학과')) {
          totalScore += _DEPT_MATCH_SCORE;
        } else {
          // 일반 기술 스택 매칭 (_SKILL_MATCH_SCORE 적용)
          totalScore += _SKILL_MATCH_SCORE;
        }
      }
    }

    return math.min(totalScore, _MAX_TAG_SCORE); // 최대 점수 제한
  }

  // 사용자 활동 로그 기록 (활동 개별 가중치 파라미터 적용)
  Future<void> logUserAction(String projectId, String actionType) async {
    final userId = currentUserId;
    if (userId == null) return;

    // 💡 [적용] actionType에 따라 정의된 static weight 사용
    int finalWeight = 0;
    switch (actionType) {
      case 'view':
        finalWeight = _VIEW_WEIGHT;
        break;
      case 'like':
        finalWeight = _LIKE_WEIGHT;
        break;
      case 'unlike':
        finalWeight = _UNLIKE_WEIGHT;
        break;
      case 'apply':
        finalWeight = _APPLY_WEIGHT;
        break;
      default:
        return;
    }

    try {
      await _client.from('user_logs').insert({
        'user_id': userId,
        'project_id': projectId,
        'action_type': actionType,
        'score_weight': finalWeight,
      });
    } catch (e) {
      debugPrint('사용자 로그 기록 실패: $e');
    }
  }

  // EMA 가중치 계산 (통계 누적 기반 확률형)
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
      final now = DateTime.now().toLocal();

      const int recentDaysThreshold = 30; // 최근 30일 이내 활동만 반영
      final recentThresholdDate = now.subtract(const Duration(days: recentDaysThreshold));

      double totalRecentWeight = 0.0;

      // 1. 최근 활동 로그의 가중치 합산
      for (var log in logs) {
        final projectId = log['project_id'] as String;
        final scoreWeight = (log['score_weight'] as int).toDouble();
        final createdAt = DateTime.parse(log['created_at'] as String).toLocal();

        if (createdAt.isAfter(recentThresholdDate)) {
          emaWeights[projectId] = (emaWeights[projectId] ?? 0.0) + scoreWeight;
          totalRecentWeight += scoreWeight;
        }
      }

      if (totalRecentWeight == 0.0) return {};

      final normalizedWeights = <String, double>{};

      // 2. 누적된 가중치를 전체 최근 활동량 대비 확률로 정규화 (0.0 ~ 1.0)
      emaWeights.forEach((projectId, weight) {
        normalizedWeights[projectId] = weight / totalRecentWeight;
      });

      return normalizedWeights;
    } catch (e) {
      debugPrint('EMA 가중치 계산 실패: $e');
      return {};
    }
  }

  // 1-1. 프로젝트 목록 조회 (하이브리드 매칭 최종 점수 계산)
  Future<List<Project>> fetchProjects({String? query}) async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      // 1. 내 프로필 로드 (기술스택 + 학과)
      final userProfileResponse = await _client
          .from('profiles')
          .select('tech_stack, department')
          .eq('id', userId)
          .maybeSingle();

      if (userProfileResponse == null) return [];

      final List<String> userSkills = _extractSkills(userProfileResponse);

      // 2. EMA Probability 계산
      final Map<String, double> emaWeights = await _calculateEmaWeights(userId);

      // 3. 프로젝트 데이터 로드 (검색 필터링 포함)
      var dbQuery = _client
          .from('projects')
          .select('*, my_likes:project_likes(user_id)');

      // 검색어 필터링 (제목, 설명, 기술스택 OR 검색)
      if (query != null && query.isNotEmpty) {
        final pattern = '%$query%';
        dbQuery = dbQuery.or('title.ilike.$pattern, description.ilike.$pattern, tech_stack.ilike.$pattern');
      }

      final response = await dbQuery.order('created_at', ascending: false);

      final data = response as List<dynamic>;
      final List<Project> projects = data.map((json) => Project.fromJson(json)).toList();

      if (projects.isEmpty) return [];

      // ---------------------------------------------------------
      // 🧠 최종 하이브리드 점수 계산 (Tag + EMA + NCF)
      // ---------------------------------------------------------

      // NCF 예측 점수 계산 (0.0 ~ 1.0 범위의 확률)
      final List<String> projectIds = projects.map((p) => p.id).toList();
      // 💡 NCFModel.predictBatch는 JSON 가중치를 사용하도록 변경됨
      List<double> ncfProbabilities = await NCFModel.predictBatch(
          userId: userId,
          itemIds: projectIds
      );

      final List<Project> scoredProjects = [];

      for (int i = 0; i < projects.length; i++) {
        final p = projects[i];

        // (1) Tag Score 계산 (0~MAX_TAG_SCORE) -> 0~1.0 범위로 정규화
        final double rawTagScore = _calculateTagScore(userSkills, p.techStack);
        final double normalizedTagScore = rawTagScore / _MAX_TAG_SCORE;

        // (2) EMA Score Probability (0~1.0 확률 값)
        final double emaScoreProbability = emaWeights[p.id] ?? 0.0;

        // (3) NCF 예측 점수 (0~1.0)
        final double ncfScore = ncfProbabilities[i];

        // (4) 최종 하이브리드 점수 (0.0 ~ 1.0)
        double finalScore = (normalizedTagScore * _TAG_FINAL_WEIGHT) +
            (emaScoreProbability * _EMA_FINAL_WEIGHT) +
            (ncfScore * _NCF_FINAL_WEIGHT);

        // 최종 점수를 100점 만점으로 변환
        finalScore = finalScore.clamp(0.0, 1.0) * 100.0;

        scoredProjects.add(p.copyWith(matchScore: finalScore));
      }

      scoredProjects.sort((a, b) => b.matchScore.compareTo(a.matchScore));

      return scoredProjects;

    } catch (e) {
      debugPrint('프로젝트 목록 로드 실패: $e');
      return [];
    }
  }

  // EMA 가중치 계산 (이하 기존 코드 유지)
  // ...

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

  // 1-4. 조회수 증가
  Future<void> incrementViewCount(String projectId) async {
    try {
      await _client.rpc('increment_view_count', params: {'row_id': projectId});
      // 💡 [적용] logUserAction에 상세 actionType 전달
      logUserAction(projectId, 'view');
    } catch (e) {
      debugPrint('조회수 증가 실패: $e');
    }
  }

  // 1-5. 좋아요 토글
  Future<bool> toggleLike(String projectId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    try {
      final result = await _client.rpc('toggle_like', params: {'p_id': projectId});
      final bool isLiked = result as bool;
      // 💡 [적용] logUserAction에 상세 actionType 전달
      logUserAction(projectId, isLiked ? 'like' : 'unlike');
      return isLiked;
    } catch (e) {
      debugPrint('좋아요 토글 실패: $e');
      throw Exception('좋아요 실패');
    }
  }


  // 2-1. 지원하기
  Future<void> applyToProject(String projectId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    try {
      await _client.from('project_applications').insert({
        'project_id': projectId,
        'applicant_id': userId,
        'status': 'pending',
      });
      // 💡 [적용] logUserAction에 상세 actionType 전달
      logUserAction(projectId, 'apply');
    } catch (e) {
      debugPrint('지원 실패: $e');
      throw Exception('이미 지원했거나 오류가 발생했습니다.');
    }
  }

  // 2-2. 지원 여부 확인 (기존 코드 유지)
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

  // 2-3. 지원자 목록 (기존 코드 유지)
  Future<List<Application>> fetchApplications(String projectId) async {
    try {
      final response = await _client
          .from('project_applications')
          .select('*, profiles:applicant_id(username, email, department)')
          .eq('project_id', projectId)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;

      return data.map((json) => Application.fromJson(json)).toList();

    } on PostgrestException catch (e) {
      debugPrint('Postgrest Error fetching applicants: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Generic Error fetching applicants: $e');
      return [];
    }
  }

  // 2-4. 지원 상태 변경 (기존 코드 유지)
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

  // 3-1. 댓글 목록 (기존 코드 유지)
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

  // 3-2. 댓글 작성 (기존 코드 유지)
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

  // 3-3. 댓글 삭제 (기존 코드 유지)
  Future<void> deleteComment(int commentId) async {
    try {
      await _client.from('project_comments').delete().eq('id', commentId);
    } catch (e) {
      debugPrint('댓글 삭제 실패: $e');
      throw Exception('삭제 실패');
    }
  }
}