import 'package:flutter/material.dart';
import 'login_page.dart'; // 로그인 페이지 import (기능 유지)

class SplashPage extends StatelessWidget {
  const SplashPage({Key? key}) : super(key: key);

  // 카드 내부 텍스트 스타일 정의 (앱 스타일을 위해 폰트 굵기 조정)
  static const TextStyle cardTitleStyle = TextStyle(
    color: Colors.white70, // 조금 더 부드러운 흰색
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle cardValueStyle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w600, // 약간 더 굵게
  );

  @override
  Widget build(BuildContext context) {
    // 💡 배경 색상 (이전 유지)
    const Color darkTeal = Color(0xFF175D69);
    const Color darkPurple = Color(0xFF330C43);

    // 💳 카드 배경색 (기존 유지)
    const Color cardBackground = Color(0xFF5A4C98);

    return Scaffold(
      // 🚨 배경 설정 (앱 메인 화면 느낌의 다크 그라데이션)
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              darkTeal,
              darkPurple,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Center(
          // 💳 신용카드 모양의 컨테이너
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            // 높이를 AspectRatio로 조정하여 카드 비율을 유지 (선택 사항)
            child: AspectRatio(
              aspectRatio: 1.6, // 일반 신용카드의 비율 (약 1.586)
              child: Container(
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(28),
                  // 그림자 효과를 강조하여 앱 컴포넌트 느낌 강화
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54, // 더 진한 그림자
                      offset: Offset(0, 15),
                      blurRadius: 30, // 그림자 크기 키우기
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(30), // 내부 패딩 증가

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // 내용 위/아래 정렬
                  children: [
                    // 💳 HEADER (로고와 칩)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 로고 (Master Card 텍스트와 아이콘)
                        Row(
                          children: [
                            const Icon(Icons.flash_on, color: Colors.white, size: 30),
                            const SizedBox(width: 10),
                            Text('ProMatch', style: cardValueStyle.copyWith(fontSize: 18)),
                          ],
                        ),
                        // 칩 (앱 아이콘처럼 상징적으로 배치)
                        const Icon(Icons.verified_user, color: Colors.cyanAccent, size: 35), // 색상 변경
                      ],
                    ),

                    // 💳 CARD DETAILS 대신 SPLASH CONTENT 배치
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 'Card Number' 역할 (제목)
                        Text(
                          '프로젝트 매칭 시스템',
                          style: cardTitleStyle.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 8),

                        // 'Card Number' 값 역할 (부제목)
                        Text(
                          '새로운 협업 기회',
                          style: cardValueStyle.copyWith(
                            fontSize: 24, // 폰트 크기 강조
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // 'Name / Valid Thru' 역할 (본문 및 버튼)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // 'Name' 역할 (본문 내용)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '다양한 전공의 학생들과 만나\n프로젝트를 시작해보세요!',
                                    style: cardTitleStyle.copyWith(fontSize: 13, height: 1.5),
                                  ),
                                ],
                              ),
                            ),

                            // 'Valid Thru' 역할 (로그인 버튼)
                            SizedBox(
                              width: 130, // 폭 조정
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: cardBackground,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16), // 좀 더 둥글게
                                  ),
                                  elevation: 5,
                                  padding: const EdgeInsets.symmetric(vertical: 12), // 높이 조정
                                ),
                                onPressed: () {
                                  // 👉 기능 유지: LoginPage로 이동
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginPage()),
                                  );
                                },
                                child: const Text(
                                  '시작하기',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}