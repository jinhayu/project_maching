// lib/pages/ai_chatbot_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/chat_service.dart';

class AiChatbotPage extends StatefulWidget {
  const AiChatbotPage({Key? key}) : super(key: key);

  @override
  State<AiChatbotPage> createState() => _AiChatbotPageState();
}

class _AiChatbotPageState extends State<AiChatbotPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ChatService의 typedef ChatMessage 사용 (Records 문법)
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 초기 환영 메시지 로드
    _messages.add(_chatService.initialMessage);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 메시지 전송 및 스트림 처리 함수
  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _isLoading = true;
      // 1. 사용자 메시지 추가
      _messages.add((text: text, isUser: true));
      // 2. AI 응답을 담을 빈 메시지 미리 추가 (스트림 데이터를 여기에 채움)
      _messages.add((text: '', isUser: false));
    });
    _scrollToBottom();

    try {
      // 3. 스트림 구독 (한 글자씩 받아오기)
      final stream = _chatService.sendMessageStream(text);

      // 현재 응답 중인 메시지의 인덱스 (리스트의 마지막)
      final aiMessageIndex = _messages.length - 1;
      String accumulatedText = '';

      await for (final chunk in stream) {
        accumulatedText += chunk;
        if (mounted) {
          setState(() {
            // Records는 불변(Immutable)이므로 교체 방식으로 업데이트
            _messages[aiMessageIndex] = (text: accumulatedText, isUser: false);
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // 에러 발생 시 마지막 메시지에 에러 내용 표시
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI 프로젝트 코치',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 1. 채팅 메시지 리스트
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.isUser;

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    decoration: BoxDecoration(
                      // 사용자: 파란색, AI: 흰색
                      color: isUser ? const Color(0xFF2563EB) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                      ),
                      boxShadow: [
                        if (!isUser)
                          BoxShadow(
                            // 💡 경고 해결: withOpacity -> withAlpha (0.05 * 255 ≈ 13)
                            color: Colors.black.withAlpha(13),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                      ],
                      border: isUser ? null : Border.all(color: Colors.grey.shade200),
                    ),
                    child: isUser
                        ? Text(
                      message.text,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    )
                        : MarkdownBody(
                      data: message.text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. 로딩 인디케이터 (초기 연결 등)
          if (_isLoading && _messages.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),

          // 3. 입력창 영역
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: '질문을 입력하세요...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    // 엔터키 전송
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 8),
                // 전송 버튼
                CircleAvatar(
                  backgroundColor: const Color(0xFF2563EB),
                  radius: 24,
                  // 💡 const 최적화 적용
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _isLoading ? null : _handleSend,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}