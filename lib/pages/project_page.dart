import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter/foundation.dart'; // 💥 불필요한 import 제거

// 프로젝트 데이터를 담을 클래스에 'required_skills' 추가
class Project {
  final String id;
  final String title;
  final String description;
  final String ownerId;
  final List<String> requiredSkills; // (AI 매칭용)
  double matchScore; // 💥 non-final 필드

  // 💥 const 생성자 제거 (오류 해결)
  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.ownerId,
    required this.requiredSkills,
    this.matchScore = 0.0, // 기본값 0
  });
}

class ProjectPage extends StatefulWidget {
  const ProjectPage({Key? key}) : super(key: key);

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  late final SupabaseClient _client;
  List<Project> _projects = [];
  List<String> _mySkills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() { _isLoading = true; });
    try {
      await _loadMySkills();
      await _loadProjectsAndCalculateScores();
    } catch (e) {
      _showErrorSnackBar('데이터 초기화 실패: $e');
    }
    setState(() { _isLoading = false; });
  }

  Future<void> _loadMySkills() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('profiles')
        .select('skills')
        .eq('id', userId)
        .single();
    final skillsList = (data['skills'] as List<dynamic>?) ?? [];
    _mySkills = skillsList.map((skill) => skill as String).toList();
  }

  Future<void> _loadProjectsAndCalculateScores() async {
    final response = await _client
        .from('projects')
        .select()
        .order('created_at', ascending: false);

    final List<Project> loadedProjects = response.map((data) {
      final skillsList = (data['required_skills'] as List<dynamic>?) ?? [];
      final requiredSkills = skillsList.map((skill) => skill as String).toList();

      final project = Project(
        id: data['id'] as String,
        title: data['title'] as String,
        description: data['description'] as String,
        ownerId: data['owner_id'] as String,
        requiredSkills: requiredSkills,
      );
      project.matchScore = _calculateMockMatchScore(requiredSkills);
      return project;
    }).toList();

    loadedProjects.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    setState(() {
      _projects = loadedProjects;
    });
  }

  double _calculateMockMatchScore(List<String> requiredSkills) {
    if (requiredSkills.isEmpty) {
      return 0;
    }
    final commonSkills = _mySkills.where((mySkill) {
      final mySkillTrimmed = mySkill.trim().toLowerCase();
      return requiredSkills.any((reqSkill) =>
      reqSkill.trim().toLowerCase() == mySkillTrimmed
      );
    }).length;
    final score = (commonSkills / requiredSkills.length) * 100;
    return score;
  }


  void _showAddProjectDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final skillsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('새 프로젝트 생성'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(hintText: '프로젝트 제목'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(hintText: '프로젝트 설명'),
                ),
                TextField(
                  controller: skillsController,
                  decoration: const InputDecoration(
                    hintText: '필요 스킬 (쉼표로 구분)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;

                try {
                  final userId = _client.auth.currentUser!.id;

                  final skillsList = skillsController.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();

                  final newProjectData = await _client.from('projects').insert({
                    'owner_id': userId,
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'required_skills': skillsList,
                  }).select();

                  if (!mounted) return; // 💥 Context 경고 해결

                  final newProject = Project(
                    id: newProjectData[0]['id'] as String,
                    title: newProjectData[0]['title'] as String,
                    description: newProjectData[0]['description'] as String,
                    ownerId: newProjectData[0]['owner_id'] as String,
                    requiredSkills: skillsList,
                    matchScore: _calculateMockMatchScore(skillsList),
                  );

                  setState(() {
                    _projects.insert(0, newProject);
                    _projects.sort((a, b) => b.matchScore.compareTo(a.matchScore));
                  });

                  Navigator.pop(context);
                } catch (e) {
                  if (!mounted) return; // 💥 Context 경고 해결
                  _showErrorSnackBar('프로젝트 저장 실패: $e');
                }
              },
              child: const Text('생성'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color scaffoldBgColor = Color.fromARGB(255, 237, 231, 246); // Light Purple for the content area
    const Color appBarColor = Colors.white;
    const Color textColor = Colors.black;
    final Color iconColor = Colors.grey.shade600;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 1,
        title: const Text('프로젝트 목록', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: iconColor),
            tooltip: '새 프로젝트 생성',
            onPressed: _showAddProjectDialog,
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _initializeData, // 당겨서 새로고침 (매칭 점수 다시 계산)
        child: ListView.builder(
          itemCount: _projects.length,
          itemBuilder: (context, index) {
            final project = _projects[index];
            return Column(
              children: [
                ListTile(
                  title: Text(project.title, style: const TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  subtitle: Text(project.description, style: TextStyle(color: iconColor)),
                  leading: CircleAvatar(
                    child: Text('${project.matchScore.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    backgroundColor: project.matchScore > 70 ? Colors.green.shade600 : (project.matchScore > 30 ? Colors.orange.shade600 : Colors.grey.shade600),
                  ),
                  // 💥 child 속성 순서 경고 해결
                  trailing: Text(
                    project.requiredSkills.join(', '),
                    style: TextStyle(fontSize: 12, color: iconColor),
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade300),
              ],
            );
          },
        ),
      ),
    );
  }
}