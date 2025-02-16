import 'package:flutter/material.dart';
import 'package:the_mind_game/screens/lobby_detail_screen.dart';
import 'package:the_mind_game/services/user_service.dart';

import '../models/lobby_model.dart';
import '../services/lobby_service.dart';

class LobbyListScreen extends StatelessWidget {
  final LobbyService lobbyService;
  final UserService userService;

  const LobbyListScreen(
      {Key? key, required this.lobbyService, required this.userService})
      : super(key: key);

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
              return FutureBuilder<String?>(
                future: userService.getNickname(lobby.hostUid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Stiamo ancora caricando il nickname
                    return ListTile(
                      title: Text("Lobby ${lobby.lobbyId}"),
                      subtitle: Text(
                          "Host: Caricamento... - Players: ${lobby.players.length}"),
                    );
                  } else if (snapshot.hasError) {
                    // Se c'è stato un errore
                    return ListTile(
                      title: Text("Lobby ${lobby.lobbyId}"),
                      subtitle: Text("Errore caricamento host"),
                    );
                  } else {
                    // Se abbiamo i dati: snapshot.data contiene il nickname (o null)
                    final nickname = snapshot.data ?? "Sconosciuto";
                    return ListTile(
                      title: Text("Lobby ${lobby.lobbyId}"),
                      subtitle: Text(
                          "Host: $nickname - Players: ${lobby.players.length}"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LobbyDetailScreen(
                              lobbyId: lobby.lobbyId,
                              lobbyService: lobbyService,
                            ),
                          ),
                        );
                      },
                    );
                  }
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
