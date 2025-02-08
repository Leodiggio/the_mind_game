import 'package:the_mind_game/models/user_model.dart';
import 'card_model.dart';

class GameState {
  final int level;
  final List<UserModel> players;
  final List<CardModel> deck;
  final List<CardModel> playedCards;
  final int lives;
  final int stars;
  final String status;

  GameState(
      {required this.level,
      required this.players,
      required this.deck,
      required this.playedCards,
      required this.lives,
      required this.stars,
      required this.status  //Won o Game Over
      });

  GameState copyWith(
      {int? level,
      List<UserModel>? players,
      List<CardModel>? deck,
      List<CardModel>? playedCards,
      int? lives,
      int? stars,
      String? status}) {
    return GameState(
        level: level ?? this.level,
        players: players ?? this.players,
        deck: deck ?? this.deck,
        playedCards: playedCards ?? this.playedCards,
        lives: lives ?? this.lives,
        stars: stars ?? this.stars,
        status: status ?? this.status);
  }

  Map<String, dynamic> toMap() {
    return {
      "level": level,
      "players": players.map((p) => p.toMap()).toList(),
      //conversione di ogni elemento della lista in Map<String, dynamic> usando il relativo toMap()
      "deck": deck.map((c) => c.toMap()).toList(),
      "playedCards": playedCards.map((c) => c.toMap()).toList(),
      "lives": lives,
      "stars": stars,
      "status": status
    };
  }

  factory GameState.fromMap(Map<String, dynamic> map) {
    final playersList = (map["players"] as List)
        .map((p) => UserModel.fromMap(p as Map<String, dynamic>))
        .toList();
    final deckList = (map["deck"] as List)
        .map((c) => CardModel.fromMap(c as Map<String, dynamic>))
        .toList();
    final playedList = (map["playedCards"] as List)
        .map((c) => CardModel.fromMap(c as Map<String, dynamic>))
        .toList();

    return GameState(
        level: map["level"] as int,
        players: playersList,
        deck: deckList,
        playedCards: playedList,
        lives: map["lives"] as int,
        stars: map["stars"] as int,
        status: map["status"] as String);
  }
}
