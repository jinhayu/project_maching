import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_page.dart';
import 'main_page.dart'; // MainPage 클래스 호출을 위한 import

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  User? _user;
  bool _loading = true; // 초기 로딩 상태

  @override
  void initState() {
    super.initState();
    _getAuth();
  }

  Future<void> _getAuth() async {
    // 💡 Context/Async 경고 해결
    if (!mounted) return;

    // 1. 현재 로그인된 사용자 상태 즉시 확인
    setState(() {
      _user = Supabase.instance.client.auth.currentUser;
      _loading = false;
    });

    // 2. 로그인/로그아웃 상태 변화를 실시간으로 감지하고 UI 업데이트
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      // 💡 Context/Async 경고 해결
      if (!mounted) return;

      setState(() {
        _user = data.session?.user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중일 경우 (초기 Supabase 상태 확인)
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 로그인 상태에 따른 페이지 분기
    // - 로그인되어 있지 않다면 SplashPage (로그인/회원가입)
    // - 로그인되어 있다면 MainPage (메인 대시보드)
    return _user == null ? const SplashPage() : const MainPage();
  }
}