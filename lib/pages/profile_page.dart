import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import 'profile/profile_edit_page.dart';

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

    final targetId = widget.userId ?? _profileService.currentUserId;

    if (targetId != null) {
      try {
        final profile = await _profileService.fetchProfile(targetId);
        if (mounted) {
          setState(() {
            _profile = profile;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMyProfile = widget.userId == null || widget.userId == _profileService.currentUserId;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          if (isMyProfile && !_isLoading && _profile != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: '프로필 수정',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileEditPage(profile: _profile!)),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 1. 상단 프로필 카드 (명함 스타일)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  // 프로필 이미지 (이니셜 또는 아이콘)
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                    child: Icon(Icons.person, size: 60, color: theme.primaryColor),
                  ),
                  const SizedBox(height: 24),

                  // 닉네임
                  Text(
                    _profile!.username ?? '이름 없음',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // 💡 FIX: 학부/학과 표시 (department 사용)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _profile!.department?.isNotEmpty == true ? _profile!.department! : '학과 미설정',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 이메일
                  Text(
                    _profile!.email ?? '',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 2. 상세 정보 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 자기소개
                  _SectionTitle(title: '자기소개', icon: Icons.format_quote_rounded),
                  const SizedBox(height: 12),
                  Text(
                    _profile!.bio?.isNotEmpty == true ? _profile!.bio! : '자기소개가 없습니다.',
                    style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF374151)),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(),
                  ),

                  // 기술 스택
                  _SectionTitle(title: '기술 스택', icon: Icons.code_rounded),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _profile!.techStack?.isNotEmpty == true
                        ? _profile!.techStack!.split(',').map((t) => Chip(
                      label: Text(t.trim()),
                      backgroundColor: Colors.grey[50],
                      labelStyle: TextStyle(color: Colors.grey[800], fontSize: 13),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    )).toList()
                        : [const Text('등록된 기술이 없습니다.', style: TextStyle(color: Colors.grey))],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(),
                  ),

                  // 링크
                  _SectionTitle(title: '링크', icon: Icons.link_rounded),
                  const SizedBox(height: 12),
                  if (_profile!.blogUrl?.isNotEmpty == true)
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('링크 이동 기능은 추후 구현됩니다.')));
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          _profile!.blogUrl!,
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.primaryColor,
                            decoration: TextDecoration.underline,
                            decorationColor: theme.primaryColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    )
                  else
                    const Text('등록된 링크가 없습니다.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// 섹션 타이틀 위젯 (재사용)
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.grey[700]),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}