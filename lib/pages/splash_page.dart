import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';   // <--- 우리가 만든 페이지 import
import 'profile_page.dart';  // <--- 우리가 만든 페이지 import

// 'MyWidget'의 이름을 'SplashPage'로 변경했습니다.
class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  User? _user;
  @override
  void initState() {
    _getAuth();
    super.initState();
  }

  Future<void> _getAuth() async {
    setState(() {
      _user = Supabase.instance.client.auth.currentUser;
    });
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      setState(() {
        _user = data.session?.user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold는 LoginPage와 ProfilePage가 각자 가지도록 여기서 제거합니다.
    // 로그인 상태에 따라 LoginPage 또는 ProfilePage를 보여줍니다.
    return _user == null ? const LoginPage() : const ProfilePage();
  }
}