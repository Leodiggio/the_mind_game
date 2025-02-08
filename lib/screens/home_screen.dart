import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:the_mind_game/services/auth_service.dart';
import 'package:the_mind_game/services/user_service.dart';
import 'package:the_mind_game/services/lobby_service.dart';
import 'package:the_mind_game/screens/lobby_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserService userService;
  final AuthService authService;

  const HomeScreen({
    Key? key,
    required this.userService,
    required this.authService,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? nickname;
  bool isLoading = true;

  final lobbyService = LobbyService(); // Iniettiamo o creiamo qui

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

  // TEST: Naviga alla LobbyList per vedere le lobby "waiting" e potersi unire
  void _goLobbyList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LobbyListScreen(lobbyService: lobbyService),
      ),
    );
  }

  // TEST: Creazione rapida di una lobby e stampo l'ID in console
  Future<void> _quickCreateLobby() async {
    try {
      final lobbyId = await lobbyService.createLobby();
      print("Lobby creata con ID = $lobbyId");
      // Potresti navigare automaticamente alla LobbyDetailScreen(lobbyId)
      // ...
    } catch (e) {
      print("Errore creazione lobby: $e");
    }
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Benvenuto nella Home!"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _quickCreateLobby,
              child: Text("Crea Lobby rapida"),
            ),
            ElevatedButton(
              onPressed: _goLobbyList,
              child: Text("Vai alla Lobby List"),
            ),
          ],
        ),
      ),
    );
  }
}
