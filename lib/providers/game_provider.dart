import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:the_mind_game/models/game_state_model.dart';

import '../models/card_model.dart';
import '../models/user_model.dart';

class GameProvider with ChangeNotifier {
  final LocalStorage storage;
  GameState? _gameState;

  final int _maxLevel = 12;

  bool _isGameOver = false;
  bool _hasWon = false;

  GameState? get gameState => _gameState;

  bool get isGameOver => _isGameOver;

  bool get hasWon => _hasWon;

  GameProvider(this.storage);

  void startNewGame({int level = 1, required List<User> players}) {
    _isGameOver = false;
    _hasWon = false;

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

  void playCard({required userId, required CardModel card}) {
    if (_gameState == null || _isGameOver || _hasWon) return;

    final state = _gameState!;
    final currentPlayers = List<User>.from(state.players);

    // Trova l'indice del player
    final playerIndex = currentPlayers.indexWhere((p) => p.uid == userId);
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

    // Controlla ordine (se la carta giocata è minore dell’ultima giocata, perdi 1 vita)
    if (updatedPlayed.length > 1) {
      final lastCard = updatedPlayed[updatedPlayed.length - 2];
      if (card.value < lastCard.value) {
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

    // Dopo aver giocato la carta, verifica se la partita è finita / passare di livello / vittoria
    _checkGameProgress();

    notifyListeners();
  }

  void _checkGameProgress() {
    if (_gameState == null) return;

    final state = _gameState!;

    // 1) Controlla se vite <= 0, Game Over
    if (state.lives <= 0) {
      _isGameOver = true;
      return;
    }

    // 2) Controlla se tutti i giocatori hanno finito le carte
    // (cioè ogni `User.handCards` è vuota)
    final allHandsEmpty = state.players.every((p) => p.handCards.isEmpty);
    if (allHandsEmpty) {
      // Se sei all’ultimo livello => Vittoria
      if (state.level >= _maxLevel) {
        _hasWon = true;
        return;
      } else {
        // Altrimenti, passa al livello successivo
        final newLevel = state.level + 1;
        var nextState = state.copyWith(level: newLevel);

        // Ridistribuisci le carte del livello successivo
        nextState = _distributeCards(nextState);

        _gameState = nextState;
      }
    }
  }

  void useStar() {
    if (_gameState == null || _isGameOver || _hasWon) return;
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

    _checkGameProgress();

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

    final strMap = jsonEncode(map);
    storage.setItem("gameState", strMap);
  }

  Future<void> loadGameState() async {
    final loadedMap = storage.getItem('gameState');
    if (loadedMap == null) {
      return;
    }
    final Map<String, dynamic> loadedMapDec = jsonDecode(loadedMap);

    final loadedState =
        GameState.fromMap(Map<String, dynamic>.from(loadedMapDec));
    _gameState = loadedState;

    _isGameOver = false;
    _hasWon = false;
    _checkGameProgress();

    notifyListeners();
  }
}
