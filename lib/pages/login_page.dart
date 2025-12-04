import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          TextFormField(
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
            decoration: const InputDecoration(label: Text('Email')),
          ),
          const SizedBox(height: 16),
          TextFormField(
            obscureText: true,
            controller: _passwordController,
            decoration: const InputDecoration(label: Text('Password')),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              // 💡 [핵심 해결책]
              // 비동기(await) 작업이 시작되기 전에 context를 사용하는 객체들을
              // 미리 '동기' 구간에서 찾아서 변수에 담아둡니다.
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              setState(() {
                _loading = true;
              });

              try {
                final email = _emailController.text;
                final password = _passwordController.text;

                // ⏳ 비동기 작업
                await Supabase.instance.client.auth.signInWithPassword(
                  email: email,
                  password: password,
                );

                // 💡 이제 context 대신 미리 찾아둔 navigator를 사용합니다.
                // 린터는 이제 async gap 이후에 context가 사용되지 않았다고 판단하므로 경고가 사라집니다.
                navigator.popUntil((route) => route.isFirst);

              } catch (e) {
                // 💡 에러 메시지도 미리 찾아둔 scaffoldMessenger를 사용합니다.
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('로그인 실패: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );

                // setState는 context와 무관하게 State 객체 내부 함수이므로
                // mounted 체크만 있으면 안전합니다.
                if (mounted) {
                  setState(() {
                    _loading = false;
                  });
                }
              }
            },
            child: const Text('Login'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignupPage()),
              );
            },
            child: const Text('아직 계정이 없으신가요? 회원가입'),
          ),
        ],
      ),
    );
  }
}