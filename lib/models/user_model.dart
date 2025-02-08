import 'package:the_mind_game/models/card_model.dart';

class UserModel {
  final String uid;
  final String email;
  final String nickname;
  final List<CardModel> handCards;

  UserModel(
      {required this.uid,
      required this.email,
      required this.nickname,
      this.handCards = const []});

  UserModel copyWith({
    String? uid,
    String? email,
    String? nickname,
    List<CardModel>? handCards,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      handCards: handCards ?? this.handCards,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "email": email,
      "nickname": nickname,
      "handCards": handCards.map((c) => c.toMap()).toList()
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final handCardsList = (map["handCards"] as List)
        .map((c) => CardModel.fromMap(c as Map<String, dynamic>))
        .toList();

    return UserModel(
        uid: map["uid"] as String,
        email: map["email"] as String,
        nickname: map["nickname"] as String,
        handCards: handCardsList);
  }
}
