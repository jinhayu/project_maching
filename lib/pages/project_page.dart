import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';
// 상세/생성 페이지는 기존에 만든 파일 경로를 사용합니다.
import 'project/project_create_page.dart';
import 'project/project_detail_page.dart';

class ProjectPage extends StatefulWidget {
  const ProjectPage({Key? key}) : super(key: key);

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
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
        title: const Text('프로젝트 찾기'),
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거 (메인 탭용)
      ),
      body: Column(
        children: [
          // 🔍 검색창 (디자인 적용)
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
        icon: const Icon(Icons.edit),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _ProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 기술 스택 태그 처리
    final techTags = project.techStack.isNotEmpty
        ? project.techStack.split(',').take(3).toList()
        : [];

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 상단: 상태 배지 & 제목
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusBadge(isRecruiting: project.isRecruiting),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      project.title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. 설명
              Text(
                project.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),

              // 3. 태그 (Chips)
              if (techTags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: techTags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag.trim(),
                      style: TextStyle(color: Colors.grey[700], fontSize: 11),
                    ),
                  )).toList(),
                ),

              if (techTags.isNotEmpty) const SizedBox(height: 16),

              const Divider(height: 1),
              const SizedBox(height: 12),

              // 4. 하단 정보 (인원, 조회수, 좋아요)
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
                      style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 13)
                  ),
                  Icon(Icons.chevron_right, size: 16, color: Theme.of(context).primaryColor),
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
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}