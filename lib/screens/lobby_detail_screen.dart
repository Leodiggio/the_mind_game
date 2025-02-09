import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:the_mind_game/models/user_model.dart';

import '../models/lobby_model.dart';
import '../services/lobby_service.dart';
import 'game_screen.dart';

class LobbyDetailScreen extends StatefulWidget {
  final String lobbyId;
  final LobbyService lobbyService;

  const LobbyDetailScreen({
    Key? key,
    required this.lobbyId,
    required this.lobbyService,
  }) : super(key: key);

  @override
  State<LobbyDetailScreen> createState() => _LobbyDetailScreenState();
}

class _LobbyDetailScreenState extends State<LobbyDetailScreen> {
  Future<void> _join() async {
    await widget.lobbyService.joinLobby(widget.lobbyId);
  }

  Future<void> _leave() async {
    await widget.lobbyService.leaveLobby(widget.lobbyId);
  }

  Future<void> _startGame() async {
    try {
      // 1) Avvia la partita su Firestore (status inGame + creazione gameState)
      await widget.lobbyService.startLobby(widget.lobbyId);

      // 2) Ora navighi direttamente alla GameScreen
      //setState(() {
      //});

      //Navigator.pushReplacement(
      //  context,
      //  MaterialPageRoute(
      //    builder: (context) => GameScreen(lobbyId: widget.lobbyId),
      //  ),
      //);
    } catch (e) {
      print("Errore avvio lobby: $e");
      // mostrare snackbar o dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lobby $widget.lobbyId"),
      ),
      body: StreamBuilder<Lobby?>(
        stream: widget.lobbyService.getLobbyStream(widget.lobbyId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final lobby = snapshot.data;
          if (lobby == null) {
            return Center(child: Text("Lobby non trovata"));
          }

          // Se la lobby è passata a "inGame" E non abbiamo ancora navigato,
          // vai alla GameScreen automaticamente.
          if (lobby.status == 'inGame') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => GameScreen(lobbyId: lobby.lobbyId),
                ),
              );
            });
          }

          final currentUid = FirebaseAuth.instance.currentUser?.uid;

          return FutureBuilder<List<UserModel>>(
            future: widget.lobbyService.fetchPlayersData(lobby.players),
            builder: (context, usersSnapshot) {
              if (usersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (usersSnapshot.hasError) {
                return Text(
                    "Errore caricamento utenti: ${usersSnapshot.error}");
              }
              final userModels = usersSnapshot.data ?? [];

              return Column(
                children: [
                  Text("Host: ${lobby.hostUid}"),
                  Text("Status: ${lobby.status}"),
                  Divider(),
                  Text("Players:"),
                  ...userModels.map((u) => Text(u.nickname)).toList(),
                  Divider(),
                  Row(
                    children: [
                      // Pulsanti di join/leave
                      ElevatedButton(
                        onPressed: _join,
                        child: Text("Join"),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      ElevatedButton(
                        onPressed: _leave,
                        child: Text("Leave"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (currentUid == lobby.hostUid && lobby.status == "waiting")
                    ElevatedButton(
                      onPressed: _startGame,
                      child: Text("Start"),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
