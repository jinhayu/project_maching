import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_page.dart';
import 'project/project_list_page.dart';
import 'scheduler_page.dart';
import 'splash_page.dart'; // 💡 FIX: 경로 수정 (같은 폴더 내 파일)
import 'notification_page.dart';
import '../services/notification_service.dart';
import 'settings/settings_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _userName = '사용자';
  bool _isLoading = true;

  int _unreadNotifications = 0;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _checkUnreadNotifications();
  }

  Future<void> _checkUnreadNotifications() async {
    final count = await _notificationService.getUnreadCount();
    if (mounted) {
      setState(() => _unreadNotifications = count);
    }
  }

  Future<void> _fetchUserProfile() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null || !mounted) return;

    try {
      if (mounted) {
        setState(() {
          _userName = currentUser.email?.split('@')[0] ?? '사용자';
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _userName = '이름 로드 오류';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    ).then((_) => _fetchUserProfile());
  }

  void _navigateToScheduler() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SchedulerPage()),
    );
  }

  Future<void> _navigateToNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationPage()),
    );
    _checkUnreadNotifications();
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (error) {
      // 💡 FIX: 에러 발생 시에도 mounted 체크
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그아웃 실패')));
      }
      return; // 에러 발생 시 중단
    }

    // 💡 FIX: 비동기 작업(signOut) 후 context 사용 전 mounted 체크
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const SplashPage()),
          (route) => false,
    );
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
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '시너지',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.notifications_outlined, color: iconColor),
                        tooltip: '알림 센터',
                        onPressed: _navigateToNotifications,
                      ),
                      if (_unreadNotifications > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                          ),
                        ),
                    ],
                  ),

                  IconButton(
                    icon: Icon(Icons.person_outline, color: iconColor),
                    tooltip: '프로필',
                    onPressed: _navigateToProfile,
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today_outlined, color: iconColor),
                    tooltip: '스케줄러',
                    onPressed: _navigateToScheduler,
                  ),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: iconColor),
                    tooltip: '설정',
                    onPressed: _navigateToSettings,
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _signOut,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                    child: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _SideCard(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF2563EB),
                        radius: 30,
                        child: Icon(Icons.person, color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _userName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: _navigateToProfile,
                        child: const Text('내 프로필 관리 >'),
                      )
                    ],
                  ),
                ),
              ),

              const Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    elevation: 0,
                    color: Colors.transparent,
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: ProjectListPage(),
                  ),
                ),
              ),

              Expanded(
                flex: 1,
                child: _SideCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('빠른 실행', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _QuickMenu(
                          icon: Icons.calendar_month_outlined,
                          label: '내 일정 확인',
                          onTap: _navigateToScheduler
                      ),
                      const SizedBox(height: 8),
                      _QuickMenu(
                          icon: Icons.settings_outlined,
                          label: '계정 설정',
                          onTap: _navigateToSettings
                      ),
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

class _SideCard extends StatelessWidget {
  final Widget child;
  const _SideCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: child,
      ),
    );
  }
}

class _QuickMenu extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickMenu({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF2563EB)),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}