import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/project_model.dart';
import '../../models/application_model.dart';
import '../../services/mypage_service.dart';
import '../project/project_detail_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MyPageService _myPageService = MyPageService();

  // 데이터 상태 변수
  List<Project> _createdProjects = [];
  List<Project> _participatingProjects = [];
  List<Application> _myApplications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 3가지 데이터를 한 번에 로드
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final created = await _myPageService.fetchCreatedProjects();
      final participating = await _myPageService.fetchParticipatingProjects();
      final applications = await _myPageService.fetchMyApplications();

      if (mounted) {
        setState(() {
          _createdProjects = created;
          _participatingProjects = participating;
          _myApplications = applications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 활동'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: '내가 만든'),
            Tab(text: '참여 중'),
            Tab(text: '지원 현황'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          // 1. 내가 만든 프로젝트
          _ProjectList(
            projects: _createdProjects,
            emptyMessage: '생성한 프로젝트가 없습니다.',
            isOwnerList: true,
          ),

          // 2. 참여 중인 프로젝트
          _ProjectList(
            projects: _participatingProjects,
            emptyMessage: '참여 중인 프로젝트가 없습니다.',
          ),

          // 3. 지원 현황
          _ApplicationList(
            applications: _myApplications,
            emptyMessage: '지원 내역이 없습니다.',
          ),
        ],
      ),
    );
  }
}

// 프로젝트 리스트 위젯 (재사용)
class _ProjectList extends StatelessWidget {
  final List<Project> projects;
  final String emptyMessage;
  final bool isOwnerList;

  const _ProjectList({
    required this.projects,
    required this.emptyMessage,
    this.isOwnerList = false,
  });

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final project = projects[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(project.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                isOwnerList ? '지원자 관리 및 수정' : '프로젝트 상세 보기',
                style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProjectDetailPage(project: project)),
              );
            },
          ),
        );
      },
    );
  }
}

// 지원 현황 리스트 위젯
class _ApplicationList extends StatelessWidget {
  final List<Application> applications;
  final String emptyMessage;

  const _ApplicationList({required this.applications, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: applications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final app = applications[index];
        // Application 모델의 project 필드를 통해 제목 가져오기
        final projectTitle = app.project?.title ?? '알 수 없는 프로젝트';

        Color statusColor;
        String statusText;
        IconData statusIcon;

        switch (app.status) {
          case 'accepted':
            statusColor = Colors.green;
            statusText = '합격';
            statusIcon = Icons.check_circle;
            break;
          case 'rejected':
            statusColor = Colors.red;
            statusText = '불합격';
            statusIcon = Icons.cancel;
            break;
          default:
            statusColor = Colors.orange;
            statusText = '대기중';
            statusIcon = Icons.hourglass_empty;
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(projectTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('지원일: ${DateFormat('yyyy.MM.dd').format(app.createdAt)}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    // 💡 FIX: withOpacity 대신 withValues 사용 (Deprecated 해결)
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}