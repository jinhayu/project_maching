import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart'; // 💡 FIX: 모델 사용을 위해 import 유지

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;
  String? get currentUserId => _client.auth.currentUser?.id;

  // 1. 프로필 조회 (내 프로필 또는 다른 사람 프로필)
  // 💡 FIX: 누락된 fetchProfile 메서드 추가
  Future<Profile?> fetchProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle(); // single 대신 maybeSingle 사용하여 데이터가 없을 때 오류 방지

      if (response == null) return null;

      return Profile.fromJson(response);
    } catch (e) {
      debugPrint('프로필 로드 실패: $e');
      return null;
    }
  }

  // 2. 내 프로필 업데이트 (학과 정보 포함)
  Future<void> updateProfile({
    required String username,
    required String department, // 💡 FIX: position -> department로 변경
    required String bio,
    required String techStack,
    required String blogUrl,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    try {
      await _client.from('profiles').update({
        'username': username,
        'department': department, // 💡 FIX: DB 키도 department로 변경
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