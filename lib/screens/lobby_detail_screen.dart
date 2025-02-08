import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:the_mind_game/models/user_model.dart';

import '../models/lobby_model.dart';
import '../services/lobby_service.dart';

class LobbyDetailScreen extends StatelessWidget {
  final String lobbyId;
  final LobbyService lobbyService;

  const LobbyDetailScreen({
    Key? key,
    required this.lobbyId,
    required this.lobbyService,
  }) : super(key: key);

  Future<void> _join() async {
    await lobbyService.joinLobby(lobbyId);
  }

  Future<void> _leave() async {
    await lobbyService.leaveLobby(lobbyId);
  }

  Future<void> _startGame() async {
    try {
      await lobbyService.startLobby(lobbyId);
    } catch (e) {
      print("Errore avvio lobby: $e");
      // mostrare snackbar o dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lobby $lobbyId"),
      ),
      body: StreamBuilder<Lobby?>(
        stream: lobbyService.getLobbyStream(lobbyId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          final lobby = snapshot.data;
          if (lobby == null) {
            return Center(child: Text("Lobby non trovata"));
          }

          final currentUid = FirebaseAuth.instance.currentUser?.uid;

          return FutureBuilder<List<UserModel>>(
            future: lobbyService.fetchPlayersData(lobby.players),
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
                  if (currentUid == lobby.hostUid && lobby.status == "waiting")
                    ElevatedButton(
                      onPressed: _startGame,
                      child: Text("Start"),
                    )
                ],
              );
            },
          );
        },
      ),
    );
  }
}
