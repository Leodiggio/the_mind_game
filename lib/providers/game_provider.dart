import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:the_mind_game/models/game_state_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/card_model.dart';
import '../models/user_model.dart';

class GameProvider with ChangeNotifier {
  final LocalStorage storage;
  GameState? _gameState;

  GameState? get gameState => _gameState;

  GameProvider(this.storage);

  void startNewGame({int level = 1, required List<User> players}) {
    final deck = _generateDeck();

    final newState = GameState(
        level: level,
        players: players,
        deck: deck,
        playedCards: const [],
        lives: 3,
        stars: 2);

    final distributedState = _distributeCards(newState);

    _gameState = distributedState;

    notifyListeners();
  }

  GameState _distributeCards(GameState state) {
    if (state.players.isEmpty) return state;

    final level = state.level;

    var tempDeck = List<CardModel>.from(state.deck);
    var updatedPlayers = <User>[];

    for (final player in state.players) {
      // Pesca un numero pari a level di carte dal deck
      final drawn = tempDeck.take(level).toList();
      tempDeck.removeRange(0, level);

      // Aggiorna la mano del player con copyWith
      final updatedPlayer = player.copyWith(handCards: drawn);
      updatedPlayers.add(updatedPlayer);
    }

    return state.copyWith(
      deck: tempDeck,
      players: updatedPlayers,
    );
  }

  void playCard({required uderId, required CardModel card}) {
    if (_gameState == null) return;

    final state = _gameState!;
    final currentPlayers = List<User>.from(state.players);

    // Trova l'indice del player
    final playerIndex = currentPlayers.indexWhere((p) => p.id == userId);
    if (playerIndex == -1) return;

    final currentPlayer = currentPlayers[playerIndex];

    // Rimuovi la carta dalla mano
    final updatedHand = List<CardModel>.from(currentPlayer.handCards);
    updatedHand.removeWhere((c) => c.value == card.value);

    // Aggiorna il player eliminando la carta dalla mano
    final updatedPlayer = currentPlayer.copyWith(handCards: updatedHand);
    currentPlayers[playerIndex] = updatedPlayer;

    // Aggiungi la carta a "playedCards"
    final updatedPlayed = List<CardModel>.from(state.playedCards);
    updatedPlayed.add(card.copyWith(isPlayed: true));

    // Controlla se la carta è effettivamente superiore all'ultima (se vuoi la logica “ordinata”)
    if (updatedPlayed.length > 1) {
      final lastCard = updatedPlayed[updatedPlayed.length - 2];
      if (card.value < lastCard.value) {
        // Esempio: carta non in ordine => perdi una vita
        // (Logica extra: controllare se la vita va sotto zero, fine partita, ecc.)
        final newLives = state.lives - 1;
        _gameState = state.copyWith(
          lives: newLives,
          players: currentPlayers,
          playedCards: updatedPlayed,
        );
      } else {
        // Carta corretta
        _gameState = state.copyWith(
          players: currentPlayers,
          playedCards: updatedPlayed,
        );
      }
    } else {
      // Prima carta giocata
      _gameState = state.copyWith(
        players: currentPlayers,
        playedCards: updatedPlayed,
      );
    }

    notifyListeners();
  }

  void useStar() {
    if (_gameState == null) return;
    final state = _gameState!;
    if (state.stars <= 0) {
      // Nessuna stella disponibile, ignora o mostra errore
      return;
    }

    var updatedPlayers = <User>[];
    var updatedPlayed = List<CardModel>.from(state.playedCards);

    for (final player in state.players) {
      if (player.handCards.isEmpty) {
        updatedPlayers.add(player);
        continue;
      }
      // Trova la carta più bassa
      final sorted = List<CardModel>.from(player.handCards)
        ..sort((a, b) => a.value.compareTo(b.value));
      final lowestCard = sorted.first;
      sorted.removeAt(0);

      // Aggiungila alle carte giocate
      updatedPlayed.add(lowestCard.copyWith(isPlayed: true));

      // Aggiorna la mano del player
      final updatedPlayer = player.copyWith(handCards: sorted);
      updatedPlayers.add(updatedPlayer);
    }

    final newStars = state.stars - 1;

    _gameState = state.copyWith(
      players: updatedPlayers,
      playedCards: updatedPlayed,
      stars: newStars,
    );
    notifyListeners();
  }

  List<CardModel> _generateDeck() {
    final deck = List.generate(
      100,
      (i) => CardModel(value: i + 1, isPlayed: false),
    );
    deck.shuffle();
    return deck;
  }

// ----------------------------------------------------------------
//                 SEZIONE DI SALVATAGGIO / CARICAMENTO
// ----------------------------------------------------------------

  /// Salva lo stato attuale del gioco (se presente) nelle SharedPreferences
  Future<void> saveGameState() async {
    if (_gameState == null) return;
    final map = _gameState!.toMap();
    storage.setItem("gameState", map);
  }

  Future<void> loadGameState() async {
    final loadedMap = storage.getItem('gameState');
    if (loadedMap == null) {
      return;
    }

    final loadedState = GameState.fromMap(Map<String, dynamic>.from(loadedMap));
    _gameState = loadedState;
    notifyListeners();
  }
}
