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
              setState(() {
                _loading = true;
              });

              try {
                final email = _emailController.text;
                final password = _passwordController.text;

                await Supabase.instance.client.auth.signUp(
                  email: email,
                  password: password,
                );

                // 💥 Context 경고 해결: 비동기 갭 이후 mounted 체크 추가
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      '회원가입 성공! 이메일 인증을 확인하세요.'),
                  backgroundColor: Colors.green,
                ));
                Navigator.pop(context);

              } catch (e) {
                // 💥 Context 경고 해결: 비동기 갭 이후 mounted 체크 추가
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('회원가입 실패: $e'),
                  backgroundColor: Colors.red,
                ));
              }
              setState(() {
                _loading = false;
              });
            },
            child: const Text('Signup'),
          ),
        ],
      ),
    );
  }
}