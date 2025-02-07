import 'package:the_mind_game/models/card_model.dart';

class User {
  final String uid;
  final String email;
  final String nickname;
  final bool isAI;
  final List<CardModel> handCards;

  User(
      {required this.uid,
      required this.email,
      required this.nickname,
      this.isAI = false,
      this.handCards = const []});

  User copyWith({
    String? uid,
    String? email,
    String? nickname,
    bool? isAI,
    List<CardModel>? handCards,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      isAI: isAI ?? this.isAI,
      handCards: handCards ?? this.handCards,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "email": email,
      "nickname": nickname,
      "isAI": isAI,
      "handCards": handCards.map((c) => c.toMap()).toList()
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    final handCardsList = (map["handCards"] as List)
        .map((c) => CardModel.fromMap(c as Map<String, dynamic>))
        .toList();

    return User(
        uid: map["uid"] as String,
        email: map["email"] as String,
        nickname: map["nickname"] as String,
        isAI: map["isAI"] as bool,
        handCards: handCardsList);
  }
}
