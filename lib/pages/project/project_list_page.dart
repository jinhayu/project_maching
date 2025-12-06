import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import '../../services/project_service.dart';
import 'project_create_page.dart';
import 'project_detail_page.dart';

class ProjectListPage extends StatefulWidget {
  const ProjectListPage({Key? key}) : super(key: key);

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  final ProjectService _projectService = ProjectService();
  final TextEditingController _searchController = TextEditingController();

  List<Project> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({String? query}) async {
    if (_projects.isEmpty) setState(() => _isLoading = true);

    try {
      // 매칭 점수가 계산되어 정렬된 목록을 가져옴
      final projects = await _projectService.fetchProjects(query: query);
      if (mounted) {
        setState(() {
          _projects = projects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로젝트 찾기', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 🔍 검색창 영역
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '관심 기술, 제목 검색 (예: Flutter)',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _loadData();
                  },
                )
                    : null,
              ),
              onSubmitted: (value) => _loadData(query: value),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // 프로젝트 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _projects.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('검색 결과가 없습니다.', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: () => _loadData(query: _searchController.text),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _projects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _ProjectCard(
                    project: _projects[index],
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProjectDetailPage(project: _projects[index])),
                      );
                      _loadData(query: _searchController.text);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProjectCreatePage()),
          );
          if (result == true) _loadData();
        },
        label: const Text('글쓰기'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _ProjectCard({required this.project, required this.onTap});

  // 매칭 점수 색상을 결정하는 헬퍼 함수
  Color _getMatchColor(double score) {
    if (score >= 80) return Colors.green.shade600;
    if (score >= 50) return Colors.orange.shade600;
    return Colors.grey.shade500;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final techTags = project.techStack.isNotEmpty
        ? project.techStack.split(',').take(3).toList()
        : [];

    final matchScore = project.matchScore.toInt(); // 정수로 변환
    final matchColor = _getMatchColor(project.matchScore);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 상단: 매칭 점수 & 모집 상태
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🆕 매칭 점수 배지
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: matchColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: matchColor.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '추천 $matchScore%', // 💡 FIX: 불필요한 중괄호 제거
                      style: TextStyle(
                        fontSize: 12,
                        color: matchColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusBadge(isRecruiting: project.isRecruiting),
                ],
              ),
              const SizedBox(height: 12),

              // 2. 제목
              Text(
                project.title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // 3. 설명
              Text(
                project.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),

              // 4. 태그 (Chips)
              if (techTags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: techTags.map((tag) => Chip(
                    label: Text(tag.trim(), style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.grey[100],
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),

              if (techTags.isNotEmpty) const SizedBox(height: 16),

              const Divider(height: 1),
              const SizedBox(height: 12),

              // 5. 하단 정보 (조회수, 좋아요)
              Row(
                children: [
                  _IconText(icon: Icons.people_outline, text: '최대 ${project.maxMembers}명'),
                  const SizedBox(width: 16),
                  _IconText(icon: Icons.remove_red_eye_outlined, text: '${project.viewCount}'),
                  const SizedBox(width: 16),
                  _IconText(
                      icon: project.isLiked ? Icons.favorite : Icons.favorite_border,
                      text: '${project.likeCount}',
                      color: project.isLiked ? Colors.red : null
                  ),
                  const Spacer(),
                  Text(
                      '자세히 보기',
                      style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)
                  ),
                  Icon(Icons.chevron_right, size: 16, color: theme.primaryColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _IconText({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[500]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color ?? Colors.grey[600], fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isRecruiting;
  const _StatusBadge({required this.isRecruiting});

  @override
  Widget build(BuildContext context) {
    final color = isRecruiting ? const Color(0xFF10B981) : const Color(0xFF9CA3AF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        isRecruiting ? '모집중' : '마감',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}