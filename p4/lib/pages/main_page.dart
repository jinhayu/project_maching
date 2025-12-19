import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 상태바 스타일링용
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui'; // 유리 효과(Blur)를 위해 필요
import 'package:flutter/foundation.dart'; // kIsWeb 체크용

// 기존 페이지 import
import 'profile_page.dart';
import 'project/project_list_page.dart'; // 리스트 페이지
import 'scheduler_page.dart';
import 'project_page.dart';
import  'ai_recommendation_page.dart';// ✨ [추가됨] 추천 아이콘 클릭 시 이동할 페이지
import 'splash_page.dart';
import 'notification_page.dart';
import '../services/notification_service.dart';
import 'settings/settings_page.dart';
import 'ai_chatbot_page.dart';
//import './mypage/my_projects_page.dart';  내 프로젝트 관리 페이지
import './mypage/my_page.dart';

// -------------------------------------------------------------
// 🎨 Design System
// -------------------------------------------------------------
class AppColors {
  static const Color primary = Color(0xFF4F46E5); // Brand Color (Indigo 600)
  static const Color textMain = Color(0xFF111827); // Gray 900
  static const Color textSub = Color(0xFF6B7280); // Gray 500
  static const Color border = Color(0xFFE5E7EB); // Gray 200
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color background = Color(0xFFF9FAFB);
  static const Color cardBackground = Colors.white;
}

// ✨ 배경 그라디언트
class AppDecorations {
  static const BoxDecoration auroraBackground = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFE0E7FF), // Indigo 100
        Color(0xFFFAE8FF), // Pink 100
        Color(0xFFCFFAFE), // Cyan 100
        Color(0xFFF3F4F6), // Gray 100
      ],
      stops: [0.0, 0.35, 0.7, 1.0],
    ),
  );

  static const BoxDecoration plainBackground = BoxDecoration(
    color: AppColors.background,
  );
}

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textMain,
    letterSpacing: -0.5,
  );
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain,
  );
  static const TextStyle body = TextStyle(
    fontSize: 15,
    color: AppColors.textMain,
    height: 1.4,
  );
  static const TextStyle hint = TextStyle(
    fontSize: 15,
    color: AppColors.textSub,
  );
}

// -------------------------------------------------------------
// 🧩 Components: 모던한 입력창 위젯
// -------------------------------------------------------------
class ModernTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData? icon;
  final int maxLines;
  final TextInputType keyboardType;

  const ModernTextField({
    Key? key,
    required this.label,
    this.hint,
    this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.sectionTitle),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.hint,
              prefixIcon: icon != null
                  ? Icon(icon, color: AppColors.textSub, size: 20)
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.cardBackground,
            ),
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// 🏠 MainPage
// -------------------------------------------------------------
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // bool _isLoading = true;
  int _unreadNotifications = 0;
  final NotificationService _notificationService = NotificationService();

  int _selectedIndex = 0; // 현재 탭 인덱스

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _checkUnreadNotifications();

    // 탭별 페이지 구성
    _widgetOptions = <Widget>[
      const ProjectListPage(),     // 0: 홈
      const SchedulerPage(),       // 1: 일정
      const SizedBox.shrink(),     // 2: 작성 (버튼 클릭 시 MyProjectsPage로 이동)
      const AiChatbotPage(),       // 3: AI 채팅
      const ProfilePage(),         // 4: 마이페이지
    ];
  }

  Future<void> _checkUnreadNotifications() async {
    final count = await _notificationService.getUnreadCount();
    if (mounted) setState(() => _unreadNotifications = count);
  }

  Future<void> _fetchUserProfile() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null || !mounted) return;
    // _isLoading = false;
  }

  void _navigateToSettings() => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));

  // ✨ [추가됨] 추천 페이지 이동 함수
  void _navigateToRecommendation() => Navigator.push(context, MaterialPageRoute(builder: (context) => const AiRecommendationPage()));

  Future<void> _navigateToNotifications() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage()));
    _checkUnreadNotifications();
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const SplashPage()), (route) => false);
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      // 중앙 '+' 버튼 클릭 시 -> [나의 프로젝트 관리] 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MyPage()),
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    // 📱 [모바일 사이즈 제한]
    return Container(
      color: Colors.grey[200], // PC/Web 바깥 배경
      child: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 500, // 모바일 앱 크기 고정
          ),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Scaffold(
            extendBodyBehindAppBar: true,

            // ---------- 상단바 ----------
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white.withOpacity(0.8),
              surfaceTintColor: Colors.transparent,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
              automaticallyImplyLeading: false,
              titleSpacing: 20,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  ),
                  const SizedBox(width: 8),
                  const Text('synergy', style: TextStyle(fontFamily: 'Montserrat', color: Colors.black, fontWeight: FontWeight.w800, fontSize: 22)),
                ],
              ),
              actions: [
                // ✨ [추가됨] 추천 아이콘 (엄지척)
                IconButton(
                  icon: const Icon(Icons.thumb_up_alt_outlined, color: Colors.black87),
                  onPressed: _navigateToRecommendation,
                  tooltip: '프로젝트 추천',
                ),

                // 알림 아이콘
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
                      onPressed: _navigateToNotifications,
                    ),
                    if (_unreadNotifications > 0)
                      Positioned(
                        right: 12, top: 12,
                        child: Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),

                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.black87),
                  onPressed: _navigateToSettings,
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.black54),
                  onPressed: _signOut,
                  tooltip: '로그아웃',
                ),
                const SizedBox(width: 8),
              ],
            ),

            // ---------- 본문 (Stack 사용) ----------
            body: Stack(
              children: [
                // 1. 메인 컨텐츠
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  // ✨ 모든 페이지에 오로라 배경 적용
                  decoration: AppDecorations.auroraBackground,
                  child: Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
                      Expanded(
                        child: IndexedStack(
                          index: _selectedIndex,
                          children: _widgetOptions,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ---------- 하단바 ----------
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9), // 살짝 투명
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent, // 배경 투명 처리 (컨테이너 색상 사용)
                elevation: 0,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: Colors.grey.shade400,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home_filled, size: 28),
                    label: '홈',
                  ),

                  // 1번 탭: SchedulerPage -> 달력 아이콘
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_month_rounded, size: 28),
                    label: '일정',
                  ),

                  // 중앙 버튼 (작성) -> 클릭 시 MyProjectsPage(나의 프로젝트 관리)로 이동
                  BottomNavigationBarItem(
                    icon: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.folder_shared_rounded, color: Colors.white, size: 28), // 아이콘 변경 (폴더/관리 느낌)
                    ),
                    label: '내 프로젝트',
                  ),

                  // 3번 탭: AiChatbotPage -> AI 로봇 아이콘
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.smart_toy_rounded, size: 28),
                    label: 'AI 채팅',
                  ),

                  const BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline_rounded, size: 30),
                    label: '마이',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// [CreateProjectPage] (새 프로젝트 생성 페이지)
// -------------------------------------------------------------
class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({Key? key}) : super(key: key);

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  int _memberCount = 4;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(color: Colors.white),
          child: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMain),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('새 프로젝트', style: AppTextStyles.heading),
            ),
            body: Container(
              // ✨ 모든 페이지와 동일한 배경색 적용
              decoration: AppDecorations.auroraBackground,
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("기본 정보", "프로젝트의 핵심 정보를 입력해주세요."),
                          const SizedBox(height: 20),
                          const ModernTextField(
                            label: "프로젝트 제목",
                            hint: "예: Flutter 기반 챗봇 서비스",
                            icon: Icons.edit_outlined,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Expanded(
                                flex: 2,
                                child: ModernTextField(
                                  label: "기술 스택",
                                  hint: "Flutter, React...",
                                  icon: Icons.code_rounded,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("모집 인원", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMain)),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: AppColors.cardBackground,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withOpacity(0.08),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildCounterBtn(Icons.remove, () {
                                            if (_memberCount > 1) setState(() => _memberCount--);
                                          }),
                                          Text(
                                              "$_memberCount",
                                              style: const TextStyle(
                                                  fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary
                                              )
                                          ),
                                          _buildCounterBtn(Icons.add, () {
                                            setState(() => _memberCount++);
                                          }),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Divider(color: AppColors.border),
                          const SizedBox(height: 32),
                          _buildSectionHeader("상세 내용", "팀원들이 알기 쉽게 구체적으로 적어주세요."),
                          const SizedBox(height: 20),
                          const ModernTextField(
                            label: "프로젝트 설명",
                            hint: "목표, 예상 기간, 회의 방식(온/오프라인) 등을 자유롭게 작성해주세요.",
                            maxLines: 8,
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shadowColor: AppColors.primary.withOpacity(0.4),
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          '작성 완료',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(fontSize: 14, color: AppColors.textSub)),
      ],
    );
  }

  Widget _buildCounterBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 18, color: AppColors.textSub),
      ),
    );
  }
}