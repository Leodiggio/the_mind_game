import 'game_state_model.dart';

class Lobby {
  final String lobbyId;
  final String hostUid;
  final String status;
  final List<String> players;
  final GameState? gameState;

  Lobby(
      {required this.lobbyId,
      required this.hostUid,
      required this.status,
      required this.players,
      required this.gameState});

  Lobby copyWith(
      {String? lobbyId,
      String? hostUid,
      String? status,
      List<String>? players,
      GameState? gameState}) {
    return Lobby(
        lobbyId: lobbyId ?? this.lobbyId,
        hostUid: hostUid ?? this.hostUid,
        status: status ?? this.status,
        players: players ?? this.players,
        gameState: gameState ?? this.gameState);
  }

  Map<String, dynamic> toMap() {
    return {
      "hostUid": hostUid,
      "status": status,
      "players": players,
      "gameState": gameState?.toMap(),
    };
  }

  factory Lobby.fromMap(String docId, Map<String, dynamic> map) {
    return Lobby(
        lobbyId: docId,
        hostUid: map["hostUid"] as String,
        status: map["status"] as String,
        players: List<String>.from(map["players"] as List),
        gameState: map["gameState"] == null
            ? null
            : GameState.fromMap(map["gameState"] as Map<String, dynamic>));
  }
}
