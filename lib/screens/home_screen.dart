import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:the_mind_game/services/auth_service.dart';
import 'package:the_mind_game/services/user_service.dart'; // o AuthService

class HomeScreen extends StatefulWidget {
  final UserService userService;
  final AuthService authService;

  const HomeScreen(
      {Key? key, required this.userService, required this.authService})
      : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? nickname;
  bool isLoading = true;

  void _logout() async {
    await widget.authService.logout();
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }
    final loadedNickname = await widget.userService.getNickname(uid);
    setState(() {
      nickname = loadedNickname;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = isLoading
        ? 'Caricamento...'
        : (nickname == null ? 'Nessun nickname' : 'Ciao, $nickname');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          ),
        ],
      ),
      body: Center(
        child: const Text("Benvenuto nella Home!"),
      ),
    );
  }
}
