import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_match.dart';
import '../services/project_service.dart'; // 1. ProjectService 임포트
import 'project/project_detail_page.dart';

class AiRecommendationPage extends StatefulWidget {
  const AiRecommendationPage({super.key});

  @override
  State<AiRecommendationPage> createState() => _AiRecommendationPageState();
}

class _AiRecommendationPageState extends State<AiRecommendationPage> {
  // 2. MatchingService 대신 ProjectService 인스턴스 생성 (점수 계산 로직이 여기 있으므로)
  final ProjectService _projectService = ProjectService();

  // 기존 구조 유지: ProjectMatch 리스트 사용
  List<ProjectMatch> _allMatches = [];

  int _currentMax = 5;
  final int _increment = 5;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        // 3. [핵심 수정] ProjectService에서 점수가 계산된 프로젝트 목록을 가져옵니다.
        // fetchProjects() 내부에서 이미 (태그+EMA+NCF) 점수 계산이 완료되어 project.matchScore에 들어있습니다.
        final projects = await _projectService.fetchProjects();

        // 4. [구조 유지] 가져온 Project 객체들을 기존 UI가 사용하는 ProjectMatch 객체로 변환합니다.
        // 이때 score 부분에 계산된 project.matchScore를 넣어줍니다.
        final results = projects.map((project) {
          return ProjectMatch(
            project: project,
            score: project.matchScore, // 여기가 핵심! 계산된 점수를 ProjectMatch에 주입
          );
        }).toList();

        // 점수 높은 순 정렬 (이미 되어있을 수 있지만 확실하게)
        results.sort((a, b) => b.score.compareTo(a.score));

        if (mounted) {
          setState(() {
            _allMatches = results;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading recommendations: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMore() {
    setState(() {
      _currentMax += _increment;
    });
  }

  @override
  Widget build(BuildContext context) {
    // UI 코드는 건드리지 않고 그대로 유지합니다.
    final visibleMatches = _allMatches.take(_currentMax).toList();
    final hasMore = _currentMax < _allMatches.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("AI 맞춤 추천", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allMatches.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("추천할 프로젝트가 없습니다.", style: TextStyle(color: Colors.grey[500])),
            Text("프로필에 기술 스택을 추가해보세요!", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: visibleMatches.length + (hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index == visibleMatches.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextButton.icon(
                onPressed: _showMore,
                icon: const Icon(Icons.expand_more, color: Colors.deepPurple),
                label: Text(
                  "프로젝트 더 보기 (${_allMatches.length - visibleMatches.length}개 남음)",
                  style: const TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.deepPurple.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            );
          }

          return _AiMatchCard(
            match: visibleMatches[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectDetailPage(project: visibleMatches[index].project),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// _AiMatchCard 클래스도 기존 코드 그대로 유지
class _AiMatchCard extends StatelessWidget {
  final ProjectMatch match;
  final VoidCallback onTap;

  const _AiMatchCard({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 점수 뱃지 부분
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade200],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          // match.score에 이제 ProjectService에서 계산한 값이 들어옵니다.
                          Text(
                            "${match.score.toInt()}% 일치",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      match.project.isRecruiting ? "모집중" : "마감",
                      style: TextStyle(
                        color: match.project.isRecruiting ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  match.project.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  match.project.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.code, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match.project.techStack,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}