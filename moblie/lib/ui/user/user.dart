import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moblie/Account/login_screen.dart';
import 'package:moblie/ui/user/user_information.dart';

class AccountTab extends StatefulWidget {
  @override
  _AccountTabState createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  User? user = FirebaseAuth.instance.currentUser;
  String? userName = '';
  String? userEmail = '';
  String? userPhotoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userName = user!.displayName;
        userEmail = user!.email;
        userPhotoUrl = user!.photoURL;
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tài khoản của tôi'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl!) : null,
              child: userPhotoUrl == null ? Icon(Icons.account_circle, size: 50) : null,
            ),
            SizedBox(height: 16),
            Text(
              userName ?? 'Tên người dùng',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              userEmail ?? 'Email người dùng',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 32),
            ListTile(
              leading: Icon(Icons.playlist_play),
              title: Text('Danh sách phát của tôi'),
              onTap: () {
                // Navigate to My Playlists page
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('Bài hát yêu thích'),
              onTap: () {
                // Navigate to Favorite Songs page
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Lịch sử nghe nhạc'),
              onTap: () {
                // Navigate to Listening History page
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Cài đặt tài khoản'),
              onTap: () async {
                bool? result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => AccountSettingsPage()),
                );
                if (result == true) {
                  // Reload user info if data was updated
                  await _loadUserInfo();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
