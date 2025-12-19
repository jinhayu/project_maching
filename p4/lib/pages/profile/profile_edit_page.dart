import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/profile_model.dart';
import '../../services/profile_service.dart';

class ProfileEditPage extends StatefulWidget {
  final Profile profile;

  const ProfileEditPage({super.key, required this.profile});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();

  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _techStackController;
  late TextEditingController _blogUrlController;

  String? _selectedDepartment;

  final List<String> _departmentOptions = [
    'IT/컴퓨터/SW (컴공, AI, 소웨 등)',
    '디자인/조형예술 (시각, 산업, UI/UX 등)',
    '미디어/콘텐츠/언론 (광고, 영상, 신방 등)',
    '경영/경제/마케팅 (경영, 경제, 회계 등)',
    '기계/전자/건축 (기계, 전기, 토목 등)',
    '화학/생명/환경 (화공, 신소재, 바이오 등)',
    '인문/어문/교육 (국문, 영문, 교육 등)',
    '사회과학/심리 (심리, 사회, 행정 등)',
    '의학/간호/보건 (간호, 스포츠, 보건 등)',
    '기타 (자율전공, 예체능 등)',
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.profile.username);
    _bioController = TextEditingController(text: widget.profile.bio);
    _techStackController =
        TextEditingController(text: widget.profile.techStack);
    _blogUrlController = TextEditingController(text: widget.profile.blogUrl);

    if (widget.profile.department != null &&
        _departmentOptions.contains(widget.profile.department)) {
      _selectedDepartment = widget.profile.department;
    } else {
      _selectedDepartment = null;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _techStackController.dispose();
    _blogUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('학과(전공 계열)를 선택해주세요.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _profileService.updateProfile(
        username: _usernameController.text,
        // 💡 [수정] null check 에러 해결 (! 추가)
        // 위에서 _selectedDepartment == null 체크를 했으므로 안전합니다.
        department: _selectedDepartment!,
        bio: _bioController.text,
        techStack: _techStackController.text,
        blogUrl: _blogUrlController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('저장되었습니다.')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('저장 실패')));
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
                ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('저장',
                style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

              DropdownButtonFormField<String>(
                // 💡 [참고] value를 사용하면 상태 관리가 쉽지만 경고가 뜰 수 있습니다.
                // 여기서는 직관적인 동작을 위해 value를 유지합니다.
                value: _selectedDepartment,
                decoration: const InputDecoration(
                  labelText: '학과 (전공 계열)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
                items: _departmentOptions.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(
                      category,
                      style: GoogleFonts.notoSansKr(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedDepartment = newValue;
                  });
                },
                validator: (value) => value == null ? '학과를 선택해주세요' : null,
              ),
              const SizedBox(height: 8),
              Text(
                "※ 융합 프로젝트 매칭을 위해 가장 가까운 계열을 선택해주세요.",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 24),

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