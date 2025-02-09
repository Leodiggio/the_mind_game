import '../models/card_model.dart';
import '../models/user_model.dart';

List<UserModel> distributeCards(
    List<UserModel> players, List<CardModel> deck, int level) {
  var tempDeck = List<CardModel>.from(deck); // copia del deck
  var updatedPlayers = <UserModel>[];

  for (final player in players) {
    final drawn = tempDeck.take(level).toList();
    tempDeck.removeRange(0, level);

    final updatedPlayer = player.copyWith(handCards: drawn);
    updatedPlayers.add(updatedPlayer);
  }

  // Aggiorno 'deck' con ciò che resta
  deck
    ..clear()
    ..addAll(tempDeck);

  return updatedPlayers;
}