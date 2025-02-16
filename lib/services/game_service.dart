import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:the_mind_game/models/game_state_model.dart';
import 'package:the_mind_game/utils/distribute_cards.dart';

import '../models/card_model.dart';
import '../models/user_model.dart';

class GameService with ChangeNotifier {
  GameState? _gameState;
  final int _maxLevel = 12;

  // Riferimento al doc Firestore
  late StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _gameSub;

  // Avvia l'ascolto del doc "lobbies/{lobbyId}"
  void listenToGameState(String lobbyId) {
    _gameSub = FirebaseFirestore.instance
        .collection('lobbies')
        .doc(lobbyId)
        .snapshots()
        .listen((docSnap) {
      if (!docSnap.exists) {
        // Lobby eliminata?
        _gameState = null;
        notifyListeners();
        return;
      }
      final data = docSnap.data();
      if (data == null) return;

      // Recupera il subcampo "gameState" se presente
      final gameStateMap = data['gameState'];
      if (gameStateMap == null) {
        // Partita non ancora iniziata?
        _gameState = null;
      } else {
        _gameState = GameState.fromMap(Map<String, dynamic>.from(gameStateMap));
      }
      notifyListeners();
    });
  }

  // Smetti di ascoltare (es. se esci dalla partita)
  void cancelListening() {
    _gameSub?.cancel();
    _gameSub = null;
  }

  GameState? get gameState => _gameState;

  Future<void> playCard(String lobbyId, String userId, CardModel card) async {
    //final deck = generateDeck();
    // 1. Copia locale dell’ultimo _gameState (grazie a listenToGameState, viene sempre aggiornato)
    if (_gameState == null) return;
    var state = _gameState!;

    // 2. Applica la logica: trova il player, rimuovi la carta, ecc.
    var currentPlayers = [...state.players]; // cloniamo la lista
    final playerIndex = currentPlayers.indexWhere((p) => p.uid == userId);
    if (playerIndex == -1) return;

    final currentPlayer = currentPlayers[playerIndex];
    final newHand = [...currentPlayer.handCards]
      ..removeWhere((c) => c.value == card.value);
    final updatedPlayer = currentPlayer.copyWith(handCards: newHand);
    currentPlayers[playerIndex] = updatedPlayer;

    var updatedPlayed = [...state.playedCards, card.copyWith(isPlayed: true)];

    int newLives = state.lives;
    int newLevel = state.level;
    String newStatus = state.status;
    if (updatedPlayed.length > 1) {
      final lastCard = updatedPlayed[updatedPlayed.length - 2];
      if (card.value < lastCard.value) {
        if (state.lives == 1) {
          newStatus = 'Game Over';
        } else {
          newLives = state.lives - 1;
          currentPlayers =
              distributeCards(currentPlayers, state.deck, newLevel);
          updatedPlayed = [];
        }
      }
      else if (currentPlayers.every((p) => p.handCards.isEmpty)) {
        if (state.level == _maxLevel) {
          newStatus = 'Won'; // Partita vinta
        }
        else {
          newLevel = state.level + 1;
          updatedPlayed = [];
          currentPlayers =
              distributeCards(currentPlayers, state.deck, newLevel);
        }
      }
    }

    final newState = state.copyWith(
        level: newLevel,
        players: currentPlayers,
        playedCards: updatedPlayed,
        lives: newLives,
        status: newStatus);

    // Scrivi il nuovo gameState su Firestore, se si è vinto o perso, la lobby torna in waiting
    if (newStatus == "Game Over" || newStatus == "Won") {
      await FirebaseFirestore.instance
          .collection('lobbies')
          .doc(lobbyId)
          .update({
        'gameState': newState.toMap(),
        'status': 'waiting', // O "finished"
      });
    } else {
      await FirebaseFirestore.instance
          .collection('lobbies')
          .doc(lobbyId)
          .update({
        'gameState': newState.toMap(),
        // lo status della lobby rimane invariato
      });
    }
  }

  Future<void> useStar(String lobbyId, String userId) async {
    if (_gameState == null) return;
    var state = _gameState!;

    if (state.stars <= 0) {
      // Nessuna stella disponibile, ignora o mostra errore
      return;
    }

    var updatedPlayers = <UserModel>[];
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

    String newStatus = state.status;

    // Controlla se la partita è vinta dopo aver usato la stella
    if (state.level >= _maxLevel &&
        updatedPlayers.every((p) => p.handCards.isEmpty)) {
      newStatus = 'Won'; // Partita vinta
    }

    final newState = state.copyWith(
        players: updatedPlayers,
        stars: newStars,
        playedCards: updatedPlayed,
        status: newStatus);

    await FirebaseFirestore.instance
        .collection('lobbies')
        .doc(lobbyId)
        .update({'gameState': newState.toMap()});
  }


}
