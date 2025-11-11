import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <--- 1. import 추가
import 'pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. .env 파일 로드 (Supabase 초기화 전에)
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    // 3. .env 파일에서 변수 이름으로 키 가져오기
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Supabase Flutter Demo',
      home: SplashPage(),
    );
  }
}