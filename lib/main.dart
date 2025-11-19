import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// 📅 날짜 포맷팅 초기화
import 'package:intl/date_symbol_data_local.dart';
// 🔤 폰트 패키지
import 'package:google_fonts/google_fonts.dart';
import 'pages/auth_gate_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. .env 파일 로드
  await dotenv.load(fileName: ".env");

  // 2. 날짜 포맷팅 데이터 초기화
  await initializeDateFormatting();

  // 3. Supabase 초기화
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
      debugShowCheckedModeBanner: false, // 디버그 배너 제거
      title: '프로젝트 매칭 시스템',

      // 💡 1. 테마 모드를 '라이트'로 강제 고정
      themeMode: ThemeMode.light,

      // 💡 2. 라이트 테마 상세 설정
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // 🔤 기본 폰트를 'Noto Sans KR'로 설정
        fontFamily: GoogleFonts.notoSansKr().fontFamily,

        // 텍스트 스타일 전체에 폰트 적용
        textTheme: GoogleFonts.notoSansKrTextTheme(),

        // 기본 색상 (파란색 계열)
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),

        // 배경색 (연한 회색)
        scaffoldBackgroundColor: Colors.grey[50],

        // 앱바 테마 (흰색 배경, 검은 글씨)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          surfaceTintColor: Colors.transparent,
        ),

        // 💡 스위치 등 컴포넌트 테마 (MaterialState -> WidgetState 로 수정됨)
        switchTheme: SwitchThemeData(
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (!states.contains(WidgetState.selected)) {
              return Colors.grey.shade300; // 꺼져있을 때 트랙 색상
            }
            return null; // 켜져있을 땐 기본값(Primary Color) 사용
          }),
        ),
      ),

      // 첫 화면
      home: const AuthGate(),
    );
  }
}