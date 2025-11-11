import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// '_LoginForm'의 이름을 'LoginPage'로 변경했습니다.
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
      appBar: AppBar(title: const Text('로그인 또는 회원가입')),
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
              final ScaffoldMessengerState scaffoldMessenger =
              ScaffoldMessenger.of(context);
              try {
                final email = _emailController.text;
                final password = _passwordController.text;
                await Supabase.instance.client.auth.signInWithPassword(
                  email: email,
                  password: password,
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(const SnackBar(
                  content: Text('Login failed'),
                  backgroundColor: Colors.red,
                ));
                setState(() {
                  _loading = false;
                });
              }
              // 로그인 성공 시 SplashPage가 알아서 상태를 변경하므로,
              // 여기서 _loading을 false로 되돌릴 필요가 없습니다. (성공 시)
            },
            child: const Text('Login'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () async {
              setState(() {
                _loading = true;
              });
              final ScaffoldMessengerState scaffoldMessenger =
              ScaffoldMessenger.of(context);
              try {
                final email = _emailController.text;
                final password = _passwordController.text;
                await Supabase.instance.client.auth.signUp(
                  email: email,
                  password: password,
                );
                // 회원가입 성공 시 확인 이메일을 보냈다는 메시지 표시
                scaffoldMessenger.showSnackBar(const SnackBar(
                  content: Text('Signup successful! Check your email for verification.'),
                ));
              } catch (e) {
                scaffoldMessenger.showSnackBar(const SnackBar(
                  content: Text('Signup failed'),
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