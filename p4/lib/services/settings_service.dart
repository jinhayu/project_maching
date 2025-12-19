import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsService {
  final SupabaseClient _client = Supabase.instance.client;

  // 1. 비밀번호 변경
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      debugPrint('비밀번호 변경 실패: $e');
      throw Exception('비밀번호 변경 중 오류가 발생했습니다.');
    }
  }

  // 2. 회원 탈퇴 (데이터 삭제 및 로그아웃)
  Future<void> deleteAccount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('로그인 정보가 없습니다.');

      // 1) 프로필 데이터 삭제 (Cascade 설정이 되어 있다면 연관된 게시글 등도 정리됨)
      await _client.from('profiles').delete().eq('id', userId);

      // 2) 로그아웃 (Auth 계정 삭제는 보안상 Admin 권한 필요, 여기서는 데이터 삭제 후 로그아웃 처리)
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('회원 탈퇴 실패: $e');
      throw Exception('회원 탈퇴 처리에 실패했습니다.');
    }
  }

  // 3. 현재 앱 버전 정보 (하드코딩 혹은 package_info_plus 사용 가능)
  String getAppVersion() {
    return "1.0.0";
  }
}