import 'package:flutter/material.dart';
import '../../models/application_model.dart';
import '../../services/project_service.dart';
import '../profile_page.dart';

class ApplicantListPage extends StatefulWidget {
  final String projectId;

  const ApplicantListPage({Key? key, required this.projectId}) : super(key: key);

  @override
  State<ApplicantListPage> createState() => _ApplicantListPageState();
}

class _ApplicantListPageState extends State<ApplicantListPage> {
  final ProjectService _projectService = ProjectService();
  List<Application> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    try {
      final apps = await _projectService.fetchApplications(widget.projectId);
      if (mounted) {
        setState(() {
          _applications = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(Application app, String status) async {
    try {
      await _projectService.updateApplicationStatus(app.id, status);
      _loadApplications();
      if (mounted) {
        String msg = status == 'accepted' ? '승인되었습니다.' : '거절되었습니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('오류가 발생했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('지원자 관리'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('아직 지원자가 없습니다.', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _applications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _ApplicantCard(
            application: _applications[index],
            onAccept: () => _updateStatus(_applications[index], 'accepted'),
            onReject: () => _updateStatus(_applications[index], 'rejected'),
            onViewProfile: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfilePage(userId: _applications[index].applicantId)),
              );
            },
          );
        },
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final Application application;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onViewProfile;

  const _ApplicantCard({
    required this.application,
    required this.onAccept,
    required this.onReject,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    Color bgColor;

    switch (application.status) {
      case 'accepted':
        statusColor = Colors.green;
        statusText = '승인됨';
        bgColor = Colors.green.withValues(alpha: 0.05);
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = '거절됨';
        bgColor = Colors.red.withValues(alpha: 0.05);
        break;
      default:
        statusColor = Colors.orange;
        statusText = '대기중';
        bgColor = Colors.orange.withValues(alpha: 0.05);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.applicantName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        application.applicantPosition,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),

            if (application.status == 'pending') ...[
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onViewProfile,
                      child: const Text('프로필 보기'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('거절'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('승인'),
                    ),
                  ),
                ],
              )
            ] else ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: onViewProfile,
                  icon: const Icon(Icons.person_search),
                  label: const Text('지원자 프로필 보기'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}