import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:the_mind_game/models/card_model.dart';
import 'package:the_mind_game/services/game_service.dart';
import 'package:the_mind_game/services/lobby_service.dart';

import '../models/game_state_model.dart';
import '../widgets/show_confirm_dialog.dart';

class GameScreen extends StatefulWidget {
  final String lobbyId;

  const GameScreen({Key? key, required this.lobbyId}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final gameService = GameService();
  final lobbyService = LobbyService();
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    gameService.listenToGameState(widget.lobbyId);
  }

  @override
  void dispose() {
    // _handlePlayerExit();
    gameService.cancelListening();
    super.dispose();
  }

  // Future<void> _handlePlayerExit() async {
  //   if (currentUserId == null) return;
  //   try {
  //     await lobbyService.playerAbandonedGame(widget.lobbyId, currentUserId!);
  //     print("Giocatore $currentUserId ha abbandonato la partita");
  //   } catch (e) {
  //     print("Errore durante la gestione dell'abbandono del giocatore: $e");
  //   }
  // }

  Future<void> _leaveGame() async {
    if (currentUserId == null) return;
    try {
      // Carichiamo la lobby corrente
      final docRef =
          FirebaseFirestore.instance.collection("lobbies").doc(widget.lobbyId);
      final snap = await docRef.get();
      if (!snap.exists) return;

      final data = snap.data()!;
      // Rimuoviamo il giocatore dall'array "players"
      final updatedPlayers = (data["players"] as List<dynamic>)
          .where((uid) => uid != currentUserId)
          .toList();

      // gameState.status = "Game Over"
      // status della lobby a "waiting"
      final gameStateMap = data["gameState"];
      if (gameStateMap != null) {
        gameStateMap["status"] = "Game Over";
      }

      await docRef.update({
        "players": updatedPlayers,
        "status": "waiting",
        "gameState": gameStateMap
      });
    } catch (e) {
      print("Errore nel leaveGame: $e");
    }
  }

  Future<bool> _onWillPop() async {
    // Mostriamo un dialog di conferma
    final confirmed = await showConfirmDialog(context);
    if (confirmed) {
      // Esegui la logica di abbandono
      await _leaveGame();
      // Torniamo true => permette la chiusura della schermata
      return true;
    } else {
      // Utente ha annullato => rimani nella GameScreen
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Game Screen"),
          actions: [
            IconButton(
              onPressed: _leaveGame,
              icon: const Icon(Icons.exit_to_app),
            )
          ],
        ),
        body: AnimatedBuilder(
            animation: gameService,
            builder: (context, _) {
              final state = gameService.gameState;
              if (state == null) {
                return const Center(
                    child: Text("Partita non avviata o caricamento..."));
              }

              // Check se la partita è finita / vinta
              if (state.status == "Game Over") {
                return Center(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Game Over!"),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text("Torna alla Lobby"))
                  ],
                ));
              } else if (state.status == "Won") {
                return Center(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Game Won!"),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text("Torna alla Lobby"))
                  ],
                ));
              }

              // Altrimenti, partita in corso.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Livello: ${state.level}"),
                  Text("Vite: ${state.lives}"),
                  Text("Stelle: ${state.stars}"),
                  const Divider(),
                  Text("Played Cards:"),
                  Wrap(
                    children: state.playedCards.map((c) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.all(8),
                        color: Colors.grey[300],
                        child: Text(c.value.toString()),
                      );
                    }).toList(),
                  ),
                  const Divider(),
                  Text("La tua mano:"),
                  _buildUserHand(state),
                  const Divider(),
                  ElevatedButton(
                    onPressed: _useStar,
                    child: const Text("Use Star"),
                  )
                ],
              );
            }),
      ),
    );
  }

  Widget _buildUserHand(GameState state) {
    // Trova currentUser
    final me = state.players.firstWhere(
      (p) => p.uid == currentUserId,
      orElse: () => state.players.first, // fallback
    );
    final hand = me.handCards;

    if (hand.isEmpty) {
      return const Text("Nessuna carta in mano");
    }

    return Wrap(
      children: hand.map((card) {
        return GestureDetector(
          onTap: () => _playCard(card),
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(8),
            color: Colors.blue[200],
            child: Text(card.value.toString()),
          ),
        );
      }).toList(),
    );
  }

  void _playCard(CardModel card) async {
    if (currentUserId == null) return;
    await gameService.playCard(widget.lobbyId, currentUserId!, card);
  }

  void _useStar() async {
    if (currentUserId == null) return;
    await gameService.useStar(widget.lobbyId, currentUserId!);
  }
}
