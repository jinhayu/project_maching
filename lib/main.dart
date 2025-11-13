import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/auth_gate_page.dart'; // <--- '인증 관문'을 import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드
  await dotenv.load(fileName: ".env");

  // Supabase 초기화 (URL/Key는 .env에서)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false, // 디버그 배너 숨기기
      title: '프로젝트 매칭 시스템',

      // 💡 FIX 1: 테마 모드를 Light로 고정
      themeMode: ThemeMode.light,

      // 💡 FIX 2: 기본 Light Theme 정의 (기존 darkTheme 제거)
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // AppBar 배경을 흰색으로 설정
          foregroundColor: Colors.black,  // AppBar 아이콘/텍스트 색상을 검은색으로 설정
          elevation: 1,
        ),
        scaffoldBackgroundColor: Colors.grey[50], // 연한 회색 배경
      ),

      // 참고: darkTheme 속성은 이제 무시됩니다.

      home: const AuthGate(), // 앱의 첫 화면을 'AuthGate'로 유지
    );
  }
}