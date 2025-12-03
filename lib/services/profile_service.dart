import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  // 1. 프로필 조회 (내 프로필 또는 다른 사람 프로필)
  Future<Profile?> fetchProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return Profile.fromJson(response);
    } catch (e) {
      debugPrint('프로필 로드 실패: $e');
      return null;
    }
  }

  // 2. 내 프로필 업데이트
  Future<void> updateProfile({
    required String username,
    required String position,
    required String bio,
    required String techStack,
    required String blogUrl,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    try {
      await _client.from('profiles').update({
        'username': username,
        'position': position,
        'bio': bio,
        'tech_stack': techStack,
        'blog_url': blogUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('프로필 수정 실패: $e');
      throw Exception('프로필 수정 중 오류가 발생했습니다.');
    }
  }
}