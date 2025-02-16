import 'package:flutter/material.dart';

import '../models/user_model.dart';


class GameTable extends StatelessWidget {
  final List<UserModel> players; // Assumi che siano al massimo 6

  const GameTable({Key? key, required this.players}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Definisci le posizioni predefinite; ad es. coordinate percentuali o assolute
    final positions = [
      Offset(0.5, 0.1), // Centro alto
      Offset(0.85, 0.3),
      Offset(0.85, 0.7),
      Offset(0.5, 0.9),
      Offset(0.15, 0.7),
      Offset(0.15, 0.3),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: List.generate(6, (index) {
            final pos = positions[index];
            // Trova il giocatore assegnato a questo posto (se presente)
            UserModel? player;
            if (index < players.length) {
              player = players[index];
            }
            return Positioned(
              left: constraints.maxWidth * pos.dx - 30, // 30 = offset per centrare il widget
              top: constraints.maxHeight * pos.dy - 30,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: player != null ? Colors.blue : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: player != null
                    ? Text(player.nickname, style: TextStyle(color: Colors.white), textAlign: TextAlign.center,)
                    : Container(),
              ),
            );
          }),
        );
      },
    );
  }
}
