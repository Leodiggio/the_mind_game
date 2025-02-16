import 'package:flutter/material.dart';

/// Mostra un dialog di conferma all'utente
Future<bool> showConfirmDialog(BuildContext context) async {
  return (await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text("Abbandona la partita"),
      content: Text("Sei sicuro di voler abbandonare la lobby e terminare la partita?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text("Annulla"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text("Conferma"),
        ),
      ],
    ),
  )) ?? false; // se l'utente chiude il dialog, false di default
}