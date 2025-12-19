import 'package:flutter/foundation.dart';
import 'dart:math' as math;

// TFLite 모델 로드 및 추론(Inference)을 담당하는 서비스

class RecommendationService {

  // ❌ _vocabulary 필드 제거 (Tag 유사도 계산 로직은 이를 사용하지 않음)

  // 1. 모델 로드 함수 (TFLite가 없으므로 비워둡니다)
  Future<void> loadModel() async {
    debugPrint("✅ Recommendation Engine initialized. Using Tag+EMA Hybrid Score (Pure Dart).");
  }

  // 2. 딥러닝 모델을 통한 매칭 점수 추론 (NCF 로직 대체)
  double getMatchScore(List<String> userSkills, List<String> requiredSkills, {required double emaWeight}) {

    // NCF 모델이 없으므로, NCF Score를 0.5 (중립 점수)로 고정하여 하이브리드 점수를 계산합니다.
    return _calculateHybridScore(userSkills, requiredSkills, ncfScore: 0.5, emaScore: emaWeight);
  }

  // 3. (Hybrid Logic) 최종 하이브리드 점수 합산 로직
  double _calculateHybridScore(
      List<String> userSkills,
      List<String> requiredSkills,
      {required double ncfScore, // 0 ~ 1.0 (현재 0.5로 고정됨)
        required double emaScore}  // 0 ~ raw weight
      ) {
    // NCF.txt의 가중치 사용: α=0.5, β=0.3, γ=0.2
    const double alpha = 0.5; // Tag Score 가중치
    const double beta = 0.3;  // NCF Score 가중치
    const double gamma = 0.2; // EMA Score 가중치

    // Tag Score 계산 (0~100점) 후 0~1로 정규화
    double tagScorePercent = _calculateTagSimilarity(userSkills, requiredSkills);
    double tagScoreNormalized = tagScorePercent / 100.0;

    // EMA Score를 Sigmoid로 정규화 (0~1)
    final emaScoreNormalized = 1.0 / (1.0 + math.exp(-emaScore));

    // 최종 점수를 0~100점 기준으로 합산
    double finalScore = (alpha * tagScoreNormalized * 100) +
        (beta * ncfScore * 100) +
        (gamma * emaScoreNormalized * 100);

    return finalScore.clamp(0.0, 100.0);
  }

  // 4. (Tag Similarity) 태그 기반 점수 계산 로직
  double _calculateTagSimilarity(List<String> userSkills, List<String> requiredSkills) {
    if (requiredSkills.isEmpty || userSkills.isEmpty) return 0.0;

    final commonSkills = userSkills.where((mySkill) {
      final mySkillLower = mySkill.trim().toLowerCase();
      return requiredSkills.any((reqSkill) =>
      reqSkill.trim().toLowerCase() == mySkillLower
      );
    }).length;

    final score = (commonSkills / requiredSkills.length) * 100;
    return score.clamp(0.0, 100.0);
  }
}