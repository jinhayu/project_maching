import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';
import '../models/application_model.dart';
import '../models/comment_model.dart'; // 💡 댓글 모델 import

class ProjectService {
  final SupabaseClient _client = Supabase.instance.client;

  // 현재 로그인한 사용자 ID
  String? get currentUserId => _client.auth.currentUser?.id;

  // ====================================================
  // 1. 프로젝트 기본 기능 (조회, 생성, 삭제, 좋아요, 조회수)
  // ====================================================

  // 1-1. 프로젝트 목록 조회 (검색 기능 포함)
  // query가 비어있으면 전체 목록, 있으면 제목 검색
  Future<List<Project>> fetchProjects({String? query}) async {
    try {
      final userId = currentUserId;

      // 기본 쿼리: 전체 목록 + 좋아요 정보
      var dbQuery = _client
          .from('projects')
          .select('*, my_likes:project_likes(user_id)');

      // 💡 검색어가 있으면 제목(title)에서 검색 (ilike: 대소문자 구분 없음)
      if (query != null && query.isNotEmpty) {
        dbQuery = dbQuery.ilike('title', '%$query%');
      }

      final response = await dbQuery
          .eq('my_likes.user_id', userId ?? '')
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((json) => Project.fromJson(json)).toList();
    } catch (e) {
      debugPrint('목록 로드 실패: $e');
      // 에러 시 빈 리스트 반환하여 앱이 죽지 않게 처리
      return [];
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

  // 1-4. 조회수 증가
  Future<void> incrementViewCount(String projectId) async {
    try {
      await _client.rpc('increment_view_count', params: {'row_id': projectId});
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
      return result as bool;
    } catch (e) {
      debugPrint('좋아요 토글 실패: $e');
      throw Exception('좋아요 실패');
    }
  }


  // ====================================================
  // 2. 지원 및 매칭 기능
  // ====================================================

  // 2-1. 프로젝트에 지원하기
  Future<void> applyToProject(String projectId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    try {
      await _client.from('project_applications').insert({
        'project_id': projectId,
        'applicant_id': userId,
        'status': 'pending',
      });
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
          .select('*, profiles(username, email)')
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


  // ====================================================
  // 3. 댓글 기능 (새로 추가됨)
  // ====================================================

  // 3-1. 댓글 목록 조회
  Future<List<Comment>> fetchComments(String projectId) async {
    try {
      final response = await _client
          .from('project_comments')
          .select('*, profiles(username)') // 작성자 이름(username) 가져오기
          .eq('project_id', projectId)
          .order('created_at', ascending: true); // 오래된 순(먼저 쓴 댓글이 위로)

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