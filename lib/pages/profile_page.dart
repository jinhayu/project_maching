import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 3단계, 4단계에서 생성할 페이지 (지금은 오류가 나는 것이 정상입니다)
import 'project_page.dart';
import 'scheduler_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  var _loading = true;

  // DB 컬럼에 맞게 컨트롤러 추가
  final _fullNameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _skillsController = TextEditingController(); // (AI 매칭용)
  final _usernameController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    // 모든 컨트롤러를 dispose
    _fullNameController.dispose();
    _departmentController.dispose();
    _skillsController.dispose();
    _usernameController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  // DB에서 프로필 정보를 불러오는 함수
  Future<void> _loadProfile() async {
    final ScaffoldMessengerState scaffoldMessenger =
    ScaffoldMessenger.of(context);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = (await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId) // .match() 대신 .eq()를 권장합니다.
          .maybeSingle());

      if (data != null) {
        setState(() {
          // DB에서 불러온 데이터로 각 입력창의 기본값을 설정
          _fullNameController.text = data['full_name'] ?? '';
          _departmentController.text = data['department'] ?? '';

          // 'skills' (text 배열)를 쉼표(,)로 구분된 하나의 문자열로 변환
          final skillsList = (data['skills'] as List<dynamic>?) ?? [];
          _skillsController.text = skillsList.join(', ');

          _usernameController.text = data['username'] ?? '';
          _websiteController.text = data['website'] ?? '';
        });
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Error occurred while getting profile: $e'),
        backgroundColor: Colors.red,
      ));
    }
    setState(() {
      _loading = false;
    });
  }

  // 프로필 정보를 DB에 저장(업데이트)하는 함수
  Future<void> _updateProfile() async {
    final ScaffoldMessengerState scaffoldMessenger =
    ScaffoldMessenger.of(context);
    try {
      setState(() {
        _loading = true;
      });
      final userId =
          Supabase.instance.client.auth.currentUser!.id;

      // 'skills' 입력창의 문자열을 쉼표(,)로 분리하고 공백을 제거하여 배열로 변환
      final skillsList = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty) // 빈 문자열 제거
          .toList();

      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
        'full_name': _fullNameController.text,
        'department': _departmentController.text,
        'skills': skillsList, // <--- DB에는 배열(List)로 저장
        'username': _usernameController.text,
        'website': _websiteController.text,
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('Saved profile'),
        ));
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Error saving profile: $e'),
        backgroundColor: Colors.red,
      ));
    }
    setState(() {
      _loading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
        actions: [
          // 로그아웃 버튼
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // (제안서 ERD 기준) full_name
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              label: Text('이름 (Full Name)'),
            ),
          ),
          const SizedBox(height: 16),

          // (제안서 ERD 기준) department
          TextFormField(
            controller: _departmentController,
            decoration: const InputDecoration(
              label: Text('학과 (Department)'),
            ),
          ),
          const SizedBox(height: 16),

          // (AI 매칭용) skills
          TextFormField(
            controller: _skillsController,
            decoration: const InputDecoration(
              label: Text('보유 스킬 (Skills)'),
              hintText: '쉼표(,)로 구분 (예: Python, Flutter, SQL)',
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              label: Text('유저명 (Username)'),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _websiteController,
            decoration: const InputDecoration(
              label: Text('웹사이트 (Website)'),
            ),
          ),
          const SizedBox(height: 24),

          // 'Save' 버튼
          ElevatedButton(
              onPressed: _updateProfile, // <--- 저장 함수 호출
              child: const Text('프로필 저장')
          ),

          const SizedBox(height: 16),

          // (3단계에서 생성할) '프로젝트' 페이지로 이동하는 버튼
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProjectPage()),
              );
            },
            child: const Text('프로젝트 목록 보기'),
          ),

          const SizedBox(height: 16),

          // (4단계에서 생성할) '스케줄러' 페이지로 이동하는 버튼
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SchedulerPage()),
              );
            },
            child: const Text('내 스케줄러 열기'),
          ),
        ],
      ),
    );
  }
}