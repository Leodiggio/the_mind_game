import 'package:the_mind_game/models/card_model.dart';

class User {
  final int id;
  final String nickname;
  final bool isAI;
  final String password;
  final List<CardModel> handCards;

  User(
      {required this.id,
      required this.nickname,
      required this.isAI,
      required this.password,
      required this.handCards});

  User copyWith({
    int? id,
    String? nickname,
    bool? isAI,
    String? password,
    List<CardModel>? handCards,
  }) {
    return User(
        id: id ?? this.id,
        nickname: nickname ?? this.nickname,
        isAI: isAI ?? this.isAI,
        password: password ?? this.password,
        handCards: handCards ?? this.handCards);
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "nickname": nickname,
      "isAI": isAI,
      "password": password,
      "handCards": handCards.map((c) => c.toMap()).toList()
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    final handCardsList = (map["handCards"] as List)
        .map((c) => CardModel.fromMap(c as Map<String, dynamic>))
        .toList();

    return User(
        id: map["id"] as int,
        nickname: map["nickname"] as String,
        isAI: map["isAI"] as bool,
        password: map["password"] as String,
        handCards: handCardsList);
  }
}
