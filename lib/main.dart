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
      theme: ThemeData.dark(), // 다크 모드
      home: const AuthGate(), // <--- 앱의 첫 화면을 'AuthGate'로 변경
    );
  }
}