// lib/pages/ai_chatbot_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/chat_service.dart';

// -------------------------------------------------------------
// 🎨 Design System (AiChatbotPage 전용)
// -------------------------------------------------------------
class ChatAppColors {
  // 메인 액센트 색상 (전송 버튼 및 텍스트)
  static const Color primary = Color(0xFFE94057); // Reddish-Pink (인스타 그라데이션 계열)
  static const Color textMain = Color(0xFF111827); // Gray 900
  static const Color textSub = Color(0xFF6B7280); // Gray 500

  // 입력창 배경색
  static const Color inputFieldFill = Color(0xFFF3F4F6); // Gray 100

  // ✨ 화려한 배경 그라데이션 색상
  static const Color gradientStart = Color(0xFF8A2387); // 보라
  static const Color gradientMiddle = Color(0xFFE94057); // 빨강
  static const Color gradientEnd = Color(0xFFF2A40A); // 오렌지
}

// SingleTickerProviderStateMixin을 사용하기 위해 with 키워드와 함께 Mixin을 추가해야 합니다.
class AiChatbotPage extends StatefulWidget {
  const AiChatbotPage({Key? key}) : super(key: key);

  @override
  State<AiChatbotPage> createState() => _AiChatbotPageState();
}

// SingleTickerProviderStateMixin 추가
class _AiChatbotPageState extends State<AiChatbotPage> with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 애니메이션 컨트롤러와 애니메이션 변수 추가
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(_chatService.initialMessage);
    // 입력창 변화 감지 리스너 추가
    _textController.addListener(_updateSendButtonState);

    // 애니메이션 컨트롤러 초기화 (Duration은 눌리는 속도)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    // 크기 변화 애니메이션 설정 (0.95배 크기로 줄어듦)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _textController.removeListener(_updateSendButtonState);
    _textController.dispose();
    _scrollController.dispose();
    _animationController.dispose(); // 애니메이션 컨트롤러 dispose
    super.dispose();
  }

  // 전송 버튼 색상 업데이트를 위한 상태 관리 함수
  void _updateSendButtonState() {
    if (mounted) {
      // 입력창이 비었는지 여부가 변경될 때만 setState 호출
      setState(() {});
    }
  }

  // 메시지 전송 및 스트림 처리 함수 (기능 유지)
  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _isLoading = true;
      _messages.add((text: text, isUser: true));
      _messages.add((text: '', isUser: false));
    });
    _scrollToBottom();

    try {
      final stream = _chatService.sendMessageStream(text);
      final aiMessageIndex = _messages.length - 1;
      String accumulatedText = '';

      await for (final chunk in stream) {
        accumulatedText += chunk;
        if (mounted) {
          setState(() {
            _messages[aiMessageIndex] = (text: accumulatedText, isUser: false);
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages[_messages.length - 1] = (text: '죄송합니다. 오류가 발생했습니다: $e', isUser: false);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ✨ 화면 너비에 맞춘 말풍선 빌더
  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;

    // 사용자 메시지 (흰색 + 강한 그림자)
    return Container(
      // ✨ 마진 조정
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      constraints: BoxConstraints(
        // ✨ 최대 너비 조정 (화면 너비의 70%)
        maxWidth: MediaQuery.of(context).size.width * 0.70,
      ),
      decoration: BoxDecoration(
        color: isUser ? Colors.white.withOpacity(0.9) : Colors.white, // 사용자: 짙은 흰색, AI: 흰색
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          // 비대칭 뾰족한 모서리 유지
          bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(6),
          bottomRight: isUser ? const Radius.circular(6) : const Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isUser ? 0.2 : 0.1), // 사용자 메시지의 그림자 강조
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isUser
          ? Text(
        message.text,
        style: const TextStyle(color: ChatAppColors.textMain, fontSize: 15),
      )
          : MarkdownBody(
        data: message.text,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: ChatAppColors.textMain,
          ),
          // 마크다운 스타일 유지
          code: TextStyle(
            backgroundColor: ChatAppColors.inputFieldFill.withOpacity(0.5),
            color: ChatAppColors.textMain,
            fontSize: 14,
          ),
          h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ChatAppColors.textMain),
          h2: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ChatAppColors.textMain),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isInputEmpty = _textController.text.trim().isEmpty;
    final bool isButtonDisabled = _isLoading || isInputEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,

      // ✨ 화려한 배경 그라데이션 적용
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ChatAppColors.gradientStart,
              ChatAppColors.gradientMiddle,
              ChatAppColors.gradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // ✨ App Bar 영역
            SafeArea( // 노치 및 상태바 영역을 안전하게 확보
              bottom: false,
              child: AppBar(
                title: const Text(
                  'AI 프로젝트 코치',
                  style: TextStyle(
                    color: Colors.white, // 흰색
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                backgroundColor: Colors.transparent, // 투명 배경
                elevation: 0, // 그림자 제거
                centerTitle: false,
                iconTheme: const IconThemeData(color: Colors.white), // 아이콘 색상 흰색
              ),
            ),

            // 1. 채팅 메시지 리스트
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                // ✨ 좌우 패딩 12로 조정
                padding: const EdgeInsets.only(top: 10, left: 12, right: 12, bottom: 8),
                itemCount: _messages.length,
                // ✨ 스크롤바가 필요할 때만 보이도록 설정
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message.isUser;

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: _buildChatBubble(message), // 커스텀 빌더 사용
                  );
                },
              ),
            ),

            // 2. 로딩 인디케이터
            if (_isLoading && _messages.length == 1)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(color: Colors.white), // 흰색
              ),

            // 3. 입력창 영역
            Container(
              // ✨ 상하좌우 패딩 조정
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false, // 하단 노치 영역만 처리
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: '메시지 보내기...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: ChatAppColors.inputFieldFill, // 입력창 배경색
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10, // 입력창 높이 조정
                          ),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 전송 버튼 (클릭 피드백 적용)
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: GestureDetector(
                        onTapDown: (_) {
                          if (!isButtonDisabled) {
                            _animationController.forward(); // 누를 때 축소
                          }
                        },
                        onTapUp: (_) {
                          if (!isButtonDisabled) {
                            _animationController.reverse(); // 뗄 때 원상 복귀
                            _handleSend();
                          }
                        },
                        onTapCancel: () {
                          if (!isButtonDisabled) {
                            _animationController.reverse(); // 취소 시 원상 복귀
                          }
                        },
                        child: CircleAvatar(
                          // 입력 내용 유무에 따라 색상 변경
                          backgroundColor: isButtonDisabled ? Colors.grey.shade400 : ChatAppColors.primary,
                          radius: 20,
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}