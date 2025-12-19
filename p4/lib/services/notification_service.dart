import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _client = Supabase.instance.client;
  String? get currentUserId => _client.auth.currentUser?.id;

  // 1. 내 알림 목록 가져오기 (최신순)
  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      if (currentUserId == null) return [];

      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false);

      // Supabase v2에서 response는 바로 List<dynamic>입니다.
      final data = response as List<dynamic>;
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('알림 로드 실패: $e');
      return [];
    }
  }

  // 2. 알림 읽음 처리
  Future<void> markAsRead(int notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('읽음 처리 실패: $e');
    }
  }

  // 3. 알림 보내기 (다른 유저에게)
  Future<void> sendNotification({
    required String receiverId,
    required String title,
    required String content,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': receiverId,
        'title': title,
        'content': content,
        'is_read': false,
      });
    } catch (e) {
      debugPrint('알림 전송 실패: $e');
    }
  }

  // 4. 읽지 않은 알림 개수 확인 (뱃지용)
  Future<int> getUnreadCount() async {
    try {
      if (currentUserId == null) return 0;

      // 💡 FIX: FetchOptions 대신 .count() 메서드 사용 (오류 해결)
      // 이렇게 하면 데이터 리스트 대신 개수(int)를 바로 반환합니다.
      final count = await _client
          .from('notifications')
          .count(CountOption.exact)
          .eq('user_id', currentUserId!)
          .eq('is_read', false);

      return count;
    } catch (e) {
      debugPrint('알림 개수 확인 실패: $e');
      return 0;
    }
  }
}