import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/card_model.dart';
import '../models/game_state_model.dart';
import '../models/lobby_model.dart';
import '../models/user_model.dart';
import '../utils/distribute_cards.dart';
import '../utils/generate_deck.dart';

class LobbyService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> startLobby(String lobbyId) async {
    final lobbyRef = firestore.collection("lobbies").doc(lobbyId);

    //Recupera il doc "lobby"
    final docSnap = await lobbyRef.get();
    if (!docSnap.exists) {
      throw Exception("Lobby non trovata");
    }

    // Ricostruisci il Lobby dal doc
    final data = docSnap.data()!;
    final lobby = Lobby.fromMap(docSnap.id, data);

    if (lobby.status != "waiting") {
      throw Exception("La lobby non è in stato waiting");
    }

    final playerUids = lobby.players;
    if (playerUids.isEmpty) {
      throw Exception("Nessun giocatore per avviare la partita");
    }

    final List<UserModel> userModels = await fetchPlayersData(playerUids);

    final deck = generateDeck();
    final distributedPlayers = distributeCards(userModels, deck, 1);

    final newGameState = GameState(
      level: 1,
      players: distributedPlayers,
      deck: deck,
      playedCards: [],
      lives: 3,
      stars: 2,
      status: "inGame"
    );

    await lobbyRef.update({
      'status': 'inGame',
      'gameState': newGameState.toMap(),
    });
  }

  // Ritorna l'ID della lobby creata
  Future<String> createLobby() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw Exception("User non loggato");

    final docRef = await firestore.collection("lobbies").add({
      "hostUid": uid,
      "status": "waiting",
      "players": [uid]
    });
    return docRef.id;
  }

  Future<void> joinLobby(String lobbyId) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw Exception("User non loggato");

    final lobbyRef = firestore.collection("lobbies").doc(lobbyId);
    await lobbyRef.update({
      "players": FieldValue.arrayUnion([uid])
    });
  }

  Future<void> leaveLobby(String lobbyId) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw Exception("User non loggato");

    final lobbyRef = firestore.collection("lobbies").doc(lobbyId);
    await lobbyRef.update({
      "players": FieldValue.arrayRemove([uid])
    });

    // Ricarica il doc per vedere quanti players sono rimasti
    final docSnap = await lobbyRef.get();
    if (!docSnap.exists) return; // la lobby potrebbe non esistere più

    final data = docSnap.data()!;
    final status = data['status'] as String? ?? 'waiting';
    final playersList = (data['players'] as List<dynamic>?)?.cast<String>() ?? [];

    // Se la partita era già avviata e ora c'è un solo player, aggiorniamo a "Game Over"
    if (status == 'inGame' && playersList.length == 1) {
      // Imposta lo status della lobby a 'finished'
      // e aggiorna gameState.status = 'Game Over'
      final gameStateMap = data['gameState'];
      if (gameStateMap != null) {
        final newGameState = Map<String, dynamic>.from(gameStateMap);
        newGameState['status'] = 'Game Over';
        await lobbyRef.update({
          'status': 'finished',
          'gameState': newGameState,
        });
      } else {
        // se non c'è un gameState, aggiorni solo 'status'
        await lobbyRef.update({'status': 'finished'});
      }
    }
  }

  /// Mostra la lista di tutte le lobbies con status=waiting
  Stream<List<Lobby>> streamWaitingLobbies() {
    return firestore
        .collection('lobbies')
        .where('status', isEqualTo: 'waiting')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return Lobby.fromMap(doc.id, doc.data());
            }).toList());
  }

  /// Recupera i dettagli di una singola lobby
  Stream<Lobby?> getLobbyStream(String lobbyId) {
    return firestore
        .collection('lobbies')
        .doc(lobbyId)
        .snapshots()
        .map((docSnap) {
      if (!docSnap.exists) return null;
      return Lobby.fromMap(docSnap.id, docSnap.data()!);
    });
  }

  /// Esempio: per ogni uid, prendo i campi nickname ed email da "users/{uid}"
  Future<List<UserModel>> fetchPlayersData(List<String> playerUids) async {
    List<UserModel> result = [];

    for (final uid in playerUids) {
      final snap = await firestore.collection('users').doc(uid).get();
      if (snap.exists) {
        final userMap = snap.data()!;
        final nickname = userMap['nickname'] as String? ?? 'Player-$uid';
        final email = userMap['email'] as String? ?? '';
        // Creiamo un oggetto 'User' del tuo game
        result.add(UserModel(
          uid: uid,
          email: email,
          nickname: nickname,
          handCards: [],
        ));
      } else {
        // se per caso non esistesse /users/uid, si può gestire l'errore o inserire placeholder
        result.add(UserModel(
          uid: uid,
          email: '',
          nickname: 'Player-$uid',
          handCards: [],
        ));
      }
    }
    return result;
  }
}
