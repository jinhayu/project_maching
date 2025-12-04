import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../splash_page.dart'; // 탈퇴 후 이동용

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settingsService = SettingsService();

  // 비밀번호 변경 다이얼로그
  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('비밀번호 변경'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('새로운 비밀번호를 입력해주세요.'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '새 비밀번호',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('비밀번호는 6자 이상이어야 합니다.')));
                return;
              }
              try {
                await _settingsService.updatePassword(passwordController.text);

                // 💡 FIX: 다이얼로그 컨텍스트(ctx)가 마운트된 상태인지 확인
                if (!ctx.mounted) return;

                Navigator.pop(ctx);

                // 💡 FIX: 메인 컨텍스트(context)가 마운트된 상태인지 확인
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('비밀번호가 변경되었습니다.')));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('변경 실패')));
              }
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  // 회원 탈퇴 다이얼로그
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원 탈퇴', style: TextStyle(color: Colors.red)),
        content: const Text('정말 탈퇴하시겠습니까?\n작성한 프로필과 데이터가 삭제되며 복구할 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              try {
                await _settingsService.deleteAccount();

                // 💡 FIX: 비동기 작업 후 mounted 체크
                if (!mounted) return;

                // 스플래시 화면으로 이동하며 모든 경로 제거
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SplashPage()),
                      (route) => false,
                );
              } catch (e) {
                if (!ctx.mounted) return;
                Navigator.pop(ctx); // 다이얼로그 닫기

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('탈퇴 처리 실패. 잠시 후 다시 시도해주세요.')));
              }
            },
            child: const Text('탈퇴하기', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionHeader(title: '계정 관리'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.lock_reset,
            title: '비밀번호 변경',
            onTap: _showChangePasswordDialog,
          ),

          const SizedBox(height: 32),

          const _SectionHeader(title: '앱 정보'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.info_outline,
            title: '버전 정보',
            trailingText: _settingsService.getAppVersion(),
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: '이용약관',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이용약관 페이지 준비 중입니다.')));
            },
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: '개인정보 처리방침',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('개인정보 처리방침 페이지 준비 중입니다.')));
            },
          ),

          const SizedBox(height: 32),

          const _SectionHeader(title: '기타', color: Colors.red),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.person_off_outlined,
            title: '회원 탈퇴',
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;

  const _SectionHeader({required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color ?? Colors.grey[600],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? trailingText;
  final Color? textColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingText,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? Colors.blue).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? Colors.blue, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: textColor ?? Colors.black87,
          ),
        ),
        trailing: trailingText != null
            ? Text(trailingText!, style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold))
            : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}