import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';

class BoardService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  // 1. 게시글 목록 조회 (작성자 닉네임 포함)
  Future<List<Post>> fetchPosts(String projectId) async {
    try {
      final response = await _client
          .from('project_posts')
          .select('*, profiles(username)') // profiles 테이블과 조인
          .eq('project_id', projectId)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((json) => Post.fromJson(json)).toList();
    } catch (e) {
      debugPrint('게시글 로드 실패: $e');
      return [];
    }
  }

  // 2. 게시글 작성
  Future<void> createPost({
    required String projectId,
    required String title,
    required String content,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    try {
      await _client.from('project_posts').insert({
        'project_id': projectId,
        'author_id': userId,
        'title': title,
        'content': content,
      });
    } catch (e) {
      debugPrint('게시글 작성 실패: $e');
      throw Exception('작성에 실패했습니다.');
    }
  }

  // 3. 게시글 삭제
  Future<void> deletePost(int postId) async {
    try {
      await _client.from('project_posts').delete().eq('id', postId);
    } catch (e) {
      debugPrint('삭제 실패: $e');
      throw Exception('삭제하지 못했습니다.');
    }
  }

  // 4. 내가 팀원인지 확인 (게시판 입장 권한 체크용)
  Future<bool> isTeamMember(String projectId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      final response = await _client
          .from('team_members')
          .select('id')
          .eq('project_id', projectId)
          .eq('user_id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }
}