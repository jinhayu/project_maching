import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/profile_model.dart';
import '../../services/profile_service.dart';

class ProfileEditPage extends StatefulWidget {
  final Profile profile;

  const ProfileEditPage({Key? key, required this.profile}) : super(key: key);

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();

  late TextEditingController _usernameController;
  late TextEditingController _departmentController; // 💡 FIX: department 컨트롤러
  late TextEditingController _bioController;
  late TextEditingController _techStackController;
  late TextEditingController _blogUrlController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // 💡 FIX: department 필드를 사용해 컨트롤러 초기화
    _usernameController = TextEditingController(text: widget.profile.username);
    _departmentController = TextEditingController(text: widget.profile.department);
    _bioController = TextEditingController(text: widget.profile.bio);
    _techStackController = TextEditingController(text: widget.profile.techStack);
    _blogUrlController = TextEditingController(text: widget.profile.blogUrl);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _departmentController.dispose();
    _bioController.dispose();
    _techStackController.dispose();
    _blogUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // 💡 FIX: department 인자 전달
      await _profileService.updateProfile(
        username: _usernameController.text,
        department: _departmentController.text,
        bio: _bioController.text,
        techStack: _techStackController.text,
        blogUrl: _blogUrlController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장되었습니다.')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장 실패')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _usernameController,
                style: GoogleFonts.notoSansKr(),
                decoration: const InputDecoration(
                  labelText: '닉네임',
                  border: OutlineInputBorder(),
                  helperText: '앱에서 표시될 이름입니다.',
                ),
                validator: (val) => val!.isEmpty ? '닉네임을 입력해주세요' : null,
              ),
              const SizedBox(height: 16),

              // 💡 FIX: 학부/학과 입력 필드
              TextFormField(
                controller: _departmentController,
                style: GoogleFonts.notoSansKr(),
                decoration: const InputDecoration(
                  labelText: '학부 / 학과', // 라벨 변경
                  border: OutlineInputBorder(),
                  hintText: '예: 컴퓨터공학과, 시각디자인과',
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _techStackController,
                style: GoogleFonts.notoSansKr(),
                decoration: const InputDecoration(
                  labelText: '주요 기술 스택',
                  border: OutlineInputBorder(),
                  hintText: '예: Dart, Firebase, Figma',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                style: GoogleFonts.notoSansKr(),
                decoration: const InputDecoration(
                  labelText: '자기소개',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  hintText: '자신을 자유롭게 소개해주세요.',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _blogUrlController,
                keyboardType: TextInputType.url,
                style: GoogleFonts.notoSansKr(),
                decoration: const InputDecoration(
                  labelText: '블로그 / 포트폴리오 링크',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}