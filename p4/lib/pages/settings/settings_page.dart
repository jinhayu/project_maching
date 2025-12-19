import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import '../splash_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 💡 FIX 1: const 생성자 호출 오류 해결을 위해 const 제거
  final SettingsService _settingsService = SettingsService();

  // 비밀번호 변경 다이얼로그
  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('비밀번호 변경'), // 💡 FIX: const 추가
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('새로운 비밀번호를 입력해주세요.'), // 💡 FIX: const 추가
            const SizedBox(height: 16), // 💡 FIX: const 추가
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration( // 💡 FIX: const 추가
                labelText: '새 비밀번호',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')), // 💡 FIX: const 추가
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('비밀번호는 6자 이상이어야 합니다.'))); // 💡 FIX: const 추가
                return;
              }
              try {
                await _settingsService.updatePassword(passwordController.text);

                if (!ctx.mounted) return;

                Navigator.pop(ctx);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('비밀번호가 변경되었습니다.'))); // 💡 FIX: const 추가
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('변경 실패'))); // 💡 FIX: const 추가
              }
            },
            child: const Text('변경'), // 💡 FIX: const 추가
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
        title: const Text('회원 탈퇴', style: TextStyle(color: Colors.red)), // 💡 FIX: const 추가
        content: const Text('정말 탈퇴하시겠습니까?\n작성한 프로필과 데이터가 삭제되며 복구할 수 없습니다.'), // 💡 FIX: const 추가
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')), // 💡 FIX: const 추가
          TextButton(
            onPressed: () async {
              try {
                await _settingsService.deleteAccount();

                if (!mounted) return;

                // 스플래시 화면으로 이동하며 모든 경로 제거
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SplashPage()), // 💡 FIX: const 추가
                      (route) => false,
                );
              } catch (e) {
                if (!ctx.mounted) return;
                Navigator.pop(ctx); // 다이얼로그 닫기

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('탈퇴 처리 실패. 잠시 후 다시 시도해주세요.'))); // 💡 FIX: const 추가
              }
            },
            child: const Text('탈퇴하기', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), // 💡 FIX: const 추가
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'), // 💡 FIX: const 추가
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black), // 💡 FIX: const 추가
      ),
      body: ListView(
        padding: const EdgeInsets.all(20), // 💡 FIX: const 추가
        children: [
          const _SectionHeader(title: '계정 관리'), // 💡 FIX: const 추가
          const SizedBox(height: 8), // 💡 FIX: const 추가
          _SettingsTile(
            icon: Icons.lock_reset,
            title: '비밀번호 변경',
            onTap: _showChangePasswordDialog,
          ),

          const SizedBox(height: 32), // 💡 FIX: const 추가

          const _SectionHeader(title: '앱 정보'), // 💡 FIX: const 추가
          const SizedBox(height: 8), // 💡 FIX: const 추가
          _SettingsTile(
            icon: Icons.info_outline,
            title: '버전 정보',
            trailingText: _settingsService.getAppVersion(),
            onTap: () {},
          ),
          const SizedBox(height: 8), // 💡 FIX: const 추가
          _SettingsTile(
            icon: Icons.description_outlined,
            title: '이용약관',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이용약관 페이지 준비 중입니다.'))); // 💡 FIX: const 추가
            },
          ),
          const SizedBox(height: 8), // 💡 FIX: const 추가
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: '개인정보 처리방침',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('개인정보 처리방침 페이지 준비 중입니다.'))); // 💡 FIX: const 추가
            },
          ),

          const SizedBox(height: 32), // 💡 FIX: const 추가

          const _SectionHeader(title: '기타', color: Colors.red), // 💡 FIX: const 추가
          const SizedBox(height: 8), // 💡 FIX: const 추가
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

  // 💡 FIX 2: super-parameters 대신 Key? key 사용
  const _SectionHeader({Key? key, required this.title, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8), // 💡 FIX: const 추가
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

  // 💡 FIX 3: super-parameters 대신 Key? key 사용
  const _SettingsTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingText,
    this.textColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0, // 💡 FIX: const 추가
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // 💡 FIX: const 추가
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8), // 💡 FIX: const 추가
          decoration: BoxDecoration(
            color: (iconColor ?? Colors.blue).withValues(alpha: 0.1),
            shape: BoxShape.circle, // 💡 FIX: const 추가
          ),
          child: Icon(icon, color: iconColor ?? Colors.blue, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: textColor ?? Colors.white,
          ),
        ),
        trailing: trailingText != null
            ? Text(trailingText!, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold))
            : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70), // 💡 FIX: const 추가
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // 💡 FIX: const 추가
      ),
    );
  }
}