import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:the_mind_game/models/card_model.dart';
import 'package:the_mind_game/services/game_service.dart';

import '../models/game_state_model.dart';

class GameScreen extends StatefulWidget {
  final String lobbyId;

  const GameScreen({Key? key, required this.lobbyId}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final gameService = GameService();
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    gameService.listenToGameState(widget.lobbyId);
  }

  @override
  void dispose() {
    gameService.cancelListening();
    super.dispose();
  }

  void _leaveGame() {
    Navigator.pop(context);
  }

  void _playCard(CardModel card) async {
    if (currentUserId == null) return;
    await gameService.playCard(widget.lobbyId, currentUserId!, card);
  }

  void _useStar() async {
    if (currentUserId == null) return;
    await gameService.useStar(widget.lobbyId, currentUserId!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              return Center(child: Text("Game Over!"));
            } else if (state.status == "Won") {
              return Center(child: Text("Hai Vinto!"));
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
}
