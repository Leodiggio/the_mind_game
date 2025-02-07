import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/lobby_model.dart';

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

    final List<User> userModels = await _fetchPlayersData(playerUids);

    final deck = _generateDeck();

    final int initialLevel = 1;
    final distributedPlayers = _distributeCards(userModels, deck, initialLevel);

    final newGameState = GameState(
      level: initialLevel,
      players: distributedPlayers,
      deck: deck,
      playedCards: [],
      lives: 3, // quante vite vuoi all'inizio
      stars: 2, // quante stelle vuoi
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
}
