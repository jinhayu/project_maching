import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  // 입력 컨트롤러
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController(); // 이름(닉네임)

  // 학과 선택
  String? _selectedDepartment;
  final List<String> _departmentOptions = [
    'IT/컴퓨터/SW (컴공, AI, 소웨 등)',
    '디자인/조형예술 (시각, 산업, UI/UX 등)',
    '미디어/콘텐츠/언론 (광고, 영상, 신방 등)',
    '경영/경제/마케팅 (경영, 경제, 회계 등)',
    '기계/전자/건축 (기계, 전기, 토목 등)',
    '화학/생명/환경 (화공, 신소재, 바이오 등)',
    '인문/어문/교육 (국문, 영문, 교육 등)',
    '사회과학/심리 (심리, 사회, 행정 등)',
    '의학/간호/보건 (간호, 스포츠, 보건 등)',
    '기타 (자율전공, 예체능 등)',
  ];

  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학과를 선택해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // 1. 회원가입 (계정 생성)
      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = res.user;
      if (user == null) {
        throw Exception('회원가입 실패: 유저 정보가 없습니다.');
      }

      // 2. 💡 [핵심 수정] 프로필 정보 직접 저장 (DB 트리거 대신 수행)
      // 이제 DB가 꼬여도 앱에서 직접 넣기 때문에 성공합니다.
      await supabase.from('profiles').insert({
        'id': user.id,
        'email': user.email,
        'username': _usernameController.text.trim(),
        'department': _selectedDepartment,
        'tech_stack': '', // 초기값 빈 문자열
        // 'created_at'은 DB에서 자동 생성됨
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공! 로그인해주세요.')),
        );
        Navigator.pop(context); // 로그인 페이지로 돌아가기
      }

    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('가입 실패: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 이메일
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: '이메일', prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => (val == null || !val.contains('@')) ? '유효한 이메일을 입력하세요' : null,
              ),
              const SizedBox(height: 16),

              // 비밀번호
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: '비밀번호 (6자 이상)', prefixIcon: Icon(Icons.lock)),
                obscureText: true,
                validator: (val) => (val == null || val.length < 6) ? '6자 이상 입력하세요' : null,
              ),
              const SizedBox(height: 16),

              // 이름(닉네임)
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: '이름 (닉네임)', prefixIcon: Icon(Icons.person)),
                validator: (val) => (val == null || val.isEmpty) ? '이름을 입력하세요' : null,
              ),
              const SizedBox(height: 16),

              // 학과 선택
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '학과 (전공 계열)', prefixIcon: Icon(Icons.school)),
                items: _departmentOptions.map((dept) {
                  return DropdownMenuItem(
                    value: dept,
                    child: Text(dept.split(' ')[0], overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedDepartment = val),
              ),
              const SizedBox(height: 8),
              const Text("※ 융합 프로젝트 매칭을 위해 가장 가까운 계열을 선택해주세요.", style: TextStyle(fontSize: 12, color: Colors.grey)),

              const SizedBox(height: 32),

              // 가입 버튼
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('회원가입 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}