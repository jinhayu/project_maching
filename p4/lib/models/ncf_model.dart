import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // 파일 로딩용

class NCFModel {
  // 가중치 데이터를 메모리에 담아둘 변수
  static Map<String, dynamic>? _weights;
  static bool _isLoaded = false;

  /// 1. 모델(JSON 가중치) 로드
  static Future<void> ensureLoaded() async {
    if (_isLoaded) return;

    try {
      // assets 폴더의 json 파일을 읽어옵니다.
      // 파일명이 다르다면 'assets/ncf_weights.json' 부분을 수정하세요.
      final String jsonString = await rootBundle.loadString('assets/ncf_weights.json');
      _weights = jsonDecode(jsonString);
      _isLoaded = true;
      debugPrint("✅ NCF Weights (JSON) Loaded Successfully");
    } catch (e) {
      debugPrint("❌ Failed to load JSON weights: $e");
      debugPrint("👉 팁: pubspec.yaml에 assets 경로가 등록되었는지 확인하세요.");
    }
  }

  /// 2. 추천 점수 계산 (행렬 연산)
  static Future<List<double>> predictBatch({
    required String userId,
    required List<String> itemIds,
  }) async {
    // 데이터 로드 확인
    await ensureLoaded();

    // 로드 실패했거나 데이터가 없으면 0점 반환 (앱 꺼짐 방지)
    if (!_isLoaded || _weights == null) {
      return List.filled(itemIds.length, 0.0);
    }

    try {
      // -------------------------------------------------------
      // ⚠️ [중요] JSON 파일 내부의 키(Key) 이름과 맞춰주세요.
      // 만약 JSON 파일 안의 이름이 'users', 'items'라면 아래를 수정해야 합니다.
      // -------------------------------------------------------

      // JSON 구조가 아래와 같다고 가정합니다:
      // { "user_embeddings": [[...], ...], "item_embeddings": [[...], ...] }
      List<dynamic> userEmbeddings = _weights!['user_embeddings'] ?? [];
      List<dynamic> itemEmbeddings = _weights!['item_embeddings'] ?? [];

      if (userEmbeddings.isEmpty || itemEmbeddings.isEmpty) {
        debugPrint("⚠️ JSON 데이터가 비어있거나 키 이름이 다릅니다.");
        return List.filled(itemIds.length, 0.0);
      }

      // 1) 내 ID를 정수 인덱스로 변환 (임시로 해시코드 사용)
      // 실제로는 user_map이 필요하지만, 일단 동작하도록 해시 사용
      int userIdx = userId.hashCode.abs() % userEmbeddings.length;

      // 2) 내 임베딩 벡터 가져오기
      List<double> myVector = List<double>.from(userEmbeddings[userIdx]);

      List<double> scores = [];

      // 3) 각 프로젝트(아이템)와의 유사도 계산
      for (String itemId in itemIds) {
        int itemIdx = itemId.hashCode.abs() % itemEmbeddings.length;

        // 아이템 벡터 가져오기
        List<double> itemVector = List<double>.from(itemEmbeddings[itemIdx]);

        // 내적(Dot Product) 계산: 벡터끼리 곱해서 더함
        double dotProduct = 0.0;
        int len = min(myVector.length, itemVector.length);
        for (int i = 0; i < len; i++) {
          dotProduct += myVector[i] * itemVector[i];
        }

        // 시그모이드(Sigmoid) 함수: 결과를 0~1 사이 확률로 변환
        double prob = 1 / (1 + exp(-dotProduct));
        scores.add(prob);
      }

      return scores;

    } catch (e) {
      debugPrint("❌ Calculation Error: $e");
      return List.filled(itemIds.length, 0.0);
    }
  }
}