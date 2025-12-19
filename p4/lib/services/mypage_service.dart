import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';
import '../models/application_model.dart';

class MyPageService {
  final SupabaseClient _client = Supabase.instance.client;
  String? get currentUserId => _client.auth.currentUser?.id;

  // 1. 내가 만든 프로젝트 (Created)
  Future<List<Project>> fetchCreatedProjects() async {
    try {
      if (currentUserId == null) return [];

      final response = await _client
          .from('projects')
          .select()
          .eq('owner_id', currentUserId!)
          .order('created_at', ascending: false);

      return (response as List).map((e) => Project.fromJson(e)).toList();
    } catch (e) {
      debugPrint('내가 만든 프로젝트 로드 실패: $e');
      return [];
    }
  }

  // 2. 내가 참여 중인 프로젝트 (Participating)
  // team_members 테이블을 통해 projects 테이블을 조인해서 가져옴
  Future<List<Project>> fetchParticipatingProjects() async {
    try {
      if (currentUserId == null) return [];

      final response = await _client
          .from('team_members')
          .select('projects(*)') // projects 테이블의 모든 컬럼 가져오기
          .eq('user_id', currentUserId!)
          .order('joined_at', ascending: false);

      final List<Project> projects = [];
      for (var item in response) {
        if (item['projects'] != null) {
          projects.add(Project.fromJson(item['projects']));
        }
      }
      return projects;
    } catch (e) {
      debugPrint('참여 프로젝트 로드 실패: $e');
      return [];
    }
  }

  // 3. 나의 지원 현황 (Applications)
  // project_applications 테이블에서 projects 정보를 조인해서 가져옴
  Future<List<Application>> fetchMyApplications() async {
    try {
      if (currentUserId == null) return [];

      final response = await _client
          .from('project_applications')
          .select('*, projects(*)') // projects 테이블 조인
          .eq('applicant_id', currentUserId!)
          .order('created_at', ascending: false);

      return (response as List).map((e) => Application.fromJson(e)).toList();
    } catch (e) {
      debugPrint('지원 현황 로드 실패: $e');
      return [];
    }
  }
}