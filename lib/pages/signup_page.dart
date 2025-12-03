import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
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
        title: const Text('회원가입'),
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
              // 💡 [핵심] context를 사용하는 객체들을 await 전에 미리 변수에 담아둡니다.
              // 이렇게 하면 비동기 작업 후에 context를 직접 참조하지 않아 경고가 사라집니다.
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              setState(() {
                _loading = true;
              });

              try {
                final email = _emailController.text;
                final password = _passwordController.text;

                // ⏳ 비동기 작업 (회원가입)
                await Supabase.instance.client.auth.signUp(
                  email: email,
                  password: password,
                );

                // 안전을 위해 mounted 체크는 유지합니다.
                if (!mounted) return;

                // 💡 context 대신 미리 만들어둔 변수(scaffoldMessenger)를 사용합니다.
                scaffoldMessenger.showSnackBar(const SnackBar(
                  content: Text('회원가입 성공! 이메일 인증을 확인하세요.'),
                  backgroundColor: Colors.green,
                ));

                // 💡 context 대신 미리 만들어둔 변수(navigator)를 사용합니다.
                navigator.pop();

              } catch (e) {
                if (!mounted) return;

                // 에러 메시지 표시
                scaffoldMessenger.showSnackBar(SnackBar(
                  content: Text('회원가입 실패: $e'),
                  backgroundColor: Colors.red,
                ));

                setState(() {
                  _loading = false;
                });
              }
            },
            child: const Text('Signup'),
          ),
        ],
      ),
    );
  }
}