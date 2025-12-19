import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/project_model.dart';
import '../../models/comment_model.dart';
import '../../services/project_service.dart';
import '../../services/board_service.dart';
import 'applicant_list_page.dart';
import 'board/project_board_page.dart';

class ProjectDetailPage extends StatefulWidget {
  final Project project;

  const ProjectDetailPage({Key? key, required this.project}) : super(key: key);

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final ProjectService _projectService = ProjectService();
  final TextEditingController _commentController = TextEditingController();

  late bool _isLiked;
  late int _likeCount;
  late int _viewCount;

  bool _hasApplied = false;
  bool _isCheckingApplied = true;
  bool _isTeamMember = false;

  List<Comment> _comments = [];
  bool _isCommentsLoading = true;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.project.isLiked;
    _likeCount = widget.project.likeCount;
    _viewCount = widget.project.viewCount;

    _incrementView();
    _checkAppliedStatus();
    _checkTeamMemberStatus();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // --- 기능 로직 ---

  Future<void> _checkAppliedStatus() async {
    if (_projectService.currentUserId != null) {
      final applied = await _projectService.hasApplied(widget.project.id);
      if (mounted) {
        setState(() {
          _hasApplied = applied;
          _isCheckingApplied = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isCheckingApplied = false);
      }
    }
  }

  Future<void> _checkTeamMemberStatus() async {
    final isMember = await BoardService().isTeamMember(widget.project.id);
    if (mounted) {
      setState(() => _isTeamMember = isMember);
    }
  }

  Future<void> _incrementView() async {
    await _projectService.incrementViewCount(widget.project.id);
    if (mounted) {
      setState(() {
        _viewCount++;
      });
    }
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _projectService.fetchComments(widget.project.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isCommentsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isCommentsLoading = false);
    }
  }

  Future<void> _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    try {
      await _projectService.toggleLike(widget.project.id);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount += _isLiked ? 1 : -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('좋아요 처리 실패')),
        );
      }
    }
  }

  Future<void> _applyProject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('프로젝트 지원'),
        content: const Text('이 프로젝트에 지원하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('지원하기'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _projectService.applyToProject(widget.project.id);
      if (mounted) {
        setState(() => _hasApplied = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('지원이 완료되었습니다!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('지원 실패: $e')),
        );
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    try {
      await _projectService.addComment(
          widget.project.id, _commentController.text.trim());
      if (!mounted) return;
      _commentController.clear();
      FocusScope.of(context).unfocus();
      _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글 등록 실패')),
        );
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    try {
      await _projectService.deleteComment(commentId);
      _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제 실패')),
        );
      }
    }
  }

  // --- UI Helpers ---

  Color _getMatchColor(double score) {
    if (score >= 80) return Colors.green.shade600;
    if (score >= 50) return Colors.orange.shade600;
    return Colors.grey.shade500;
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _projectService.currentUserId == widget.project.ownerId;
    final theme = Theme.of(context);
    final matchScore = widget.project.matchScore.toInt();
    final matchColor = _getMatchColor(widget.project.matchScore);

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로젝트 상세'),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '프로젝트 삭제',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('프로젝트 삭제'),
                    content: const Text('정말 삭제하시겠습니까? 복구할 수 없습니다.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('삭제', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  try {
                    await _projectService.deleteProject(widget.project.id);
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('삭제 실패')),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      // 💡 [구조] 스크롤 영역(내용)과 고정 영역(댓글입력) 분리
      body: Column(
        children: [
          // 1. 상세 내용 (스크롤 가능 영역)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1-1. 헤더 (제목, 좋아요, 매칭 배지)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: matchColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: matchColor.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                '추천 $matchScore%',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: matchColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.project.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '작성일: ${DateFormat('yyyy.MM.dd').format(widget.project.createdAt)} · 조회 $_viewCount',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          InkWell(
                            onTap: _toggleLike,
                            borderRadius: BorderRadius.circular(30),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                _isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isLiked ? Colors.red : Colors.grey[400],
                                size: 28,
                              ),
                            ),
                          ),
                          Text(
                            '$_likeCount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 1-2. 정보 카드
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.check_circle_outline,
                          label: '상태',
                          value: widget.project.isRecruiting ? '모집중' : '마감됨',
                          isHighlight: widget.project.isRecruiting,
                        ),
                        const Divider(height: 24),
                        _DetailRow(
                          icon: Icons.people_outline,
                          label: '모집 인원',
                          value: '${widget.project.maxMembers}명',
                        ),
                        const Divider(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.code,
                                size: 20, color: Colors.grey),
                            const SizedBox(width: 12),
                            const SizedBox(
                              width: 70,
                              child: Text('기술 스택',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey)),
                            ),
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: widget.project.techStack.isNotEmpty
                                    ? widget.project.techStack
                                    .split(',')
                                    .map((tech) => Chip(
                                  label: Text(tech.trim(),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          height: 1.0)),
                                  padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 0,
                                      vertical: -4),
                                  materialTapTargetSize:
                                  MaterialTapTargetSize
                                      .shrinkWrap,
                                  backgroundColor: theme
                                      .colorScheme.primary
                                      .withValues(alpha: 0.05),
                                  side: BorderSide.none,
                                ))
                                    .toList()
                                    : [
                                  const Text('미정',
                                      style: TextStyle(
                                          color: Colors.black87))
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 1-3. 프로젝트 설명
                  Text(
                    '프로젝트 소개',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.project.description,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 1-4. 팀 게시판 버튼
                  if (_isTeamMember)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.dashboard_customize),
                        label: const Text('팀 게시판으로 이동'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: theme.primaryColor),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectBoardPage(
                                projectId: widget.project.id,
                                projectTitle: widget.project.title,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 40),
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),

                  // 1-5. 댓글 목록 섹션
                  Row(
                    children: [
                      Text(
                        '댓글',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_comments.length}',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _isCommentsLoading
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                      : _comments.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        '첫 번째 댓글을 남겨보세요.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                  // 💡 [수정] 스크롤 문제 해결: shrinkWrap & NeverScrollableScrollPhysics
                      : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _comments.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      final isCommentAuthor =
                          _projectService.currentUserId ==
                              comment.userId;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey[200],
                            child: const Icon(Icons.person,
                                size: 20, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      Text(
                                        comment.userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('MM/dd HH:mm')
                                            .format(
                                            comment.createdAt),
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment.content,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isCommentAuthor)
                            IconButton(
                              icon: const Icon(Icons.close,
                                  size: 16, color: Colors.grey),
                              onPressed: () =>
                                  _deleteComment(comment.id),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            )
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 2. 댓글 입력창 (하단 고정)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: '댓글 작성...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(
                      backgroundColor: theme.primaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: ElevatedButton(
          onPressed: isOwner
              ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ApplicantListPage(
                    projectId: widget.project.id),
              ),
            );
          }
              : (_hasApplied ||
              _isCheckingApplied ||
              !widget.project.isRecruiting)
              ? null
              : _applyProject,
          style: ElevatedButton.styleFrom(
            backgroundColor:
            isOwner ? const Color(0xFF10B981) : theme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
          ),
          child: _isCheckingApplied
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : Text(
            isOwner
                ? '지원자 관리 (${widget.project.title})'
                : _hasApplied
                ? '지원 완료 (대기중)'
                : (widget.project.isRecruiting
                ? '프로젝트 지원하기'
                : '모집 마감'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isHighlight;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color:
              isHighlight ? Theme.of(context).primaryColor : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}