import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// '_ProfileForm'의 이름을 'ProfilePage'로 변경했습니다.
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  var _loading = true;
  final _usernameController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void initState() {
    _loadProfile();
    super.initState();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final ScaffoldMessengerState scaffoldMessenger =
    ScaffoldMessenger.of(context);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = (await Supabase.instance.client
          .from('profiles')
          .select()
          .match({'id': userId}).maybeSingle());
      if (data != null) {
        setState(() {
          _usernameController.text = data['username'];
          _websiteController.text = data['website'];
        });
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Error occurred while getting profile'),
        backgroundColor: Colors.red,
      ));
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              label: Text('Username'),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _websiteController,
            decoration: const InputDecoration(
              label: Text('Website'),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: () async {
                final ScaffoldMessengerState scaffoldMessenger =
                ScaffoldMessenger.of(context);
                try {
                  setState(() {
                    _loading = true;
                  });
                  final userId =
                      Supabase.instance.client.auth.currentUser!.id;
                  final username = _usernameController.text;
                  final website = _websiteController.text;
                  await Supabase.instance.client.from('profiles').upsert({
                    'id': userId,
                    'username': username,
                    'website': website,
                  });
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(const SnackBar(
                      content: Text('Saved profile'),
                    ));
                  }
                } catch (e) {
                  scaffoldMessenger.showSnackBar(const SnackBar(
                    content: Text('Error saving profile'),
                    backgroundColor: Colors.red,
                  ));
                }
                setState(() {
                  _loading = false;
                });
              },
              child: const Text('Save')),
          const SizedBox(height: 16),
          TextButton(
              onPressed: () => Supabase.instance.client.auth.signOut(),
              child: const Text('Sign Out')),
        ],
      ),
    );
  }
}