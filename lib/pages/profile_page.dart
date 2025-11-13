import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_page.dart';
import 'project_page.dart';
import 'scheduler_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  var _loading = true;

  final _fullNameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _skillsController = TextEditingController();
  final _usernameController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 💡 위젯 초기화 시 프로필 로드 시작
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _departmentController.dispose();
    _skillsController.dispose();
    _usernameController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  /// DB에서 프로필 정보를 불러오는 함수 (무한 로딩 방지 구조)
  Future<void> _loadProfile() async {
    // 💡 로딩 시작
    setState(() {
      _loading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = (await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle());

      if (data != null && mounted) {
        setState(() {
          _fullNameController.text = data['full_name'] ?? '';
          _departmentController.text = data['department'] ?? '';
          final skillsList = (data['skills'] as List<dynamic>?) ?? [];
          _skillsController.text = skillsList.join(', ');
          _usernameController.text = data['username'] ?? '';
          _websiteController.text = data['website'] ?? '';
        });
      }
    } catch (error) {
      // 💥 FIX: Context 경고 해결 및 오류 발생 시 메시지 표시
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('프로필 로딩 오류: $error'),
            backgroundColor: Colors.red,
          ));
        });
      }
    } finally {
      // 💥 FIX: finally 블록에서 반드시 로딩 상태 해제 (무한 로딩 방지)
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// 프로필 정보를 DB에 저장(업데이트)하는 함수
  Future<void> _updateProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final skillsList = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
        'full_name': _fullNameController.text,
        'department': _departmentController.text,
        'skills': skillsList,
        'username': _usernameController.text,
        'website': _websiteController.text,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('프로필이 성공적으로 저장되었습니다.'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('프로필 저장 오류: $error'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// 로그아웃 함수
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
    // 💡 고정된 밝은 테마 색상 정의
    const Color scaffoldBgColor = Colors.white;
    const Color appBarColor = Colors.white;
    const Color textColor = Colors.black;
    final Color iconColor = Colors.grey.shade600;
    final Color hintColor = Colors.grey.shade400;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        title: const Text('프로필 수정 (MVP)', style: TextStyle(color: textColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: iconColor),
            onPressed: _signOut,
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: iconColor))
          : ListView(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // 타이틀 텍스트
          Text(
            '${_usernameController.text.isNotEmpty ? _usernameController.text : '사용자'}님의 정보를 수정하세요.',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 24),

          // --- Form Fields with Fixed Colors ---
          TextFormField(
            controller: _fullNameController,
            style: const TextStyle(color: textColor),
            decoration: InputDecoration(
              label: const Text('이름 (Full Name)'),
              labelStyle: TextStyle(color: hintColor),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _departmentController,
            style: const TextStyle(color: textColor),
            decoration: InputDecoration(
              label: const Text('학과 (Department)'),
              labelStyle: TextStyle(color: hintColor),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _skillsController,
            style: const TextStyle(color: textColor),
            decoration: InputDecoration(
              label: const Text('보유 스킬 (Skills)'),
              hintText: '쉼표(,)로 구분 (예: Python, Flutter, SQL)',
              labelStyle: TextStyle(color: hintColor),
              hintStyle: TextStyle(color: hintColor),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _usernameController,
            style: const TextStyle(color: textColor),
            decoration: InputDecoration(
              label: const Text('유저명 (Username)'),
              labelStyle: TextStyle(color: hintColor),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _websiteController,
            style: const TextStyle(color: textColor),
            decoration: InputDecoration(
              label: const Text('웹사이트 (Website)'),
              labelStyle: TextStyle(color: hintColor),
            ),
          ),
          const SizedBox(height: 24),

          // 'Save' 버튼
          ElevatedButton.icon(
              icon: const Icon(Icons.save),
              onPressed: _updateProfile,
              label: const Text('프로필 저장')),

          const Divider(height: 48),

          // --- Navigation Buttons (고정 Light Theme) ---
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // 💥 isDarkMode 인수 제거 유지
                    builder: (context) => const ProjectPage()),
              );
            },
            child: const Text('프로젝트 매칭 페이지로 이동'),
          ),

          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SchedulerPage()),
              );
            },
            child: const Text('스케줄/진행률 페이지로 이동'),
          ),
        ],
      ),
    );
  }
}