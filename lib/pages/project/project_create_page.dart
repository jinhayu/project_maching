import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // 폰트 깨짐 방지
import '../../services/project_service.dart';

class ProjectCreatePage extends StatefulWidget {
  const ProjectCreatePage({Key? key}) : super(key: key);

  @override
  State<ProjectCreatePage> createState() => _ProjectCreatePageState();
}

class _ProjectCreatePageState extends State<ProjectCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _projectService = ProjectService();

  // 컨트롤러 초기화
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _techStackController = TextEditingController();
  final _maxMembersController = TextEditingController(text: '4');

  bool _isSubmitting = false;

  @override
  void dispose() {
    // 메모리 누수 방지를 위해 컨트롤러 해제
    _titleController.dispose();
    _descController.dispose();
    _techStackController.dispose();
    _maxMembersController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // 키보드 내리기
    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);

    try {
      await _projectService.createProject(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        techStack: _techStackController.text.trim(),
        maxMembers: int.tryParse(_maxMembersController.text) ?? 4,
      );

      // 💡 FIX: 비동기 작업 후 context 사용 전 mounted 체크 (반복되는 오류 해결)
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로젝트가 성공적으로 생성되었습니다!'),
            backgroundColor: Colors.green,
          )
      );
      Navigator.pop(context, true); // true를 반환하여 목록 새로고침 유도

    } catch (e) {
      // 💡 FIX: mounted 체크
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('생성 실패: $e'),
            backgroundColor: Colors.red,
          )
      );
    } finally {
      // 💡 FIX: mounted 체크
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 프로젝트 만들기'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('기본 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // 1. 제목 입력
              TextFormField(
                controller: _titleController,
                // 💡 한글 입력 시 엑스박스(Tofu) 방지
                style: GoogleFonts.notoSansKr(),
                decoration: const InputDecoration(
                  labelText: '프로젝트 제목',
                  hintText: '예: 플러터 스터디 모집합니다',
                  prefixIcon: Icon(Icons.title),
                ),
                textInputAction: TextInputAction.next,
                validator: (val) => val!.trim().isEmpty ? '제목을 입력해주세요' : null,
              ),
              const SizedBox(height: 16),

              // 2. 기술 스택 & 모집 인원 (Row로 배치)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _techStackController,
                      style: GoogleFonts.notoSansKr(),
                      decoration: const InputDecoration(
                        labelText: '기술 스택',
                        hintText: 'Flutter, Node.js',
                        prefixIcon: Icon(Icons.code),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _maxMembersController,
                      style: GoogleFonts.notoSansKr(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '모집 인원',
                        prefixIcon: Icon(Icons.people),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (val) {
                        if (val == null || val.isEmpty) return '필수';
                        if (int.tryParse(val) == null) return '숫자만';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const Text('상세 내용', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // 3. 상세 설명 입력
              TextFormField(
                controller: _descController,
                style: GoogleFonts.notoSansKr(),
                maxLines: 12, // 넉넉한 높이
                decoration: const InputDecoration(
                  hintText: '프로젝트의 목표, 예상 기간, 필요한 역할, 회의 방식 등을 자세히 적어주세요.',
                  alignLabelWithHint: true, // 레이블을 상단에 정렬
                  contentPadding: EdgeInsets.all(20),
                ),
                validator: (val) => val!.trim().isEmpty ? '내용을 입력해주세요' : null,
              ),

              const SizedBox(height: 32),

              // 4. 저장 버튼
              SizedBox(
                width: double.infinity,
                height: 56, // 버튼 높이 키움
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                      : const Text('작성 완료'),
                ),
              ),
              const SizedBox(height: 40), // 하단 여백
            ],
          ),
        ),
      ),
    );
  }
}