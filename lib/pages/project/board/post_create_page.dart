import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/board_service.dart';

class PostCreatePage extends StatefulWidget {
  final String projectId;

  const PostCreatePage({Key? key, required this.projectId}) : super(key: key);

  @override
  State<PostCreatePage> createState() => _PostCreatePageState();
}

class _PostCreatePageState extends State<PostCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final BoardService _boardService = BoardService();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _boardService.createPost(
        projectId: widget.projectId,
        title: _titleController.text,
        content: _contentController.text,
      );
      if (mounted) {
        Navigator.pop(context, true); // 성공 반환
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('게시글이 등록되었습니다.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('등록 실패')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('글쓰기', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: const Text('등록', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.notoSansKr(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: '제목을 입력하세요',
                  border: InputBorder.none,
                ),
                validator: (val) => val!.isEmpty ? '제목을 입력해주세요' : null,
              ),
              const Divider(),
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  style: GoogleFonts.notoSansKr(fontSize: 16),
                  maxLines: null, // 무제한 줄바꿈
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: '내용을 자유롭게 작성해주세요.\n(공지사항, 아이디어, 회의록 등)',
                    border: InputBorder.none,
                  ),
                  validator: (val) => val!.isEmpty ? '내용을 입력해주세요' : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}