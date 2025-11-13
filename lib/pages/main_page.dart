import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_page.dart';
import 'project_page.dart';
import 'scheduler_page.dart';
import 'splash_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // 1. 사용자 이름과 로딩 상태만 유지
  String _userName = '사용자';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // 2. Supabase에서 사용자 프로필을 가져오는 함수
  Future<void> _fetchUserProfile() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null || !mounted) return;

    try {
      final userId = currentUser.id;
      final response = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _userName = response['username'] ?? '사용자';
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _userName = '이름 로드 오류';
          _isLoading = false;
        });
        // print 대신 debugPrint가 Material.dart에 포함되므로 import 제거
        // debugPrint('Error fetching profile: $error');
      }
    }
  }

  // 3. 프로젝트 피드 새로고침 (MVP Placeholder)
  void _refreshProjects(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로젝트 피드 새로고침 기능 (MVP)'))
    );
  }

  // 4. 네비게이션 함수들
  void _navigateToProfile() {
    Navigator.push(
      context,
      // 💥 isDarkMode 인수가 제거된 ProfilePage 호출
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  }

  void _navigateToScheduler() {
    Navigator.push(
      context,
      // 💥 isDarkMode 인수가 제거된 SchedulerPage 호출
      MaterialPageRoute(builder: (context) => const SchedulerPage()),
    );
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 실패: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SplashPage()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor = Colors.grey.shade600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),

        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 100.0),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 좌측: 앱 타이틀
              const Text(
                '시너지',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // 우측: 아이콘 및 버튼 그룹
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. 프로필 아이콘
                  IconButton(
                    icon: Icon(Icons.person_outline, color: iconColor),
                    tooltip: '프로필 보기/수정',
                    onPressed: _navigateToProfile,
                  ),

                  // 2. 프로젝트 아이콘
                  IconButton(
                    icon: Icon(Icons.dashboard_outlined, color: iconColor),
                    tooltip: '프로젝트 피드 새로고침',
                    onPressed: () => _refreshProjects(context),
                  ),

                  // 3. 스케줄러 아이콘
                  IconButton(
                    icon: Icon(Icons.calendar_today_outlined, color: iconColor),
                    tooltip: '스케줄러',
                    onPressed: _navigateToScheduler,
                  ),

                  const VerticalDivider(
                    width: 20,
                    indent: 12,
                    endIndent: 12,
                    color: Color.fromARGB(255, 233, 233, 233),
                  ),
                  // 로그아웃 버튼
                  Padding(
                    padding: const EdgeInsets.only(right: 0.0),
                    child: TextButton(
                      onPressed: _signOut,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        overlayColor: Colors.grey[100],
                      ),
                      child: const Text(
                        '로그아웃',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: const [],
      ),

      // 3. 본문: 1:3:1 비율의 3단 카드 레이아웃
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 100.0),

          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------
              // 단 1: 좌측 카드 (프로필) - Flex 1
              // ----------------------------------------------------
              Expanded(
                flex: 1,
                child: Card(
                  color: Colors.white,
                  margin: const EdgeInsets.fromLTRB(8.0, 8.0, 4.0, 8.0),
                  elevation: 1.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  clipBehavior: Clip.antiAlias,

                  child: _isLoading
                      ? const Center(child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator()))
                      : ListView(
                    padding: const EdgeInsets.all(0),
                    shrinkWrap: true,
                    children: [

                      // '로그인 정보' 섹션 (프로필 페이지로 이동)
                      InkWell(
                        onTap: _navigateToProfile,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Colors.blueGrey,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Text(
                                      '프로필 보기/수정',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // '절반 크기'를 위한 이벤트 섹션
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
                        child: Text(
                          '⚡️ 지금 참여가능한 이벤트 (MVP)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),

                      ListTile(
                        dense: true,
                        leading: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.campaign, color: Colors.red, size: 20),
                        ),
                        title: const Text('프로덕트헌트 투표', style: TextStyle(fontSize: 13)),
                        subtitle: const Text('내 프로젝트 등록', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        onTap: () {},
                      ),
                      const SizedBox(height: 8.0),
                    ],
                  ),
                ),
              ),

              // ----------------------------------------------------
              // 단 2: 중앙 카드 (프로젝트 피드) - Flex 3
              // ----------------------------------------------------
              Expanded(
                flex: 3,
                child: Card(
                  color: Colors.deepPurple[50],
                  margin: const EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
                  elevation: 1.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: const ProjectPage(),
                ),
              ),

              // ----------------------------------------------------
              // 단 3: 우측 '빈 카드' (레이아웃 홀더) - Flex 1
              // ----------------------------------------------------
              Expanded(
                flex: 1,
                child: Card(
                  color: Colors.white,
                  margin: const EdgeInsets.fromLTRB(4.0, 8.0, 8.0, 8.0),
                  elevation: 1.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  clipBehavior: Clip.antiAlias,

                  // 높이 2배를 위한 더미 콘텐츠 추가
                  child: ListView(
                    padding: const EdgeInsets.all(0),
                    shrinkWrap: true,
                    children: [
                      // 섹션 1
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                        child: Text(
                          '우측 상단 서비스 (Placeholder)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
                        ),
                      ),
                      ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.star)),
                        title: const Text('인기 서비스 1'),
                        subtitle: const Text('더미 데이터 1'),
                        onTap: () {},
                      ),
                      ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.lightbulb)),
                        title: const Text('프로젝트 1'),
                        subtitle: const Text('더미 데이터 2'),
                        onTap: () {},
                      ),
                      const Divider(),

                      // 섹션 2
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                        child: Text(
                          '우측 하단 광고/이벤트 (Placeholder)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
                        ),
                      ),
                      Container(
                        height: 60,
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '광고 배너 Placeholder',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}