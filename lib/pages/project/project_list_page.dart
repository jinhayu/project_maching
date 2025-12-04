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
  final TextEditingController _searchController = TextEditingController(); // 검색어 입력 컨트롤러

  List<Project> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 검색어(query)를 받아서 데이터를 로드함
  Future<void> _loadData({String? query}) async {
    // 초기 로딩이거나 목록이 비었을 때만 로딩 표시 (검색 중엔 깜빡임 방지)
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
        title: const Text('프로젝트 찾기', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 🔍 검색창 영역
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '관심 있는 기술이나 제목 검색 (예: Flutter)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                // 텍스트 지우기 버튼
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadData(); // 전체 목록으로 복귀
                  },
                ),
              ),
              // 입력 완료 시(엔터) 검색 실행
              onSubmitted: (value) => _loadData(query: value),
            ),
          ),

          // 프로젝트 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _projects.isEmpty
                ? const Center(child: Text('검색 결과가 없습니다.\n+ 버튼을 눌러 시작해보세요!'))
                : RefreshIndicator(
              onRefresh: () => _loadData(query: _searchController.text),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _projects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _ProjectCard(
                    project: _projects[index],
                    onTap: () async {
                      // 상세 페이지로 이동
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProjectDetailPage(project: _projects[index])),
                      );
                      // 상세 페이지에서 좋아요/조회수가 변경되었을 수 있으므로 돌아오면 새로고침
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
          // 글 작성 후 돌아오면(result == true) 목록 새로고침
          if (result == true) _loadData();
        },
        label: const Text('프로젝트 생성'),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 제목 및 모집 상태 배지
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _StatusBadge(isRecruiting: project.isRecruiting),
                ],
              ),
              const SizedBox(height: 8),

              // 설명 (최대 2줄)
              Text(
                project.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),

              // 하단 정보 행 (기술 스택 + 조회수/좋아요)
              Row(
                children: [
                  // 기술 스택
                  Icon(Icons.code, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      project.techStack.isEmpty ? '미정' : project.techStack,
                      style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // 👁️ 조회수 표시
                  Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text('${project.viewCount}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(width: 12),

                  // ❤️ 좋아요 수 표시 (내가 눌렀으면 빨간색)
                  Icon(
                      project.isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: project.isLiked ? Colors.red : Colors.grey[500]
                  ),
                  const SizedBox(width: 4),
                  Text('${project.likeCount}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isRecruiting;
  const _StatusBadge({required this.isRecruiting});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isRecruiting ? Colors.green[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isRecruiting ? '모집중' : '마감',
        style: TextStyle(
          fontSize: 12,
          color: isRecruiting ? Colors.green[800] : Colors.grey[600],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}