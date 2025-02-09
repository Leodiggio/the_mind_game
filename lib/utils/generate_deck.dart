import '../models/card_model.dart';

List<CardModel> generateDeck() {
  final deck = List.generate(
    100,
        (i) => CardModel(value: i + 1, isPlayed: false),
  );
  deck.shuffle();
  return deck;
}