import 'package:flutter/material.dart';
import 'login_page.dart'; // <--- 4. 로그인 페이지를 import

// 이 페이지가 이제 '서비스 소개' 페이지입니다.
class SplashPage extends StatelessWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FlutterLogo(size: 100), // <--- TODO: 여기에 멋진 로고
              const SizedBox(height: 24),
              const Text(
                '프로젝트 매칭 시스템',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '다양한 전공의 학생들과 만나\n새로운 프로젝트를 시작해보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // 버튼 크기
                ),
                onPressed: () {
                  // '로그인 버튼'을 누르면 'LoginPage'로 이동합니다.
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text('로그인 또는 회원가입'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}