import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/post_model.dart';
import '../../../services/board_service.dart';
import 'post_create_page.dart';
import 'post_detail_page.dart';

class ProjectBoardPage extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const ProjectBoardPage({
    Key? key,
    required this.projectId,
    required this.projectTitle
  }) : super(key: key);

  @override
  State<ProjectBoardPage> createState() => _ProjectBoardPageState();
}

class _ProjectBoardPageState extends State<ProjectBoardPage> {
  final BoardService _boardService = BoardService();
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    final posts = await _boardService.fetchPosts(widget.projectId);
    if (mounted) {
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.projectTitle} 게시판', style: const TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
          ? const Center(child: Text('작성된 글이 없습니다.\n팀원들에게 인사를 건네보세요!', textAlign: TextAlign.center))
          : RefreshIndicator(
        onRefresh: _loadPosts,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _posts.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final post = _posts[index];
            return ListTile(
              title: Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${post.authorName} · ${DateFormat('MM/dd HH:mm').format(post.createdAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                // 상세 페이지 이동
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
                );
                _loadPosts(); // 돌아오면 목록 갱신 (삭제 등 반영)
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 글쓰기 페이지 이동
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostCreatePage(projectId: widget.projectId),
            ),
          );
          if (result == true) _loadPosts();
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}