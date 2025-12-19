import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Records 문법
typedef ChatMessage = ({String text, bool isUser});

class ChatService {
  late final String _apiKey;

  // 시스템 프롬프트 (이전과 동일)
  static const String _systemInstruction = '''
[IMPORTANT INSTRUCTION]
You are a helpful AI assistant for the 'Synergy' project.
You MUST answer ONLY in Korean (한국어).
Do NOT use Japanese (Hiragana, Katakana, Kanji) or Chinese characters.
If you need to use technical terms, use English or Korean transliteration.

--- 역할 정의 ---
당신은 '시너지' 프로젝트 매칭 시스템의 공식 AI 가이드이자 코치입니다.
팀 이름은 '진하 왔는가?'이며, 이 앱의 구조와 기술적 특징을 완벽하게 이해하고 있습니다.

--- 1. 핵심 매칭 시스템 (Hybrid Matching) ---
우리 앱의 가장 큰 차별점은 단순 태그 매칭이 아닌, '하이브리드 추천 시스템'입니다.
- **EMA(지수 이동 평균) + 태그**: 사용자의 최근 활동을 실시간으로 반영하여 가중치를 계산합니다.
- **NCF(신경망 협업 필터링)**: 사용자와 프로젝트 간의 잠재적 관계를 딥러닝으로 예측하여 추천 정확도를 높입니다.
- 이 두 가지를 결합하여 통계적 모델의 한계를 극복하고 예측형 모델로 발전시켰습니다.

--- 2. 앱 주요 기능 및 구조 ---
- **모집**: 프로젝트 생성 시 필요한 기술 스택을 설정하고 팀원을 모집합니다.
- **협업 툴**: 팀이 결성되면 '팀 스케줄러(간트 차트)', '팀 게시판' 기능을 제공합니다.
- **보안(RLS)**: Supabase의 RLS(Row Level Security) 정책을 적용하여, 같은 팀원끼리만 데이터를 공유하도록 철저히 격리되어 있습니다.
- **프로필**: 사용자의 기술 스택, 포트폴리오를 관리하며 이는 매칭 AI의 핵심 데이터로 사용됩니다.

--- 3. 기술 스택 ---
- **프론트엔드**: Flutter (Web & Mobile 크로스 플랫폼)
- **백엔드/DB**: Supabase (PostgreSQL, Authentication)
- **AI/ML**: Python, TensorFlow (NCF 모델 학습), Groq(Llama 3) 기반 챗봇
- **배포**: 웹(Web)을 메인으로 하며 안드로이드/iOS 동시 지원

--- 답변 스타일 ---
1. 무조건 자연스러운 **한국어**로 답변하세요. 일본어나 한자를 섞어 쓰지 마세요.
2. 질문이 기능 사용법을 물을 때는 구체적인 단계(Step-by-step)로 설명하세요.
3. 기술적인 질문에는 EMA, NCF 개념을 활용하여 전문성을 드러내세요.
4. 답변은 Markdown 형식을 사용하여 가독성 있게 작성하세요.
''';

  ChatService() {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY not found in .env');
    }
    _apiKey = apiKey;
  }

  ChatMessage get initialMessage {
    return (
    text: "안녕하세요! 시너지 프로젝트 코치입니다. 🚀\n\n앱 사용법이나 매칭 시스템에 대해 무엇이든 물어보세요. 제가 도와드릴게요!",
    isUser: false,
    );
  }

  Stream<String> sendMessageStream(String message) async* {
    if (message.trim().isEmpty) return;

    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final request = http.Request('POST', url);
    request.headers.addAll({
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $_apiKey',
    });

    request.body = jsonEncode({
      "model": "llama-3.3-70b-versatile",
      "messages": [
        {"role": "system", "content": _systemInstruction},
        {"role": "user", "content": message}
      ],
      "temperature": 0.3, // 창의성 억제 (한국어 유지)
      "stream": true,
    });

    try {
      final response = await request.send();

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        yield "\n[오류 발생 (${response.statusCode})]: $errorBody";
        return;
      }

      // 🔥 핵심 수정: 버퍼링 로직 추가
      // 데이터가 중간에 끊겨서 오더라도 모아서 처리하는 역할
      String buffer = '';

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk; // 들어오는 조각들을 계속 붙임

        // 버퍼에 줄바꿈(\n)이 있는 동안 계속 반복해서 완전한 줄을 꺼냄
        while (buffer.contains('\n')) {
          final index = buffer.indexOf('\n');
          final line = buffer.substring(0, index).trim(); // 한 줄 꺼내기
          buffer = buffer.substring(index + 1); // 꺼낸 부분은 버퍼에서 삭제

          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim(); // "data: " 제거
            if (jsonStr == '[DONE]') continue;

            try {
              final json = jsonDecode(jsonStr);
              final content = json['choices'][0]['delta']['content'];
              if (content != null) {
                yield content; // UI로 전송
              }
            } catch (e) {
              // JSON 형식이 아직 덜 완성되었거나 깨진 경우 무시하고 다음 청크를 기다림
              // (하지만 위에서 줄바꿈 단위로 잘랐으므로 거의 발생하지 않음)
            }
          }
        }
      }
    } catch (e) {
      yield "\n[네트워크 오류]: $e";
    }
  }
}