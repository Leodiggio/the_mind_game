import 'package:flutter/material.dart';

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
    // set status = "started" ?
    // o crea un doc "gameState" con le carte?
    await lobbyService.startLobby(lobbyId);
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
          return Column(
            children: [
              Text("Host: ${lobby.hostUid}"),
              Text("Status: ${lobby.status}"),
              Divider(),
              Text("Players:"),
              ...lobby.players.map((p) => Text(p)).toList(),
              Divider(),
              // Pulsanti di join/leave
              ElevatedButton(
                onPressed: _join,
                child: Text("Join"),
              ),
              ElevatedButton(
                onPressed: _leave,
                child: Text("Leave"),
              ),
              if (/* se l'utente è hostUid */ false)
                ElevatedButton(
                  onPressed: _startGame,
                  child: Text("Start"),
                )
            ],
          );
        },
      ),
    );
  }
}
