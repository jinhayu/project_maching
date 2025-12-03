import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import 'profile/profile_edit_page.dart'; // 수정 페이지 import

class ProfilePage extends StatefulWidget {
  final String? userId; // null이면 '내 프로필'

  const ProfilePage({Key? key, this.userId}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _profileService = ProfileService();
  Profile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    // userId가 전달되지 않았으면, 현재 로그인한 유저 ID 사용
    final targetId = widget.userId ?? _profileService.currentUserId;

    if (targetId != null) {
      final profile = await _profileService.fetchProfile(targetId);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMyProfile = widget.userId == null || widget.userId == _profileService.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // 내 프로필일 때만 '수정' 버튼 표시
          if (isMyProfile && !_isLoading && _profile != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: '프로필 수정',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileEditPage(profile: _profile!),
                  ),
                );
                // 수정 후 돌아왔을 때 데이터 새로고침
                if (result == true) _loadProfile();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
          ? const Center(child: Text('프로필 정보를 불러올 수 없습니다.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 아바타 및 기본 정보
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blueGrey,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _profile!.username ?? '이름 없음',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _profile!.email ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _profile!.position?.isNotEmpty == true ? _profile!.position! : '직군 미설정',
                      style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 상세 정보 섹션
            const Text('자기소개', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _profile!.bio?.isNotEmpty == true ? _profile!.bio! : '자기소개가 없습니다.',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),

            const Divider(height: 40),

            const Text('기술 스택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _profile!.techStack?.isNotEmpty == true ? _profile!.techStack! : '등록된 기술 스택이 없습니다.',
              style: const TextStyle(fontSize: 16),
            ),

            const Divider(height: 40),

            const Text('포트폴리오 / 링크', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _profile!.blogUrl?.isNotEmpty == true ? _profile!.blogUrl! : '등록된 링크가 없습니다.',
              style: const TextStyle(fontSize: 16, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}