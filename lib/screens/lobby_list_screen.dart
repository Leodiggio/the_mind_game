import 'package:flutter/material.dart';

import '../models/lobby_model.dart';
import '../services/lobby_service.dart';

class LobbyListScreen extends StatelessWidget {
  final LobbyService lobbyService;

  const LobbyListScreen({Key? key, required this.lobbyService}) : super(key: key);

  Future<void> _createLobby() async {
    final id = await lobbyService.createLobby();
    // Poi navighi alla LobbyDetailScreen dell'id creato
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lobby List"),
      ),
      body: StreamBuilder<List<Lobby>>(
        stream: lobbyService.streamWaitingLobbies(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }
          final lobbies = snapshot.data!;
          if (lobbies.isEmpty) {
            return Center(child: Text("Nessuna lobby in attesa"));
          }
          return ListView.builder(
            itemCount: lobbies.length,
            itemBuilder: (ctx, index) {
              final lobby = lobbies[index];
              return ListTile(
                title: Text("Lobby ${lobby.lobbyId}"),
                subtitle: Text("Host: ${lobby.hostUid} - Players: ${lobby.players.length}"),
                onTap: () {
                  // Naviga alla LobbyDetailScreen per joinare/vedere i player
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createLobby,
        child: Icon(Icons.add),
      ),
    );
  }
}
