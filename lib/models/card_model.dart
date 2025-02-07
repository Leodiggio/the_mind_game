class CardModel {
  final int value;
  final bool isPlayed;

  CardModel({required this.value, required this.isPlayed});

  //usare metodi tipo copyWith() per creare nuovi stati per i modelli invece di mutarli

  CardModel copyWith({int? value, bool? isPlayed}) {
    return CardModel(
      value: value ?? this.value,
      isPlayed: isPlayed ?? this.isPlayed,
    );
  }

  Map<String, dynamic> toMap() {
    return {"value": value, "isPlayed": isPlayed};
  }

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
        value: map["value"] as int, isPlayed: map["isPlayed"] as bool);
  }
}
